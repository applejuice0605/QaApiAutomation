#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
外层执行脚本：按模块执行 RF 用例，模块名来自 resources/api 与 tests/module 的并集；支持全部/单模块，支持 RF 或 Allure 报告。
"""

import argparse
import json
import os
import subprocess
import sys
import tempfile
import threading
import time
import webbrowser
import xml.etree.ElementTree as ET
from datetime import datetime
from pathlib import Path
from typing import Optional
from urllib.request import Request, urlopen
from urllib.error import URLError, HTTPError

try:
    from http.server import HTTPServer, SimpleHTTPRequestHandler
except ImportError:
    HTTPServer = None  # type: ignore
    SimpleHTTPRequestHandler = None  # type: ignore


# 项目根目录（脚本所在目录）
PROJECT_ROOT = Path(__file__).resolve().parent
RESOURCES_API = PROJECT_ROOT / "resources" / "api"
TESTS_MODULE = PROJECT_ROOT / "tests" / "module"
RESULTS_BASE = PROJECT_ROOT / "results"
CONFIG_DIR = PROJECT_ROOT / "config"
LARK_CONFIG_FILE = CONFIG_DIR / "lark_config.json"


def load_lark_config() -> Optional[dict]:
    """从 config/lark_config.json 读取 webhook 等配置；文件不存在或无效时返回 None。"""
    if not LARK_CONFIG_FILE.is_file():
        return None
    try:
        with open(LARK_CONFIG_FILE, "r", encoding="utf-8") as f:
            data = json.load(f)
        if not isinstance(data, dict):
            return None
        return data
    except (json.JSONDecodeError, OSError):
        return None


def get_available_modules():
    """从 resources/api 与 tests/module 子目录取并集，返回去重后的模块名列表（排序）。"""
    names = set()
    if RESOURCES_API.is_dir():
        for d in RESOURCES_API.iterdir():
            if d.is_dir() and not d.name.startswith("."):
                names.add(d.name)
    if TESTS_MODULE.is_dir():
        for d in TESTS_MODULE.iterdir():
            if d.is_dir() and not d.name.startswith("."):
                names.add(d.name)
    return sorted(names)


def get_execution_path(module_name: str) -> Optional[Path]:
    """
    解析模块执行路径：优先 tests/module/<模块名>，不存在则 resources/api/<模块名>。
    """
    tests_path = TESTS_MODULE / module_name
    api_path = RESOURCES_API / module_name
    if tests_path.is_dir():
        return tests_path
    if api_path.is_dir():
        return api_path
    return None


def path_has_tests(path: Path) -> bool:
    """检查目录下是否有至少一个 .robot 文件包含 *** Test Cases *** 或 *** Tasks ***。"""
    if not path.is_dir():
        return False
    for f in path.rglob("*.robot"):
        try:
            text = f.read_text(encoding="utf-8", errors="ignore")
            if "*** Test Cases ***" in text or "*** Tasks ***" in text:
                return True
        except OSError:
            continue
    return False


def get_report_dir_name(module_name: Optional[str], report_type: str) -> str:
    """报告目录名：单模块为 {模块名}_{类型}_{时间戳}，全部为 all_{类型}_{时间戳}。"""
    timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
    label = module_name if module_name else "all"
    return f"{label}_{report_type}_{timestamp}"


def build_robot_cmd(
    execution_paths: list[Path],
    output_dir: Path,
    use_allure: bool,
    include_tags: Optional[list[str]] = None,
    exclude_tags: Optional[list[str]] = None,
) -> tuple[list[str], Path]:
    """构建 robot 命令（列表形式，避免 shell=True）。返回 (cmd, robot_output_dir)。"""
    if use_allure:
        robot_output_dir = Path(tempfile.mkdtemp(prefix="rf_"))
    else:
        robot_output_dir = output_dir
        robot_output_dir.mkdir(parents=True, exist_ok=True)
    cmd = [
        sys.executable, "-m", "robot",
        "--outputdir", str(robot_output_dir),
        "--output", "output.xml",
        "--log", "log.html",
        "--report", "report.html",
    ]
    for tag in (include_tags or []):
        cmd.extend(["--include", tag])
    for tag in (exclude_tags or []):
        cmd.extend(["--exclude", tag])
    if use_allure:
        allure_results = output_dir / "allure-results"
        allure_results.mkdir(parents=True, exist_ok=True)
        try:
            listener_arg = str(allure_results.relative_to(Path.cwd()))
        except ValueError:
            listener_arg = str(allure_results)
        listener_arg = listener_arg.replace("\\", "/")
        cmd.extend(["--listener", f"allure_robotframework:{listener_arg}"])
    for p in execution_paths:
        cmd.append(str(p))
    return cmd, robot_output_dir


def run_robot(cmd: list[str]) -> int:
    """执行 robot，返回退出码。"""
    try:
        result = subprocess.run(cmd, capture_output=False, text=True)
        return result.returncode
    except Exception as e:
        print(f"执行 robot 时出错: {e}", file=sys.stderr)
        return 1


def check_allure_available() -> bool:
    """检查本机是否可用 allure 命令。"""
    try:
        r = subprocess.run(
            ["allure", "--version"],
            capture_output=True,
            text=True,
            shell=True,
            timeout=10,
        )
        return r.returncode == 0
    except Exception:
        return False


def generate_allure_report(allure_results_dir: Path, allure_report_dir: Path) -> bool:
    """生成 Allure 报告，返回是否成功。"""
    if not check_allure_available():
        print("警告: 未找到 allure 命令，跳过 Allure 报告生成。", file=sys.stderr)
        return False
    allure_report_dir.mkdir(parents=True, exist_ok=True)
    cmd = [
        "allure", "generate", str(allure_results_dir),
        "-o", str(allure_report_dir),
        "--clean",
    ]
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, shell=True, timeout=120)
        if r.returncode == 0:
            print(f"Allure 报告已生成: {allure_report_dir}")
            return True
        print(f"生成 Allure 报告失败: {r.stderr}", file=sys.stderr)
        return False
    except Exception as e:
        print(f"生成 Allure 报告时出错: {e}", file=sys.stderr)
        return False


def parse_robot_output_stats(output_xml_path: Path) -> Optional[dict]:
    """从 Robot output.xml 解析通过/失败/跳过数量。返回 {'pass': int, 'fail': int, 'skip': int} 或 None。"""
    if not output_xml_path.is_file():
        return None
    try:
        tree = ET.parse(output_xml_path)
        root = tree.getroot()
        # Robot Framework: <statistics><total><stat pass="..." fail="..." skip="...">All Tests</stat>
        for stat in root.findall(".//stat"):
            if stat.text and "All Tests" in stat.text:
                return {
                    "pass": int(stat.get("pass", 0)),
                    "fail": int(stat.get("fail", 0)),
                    "skip": int(stat.get("skip", 0)),
                }
        # 兼容：取最后一个 stat
        stats = root.findall(".//stat")
        if stats:
            s = stats[-1]
            return {
                "pass": int(s.get("pass", 0)),
                "fail": int(s.get("fail", 0)),
                "skip": int(s.get("skip", 0)),
            }
    except Exception:
        pass
    return None


def parse_robot_failure_messages(output_xml_path: Path) -> list[str]:
    """从 Robot output.xml 解析失败用例的错误消息。返回错误消息列表。"""
    if not output_xml_path.is_file():
        return []
    try:
        tree = ET.parse(output_xml_path)
        root = tree.getroot()
        failures = []
        # 查找所有失败用例 <test status="FAIL">
        for test in root.findall(".//test"):
            status_elem = test.find("./status")
            if status_elem is not None and status_elem.get("status") == "FAIL":
                test_name = test.get("name", "Unknown Test")
                # 获取失败消息，优先获取 <kw> 下 <status> 的消息
                failure_msg = ""
                for kw in test.findall(".//kw"):
                    kw_status = kw.find("./status")
                    if kw_status is not None and kw_status.get("status") == "FAIL":
                        msg = kw_status.text
                        if msg:
                            failure_msg = msg.strip()
                            break
                # 如果没有找到 kw 级别的失败消息，使用 test 级别的消息
                if not failure_msg and status_elem.text:
                    failure_msg = status_elem.text.strip()
                if failure_msg:
                    # 限制单条消息长度，避免过长
                    if len(failure_msg) > 300:
                        failure_msg = failure_msg[:297] + "..."
                    failures.append(f"{test_name}: {failure_msg}")
                else:
                    failures.append(f"{test_name}: 失败原因未知")
        return failures
    except Exception:
        pass
    return []


def _format_duration(seconds: float) -> str:
    """将秒数格式化为可读时长，如 1m 23s 或 45s。"""
    if seconds < 0:
        return "0s"
    s = int(round(seconds))
    if s >= 60:
        m, s = divmod(s, 60)
        return f"{m}m {s}s"
    return f"{s}s"


def send_lark_card(
    webhook_url: str,
    title: str,
    body_md: str,
    report_link: str,
    template: str = "green",
) -> bool:
    """通过飞书/Lark 机器人 webhook 发送交互卡片消息。body_md 为 lark_md 格式正文。"""
    card = {
        "config": {"wide_screen_mode": True, "enable_forward": True},
        "header": {
            "title": {"tag": "plain_text", "content": title},
            "template": "green" if template == "green" else "red",
        },
        "elements": [
            {"tag": "div", "text": {"tag": "lark_md", "content": body_md}},
            {
                "tag": "action",
                "actions": [
                    {
                        "tag": "button",
                        "text": {"tag": "plain_text", "content": "报告链接 Report link"},
                        "url": report_link,
                        "type": "primary",
                    }
                ],
            },
        ],
    }
    payload = {"msg_type": "interactive", "card": card}
    try:
        data = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        req = Request(webhook_url, data=data, headers={"Content-Type": "application/json"}, method="POST")
        with urlopen(req, timeout=15) as resp:
            if resp.status in (200, 204):
                return True
            return False
    except (URLError, HTTPError, OSError) as e:
        print(f"发送 Lark 通知失败: {e}", file=sys.stderr)
        return False


def _serve_allure_and_open_browser(allure_report_dir: Path, port: int = 8080) -> None:
    """在后台启动 HTTP 服务提供 Allure 报告目录，并打开浏览器。file:// 无法正确加载 Allure 数据，必须通过 HTTP 访问。"""
    if HTTPServer is None or SimpleHTTPRequestHandler is None:
        print("提示: 无法启动 HTTP 服务，请使用 'allure open <报告目录>' 或本地 HTTP 服务器查看报告。", file=sys.stderr)
        return
    dir_str = str(allure_report_dir.resolve())

    class _Handler(SimpleHTTPRequestHandler):
        def __init__(self, *args, **kwargs):
            super().__init__(*args, directory=dir_str, **kwargs)

        def log_message(self, format, *args):
            pass

    try:
        server = HTTPServer(("127.0.0.1", port), _Handler)
    except OSError as e:
        if "Address already in use" in str(e) or "WinError 10048" in str(e):
            print(f"提示: 端口 {port} 已被占用，请手动用 'allure open \"{allure_report_dir}\"' 查看报告。", file=sys.stderr)
        else:
            print(f"启动 HTTP 服务失败: {e}", file=sys.stderr)
        return
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    time.sleep(1)
    url = f"http://127.0.0.1:{port}"
    try:
        webbrowser.open(url)
        print(f"已通过 {url} 打开 Allure 报告（必须通过 HTTP 访问才能正确加载数据）。")
    except Exception as e:
        print(f"自动打开浏览器失败: {e}，请手动访问: {url}", file=sys.stderr)
    print(f"HTTP 服务运行中，访问 {url} 查看报告。按 Enter 键结束服务并退出。")
    try:
        input()
    except (EOFError, KeyboardInterrupt):
        pass


def main():
    parser = argparse.ArgumentParser(
        description="按模块执行 RF 用例（模块名来自 resources/api 与 tests/module 并集），支持 RF 或 Allure 报告。"
    )
    parser.add_argument(
        "--module",
        metavar="NAME",
        help="指定模块名（来自 resources/api 或 tests/module 目录名，二者并集），不传则执行全部模块；与 --file 二选一",
    )
    parser.add_argument(
        "--file",
        metavar="PATH",
        default=None,
        help="指定单个 .robot 文件执行（与 --module 二选一，传文件路径）",
    )
    report_group = parser.add_mutually_exclusive_group()
    report_group.add_argument(
        "--allure",
        action="store_true",
        help="生成 Allure 报告",
    )
    report_group.add_argument(
        "--rf",
        action="store_true",
        help="生成 RF 报告（默认）",
    )
    parser.add_argument(
        "--lark-webhook",
        metavar="URL",
        default=None,
        help="飞书/Lark 机器人 webhook URL，执行完成后推送报告摘要与链接",
    )
    parser.add_argument(
        "--report-url",
        metavar="BASE_URL",
        default=None,
        help="报告访问地址前缀（如 https://ci.example.com/artifacts/），与目录名拼接后作为 Lark 消息中的报告链接；不填则发本地路径",
    )
    parser.add_argument(
        "--include",
        metavar="TAG",
        nargs="*",
        default=None,
        help="只运行包含指定 tag 的用例，可传多个（如 --include smoke login）",
    )
    parser.add_argument(
        "--exclude",
        metavar="TAG",
        nargs="*",
        default=None,
        help="排除指定 tag 的用例，可传多个（如 --exclude wip skip）",
    )
    args = parser.parse_args()

    # 报告类型：默认 RF
    use_allure = args.allure
    report_type = "allure" if use_allure else "rf"
    # 飞书 webhook：优先命令行 > 环境变量 LARK_WEBHOOK > config/lark_config.json
    lark_config = load_lark_config()
    lark_webhook = (
        args.lark_webhook
        or os.environ.get("LARK_WEBHOOK")
        or (lark_config.get("webhook_url") if lark_config else None)
    )
    report_url_from_config = (lark_config or {}).get("report_url") or ""

    execution_paths: list[Path] = []
    run_module_names: list[str] = []

    if args.file:
        # 单文件模式：--file 与 --module 二选一
        if args.module:
            print("错误: --file 与 --module 不能同时使用，请二选一。", file=sys.stderr)
            sys.exit(1)
        path = Path(args.file)
        if not path.is_absolute():
            path = (Path.cwd() / path).resolve()
        else:
            path = path.resolve()
        if not path.is_file():
            print(f"错误: 文件不存在: {path}", file=sys.stderr)
            sys.exit(1)
        if path.suffix.lower() != ".robot":
            print(f"错误: 请指定 .robot 文件，当前: {path}", file=sys.stderr)
            sys.exit(1)
        execution_paths = [path]
        run_module_names = [path.stem]
    else:
        # 模块模式
        available = get_available_modules()
        if not available:
            print("错误: resources/api 与 tests/module 下均未找到任何模块。", file=sys.stderr)
            sys.exit(1)
        if args.module:
            if args.module not in available:
                print(f"错误: 未知模块 '{args.module}'。可选: {', '.join(available)}", file=sys.stderr)
                sys.exit(1)
            module_names = [args.module]
        else:
            module_names = available
        for name in module_names:
            path = get_execution_path(name)
            if path is None:
                print(f"警告: 模块 '{name}' 对应路径不存在，跳过。", file=sys.stderr)
                continue
            if not path_has_tests(path):
                print(f"警告: 模块 '{name}' 下无 *** Test Cases *** / *** Tasks ***，跳过。", file=sys.stderr)
                continue
            execution_paths.append(path)
            run_module_names.append(name)
        if not execution_paths:
            print("错误: 没有可执行的路径。", file=sys.stderr)
            sys.exit(1)

    # 报告目录名与路径（用实际执行的模块名）
    report_label = run_module_names[0] if len(run_module_names) == 1 else None
    report_dir_name = get_report_dir_name(report_label, report_type)
    output_dir = RESULTS_BASE / report_dir_name
    output_dir.mkdir(parents=True, exist_ok=True)

    include_list = args.include if args.include is not None else []
    exclude_list = args.exclude if args.exclude is not None else []

    print("=" * 60)
    print("Robot Framework 执行")
    print("=" * 60)
    if args.file:
        print(f"文件: {run_module_names[0]}")
    else:
        print(f"模块: {', '.join(run_module_names)}")
    print(f"报告类型: {report_type}")
    if include_list:
        print(f"Tag 过滤 --include: {', '.join(include_list)}")
    if exclude_list:
        print(f"Tag 过滤 --exclude: {', '.join(exclude_list)}")
    print(f"输出目录: {output_dir}")
    print("=" * 60)

    cmd, robot_output_dir = build_robot_cmd(
        execution_paths, output_dir, use_allure,
        include_tags=include_list if include_list else None,
        exclude_tags=exclude_list if exclude_list else None,
    )
    print(f"执行: {' '.join(cmd)}")
    print("-" * 60)

    start_time = time.perf_counter()
    exit_code = run_robot(cmd)
    elapsed_seconds = time.perf_counter() - start_time

    if use_allure and exit_code is not None:
        allure_results = output_dir / "allure-results"
        allure_report = output_dir / "allure-report"
        if allure_results.exists():
            if generate_allure_report(allure_results, allure_report):
                _serve_allure_and_open_browser(allure_report)
        print(f"  - Allure 报告目录: {allure_report}")

    print("=" * 60)
    print(f"退出码: {exit_code}")
    print(f"报告目录: {output_dir}")
    if not use_allure:
        print(f"  - log.html, report.html, output.xml")
    print("=" * 60)

    # 飞书/Lark webhook 推送报告摘要与链接（卡片形式，含执行时长）
    if lark_webhook:
        output_xml = robot_output_dir / "output.xml"
        stats = parse_robot_output_stats(output_xml)
        module_label = report_label or "all"
        status_emoji = "✅" if (exit_code == 0) else "❌"
        title = f"API Automation RF Report {status_emoji} {module_label} ({report_type})"
        duration_str = _format_duration(elapsed_seconds)
        # 报告生成时间（执行结束时间）
        report_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        lines = [
            f"**模块 Module**：{', '.join(run_module_names)}",
            f"**报告类型 Report Type**：{report_type}",
            f"**执行时长 Duration**：{duration_str}",
            f"**报告时间 Report Time**：{report_time}",
        ]
        if stats:
            lines.append(
                f"**通过 Pass**：{stats['pass']} | **失败 Fail**：{stats['fail']} | **跳过 Skip**：{stats['skip']}"
            )
        failure_messages = parse_robot_failure_messages(output_xml)
        if failure_messages:
            lines.append("\n**失败原因 Failure Reasons**：")
            max_display = 3
            for i, msg in enumerate(failure_messages[:max_display]):
                lines.append(f"{i + 1}. {msg}")
            if len(failure_messages) > max_display:
                remaining = len(failure_messages) - max_display
                lines.append(f"_… 还有 {remaining} 个错误，详见报告链接_")
        body_md = "\n".join(lines)
        report_link_override = os.environ.get("LARK_REPORT_LINK")
        if report_link_override:
            report_link = report_link_override
        else:
            report_url = (
                args.report_url
                or os.environ.get("LARK_REPORT_BASE_URL")
                or report_url_from_config
            )
            if report_url:
                report_link = (report_url.rstrip("/") + "/" + report_dir_name).strip("/")
                if report_type == "rf" and (
                    report_link.startswith("http://") or report_link.startswith("https://")
                ):
                    report_link = report_link + "/report.html"
            else:
                report_link = str(output_dir.resolve())
        template = "green" if (exit_code == 0) else "red"
        if send_lark_card(lark_webhook, title, body_md, report_link, template):
            print("已推送报告摘要至 Lark。")
        else:
            print("Lark 推送失败，请检查 webhook 或网络。", file=sys.stderr)

    sys.exit(exit_code if exit_code is not None else 0)


if __name__ == "__main__":
    main()
