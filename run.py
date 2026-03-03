#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
外层执行脚本：按 resources/api 下模块执行 RF 用例，支持全部/单模块，支持 RF 或 Allure 报告。
"""

import argparse
import subprocess
import sys
import tempfile
import threading
import time
import webbrowser
from datetime import datetime
from pathlib import Path
from typing import Optional

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


def get_available_modules():
    """从 resources/api 子目录获取模块名列表。"""
    if not RESOURCES_API.is_dir():
        return []
    return sorted(
        d.name for d in RESOURCES_API.iterdir() if d.is_dir() and not d.name.startswith(".")
    )


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


def get_report_dir_name(module_name: Optional[str], report_type: str) -> str:
    """报告目录名：单模块为 {模块名}_{类型}_{时间戳}，全部为 all_{类型}_{时间戳}。"""
    timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
    label = module_name if module_name else "all"
    return f"{label}_{report_type}_{timestamp}"


def build_robot_cmd(execution_paths: list[Path], output_dir: Path, use_allure: bool) -> list[str]:
    """构建 robot 命令（列表形式，避免 shell=True）。Allure 模式下 RF 输出写入系统临时目录，报告目录内仅保留 Allure。"""
    # Allure 模式下不把 RF 报告放进报告目录，只保留 allure-results / allure-report
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
    if use_allure:
        allure_results = output_dir / "allure-results"
        allure_results.mkdir(parents=True, exist_ok=True)
        # 使用相对路径避免 Windows 下路径中 ':' 被当作参数分隔符
        try:
            listener_arg = str(allure_results.relative_to(Path.cwd()))
        except ValueError:
            listener_arg = str(allure_results)
        listener_arg = listener_arg.replace("\\", "/")
        cmd.extend(["--listener", f"allure_robotframework:{listener_arg}"])
    for p in execution_paths:
        cmd.append(str(p))
    return cmd


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
        description="按 resources/api 模块执行 RF 用例，支持 RF 或 Allure 报告。"
    )
    parser.add_argument(
        "--module",
        metavar="NAME",
        help="指定模块名（resources/api 下目录名），不传则执行全部模块",
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
    args = parser.parse_args()

    # 报告类型：默认 RF
    use_allure = args.allure
    report_type = "allure" if use_allure else "rf"

    # 模块列表
    available = get_available_modules()
    if not available:
        print("错误: resources/api 下未找到任何模块。", file=sys.stderr)
        sys.exit(1)

    if args.module:
        if args.module not in available:
            print(f"错误: 未知模块 '{args.module}'。可选: {', '.join(available)}", file=sys.stderr)
            sys.exit(1)
        module_names = [args.module]
    else:
        module_names = available

    # 解析执行路径
    execution_paths: list[Path] = []
    for name in module_names:
        path = get_execution_path(name)
        if path is None:
            print(f"警告: 模块 '{name}' 对应路径不存在，跳过。", file=sys.stderr)
            continue
        execution_paths.append(path)

    if not execution_paths:
        print("错误: 没有可执行的路径。", file=sys.stderr)
        sys.exit(1)

    # 报告目录名与路径
    report_label = module_names[0] if len(module_names) == 1 else None
    report_dir_name = get_report_dir_name(report_label, report_type)
    output_dir = RESULTS_BASE / report_dir_name
    output_dir.mkdir(parents=True, exist_ok=True)

    print("=" * 60)
    print("Robot Framework 执行")
    print("=" * 60)
    print(f"模块: {', '.join(module_names)}")
    print(f"报告类型: {report_type}")
    print(f"输出目录: {output_dir}")
    print("=" * 60)

    cmd = build_robot_cmd(execution_paths, output_dir, use_allure)
    print(f"执行: {' '.join(cmd)}")
    print("-" * 60)

    exit_code = run_robot(cmd)

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

    sys.exit(exit_code if exit_code is not None else 0)


if __name__ == "__main__":
    main()
