#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Robot Framework 测试执行脚本
用于执行 tests/module 目录下的 RF 脚本并生成报告
"""

import os
import argparse
import subprocess
import sys
import threading
import time
import webbrowser
from pathlib import Path
from datetime import datetime
from http.server import HTTPServer, SimpleHTTPRequestHandler
import os

def create_output_dir(base_dir="results"):
    """创建输出目录"""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    output_dir = Path(base_dir) / f"rf_results_{timestamp}"
    output_dir.mkdir(parents=True, exist_ok=True)
    return output_dir

def run_robot_tests(test_path, output_dir, include_tags=None, exclude_tags=None, exclude_dirs=None, variables=None):
    """执行 Robot Framework 测试"""
    
    # 构建基本命令
    cmd = [
        "python", "-m", "robot",
        "--outputdir", str(output_dir),
        "--log", "log.html",
        "--report", "report.html",
        "--output", "output.xml"
    ]
    
    # 添加 Allure 监听器（如果需要）
    allure_results_dir = output_dir / "allure-results"
    allure_results_dir.mkdir(exist_ok=True)
    cmd.extend(["--listener", f"allure_robotframework:{allure_results_dir}"])
    
    # 添加标签过滤
    if include_tags:
        for tag in include_tags:
            cmd.extend(["--include", tag])
    
    if exclude_tags:
        for tag in exclude_tags:
            cmd.extend(["--exclude", tag])
    
    # 处理排除文件夹
    test_paths_to_run = []
    if exclude_dirs and test_path.is_dir():
        # 如果指定了排除文件夹且测试路径是目录，则扫描目录并排除指定文件夹
        print(f"排除文件夹: {', '.join(exclude_dirs)}")
        
        # 获取测试路径下的所有子目录和文件
        for item in test_path.iterdir():
            if item.is_dir():
                # 检查是否在排除列表中
                should_exclude = False
                for exclude_dir in exclude_dirs:
                    if item.name == exclude_dir or str(item.relative_to(test_path)) == exclude_dir:
                        should_exclude = True
                        break
                if not should_exclude:
                    test_paths_to_run.append(str(item))
            elif item.suffix in ['.robot', '.txt']:
                # 包含单个测试文件
                test_paths_to_run.append(str(item))
        
        if not test_paths_to_run:
            print("警告: 排除文件夹后没有找到要执行的测试")
            return 1
    else:
        # 没有排除文件夹或测试路径是文件
        test_paths_to_run = [str(test_path)]
    
    # 添加变量
    if variables:
        for key, value in variables.items():
            cmd.extend(["--variable", f"{key}:{value}"])
    
    # 添加测试路径
    for test_path_item in test_paths_to_run:
        cmd.append(test_path_item)
    
    print(f"执行命令: {' '.join(cmd)}")
    print(f"输出目录: {output_dir}")
    print("-" * 50)
    
    try:
        # 执行测试
        result = subprocess.run(cmd, capture_output=False, text=True)
        return result.returncode
    except Exception as e:
        print(f"执行测试时出错: {e}")
        return 1

def start_http_server(directory, port=8080):
    """启动HTTP服务器"""
    class CustomHTTPRequestHandler(SimpleHTTPRequestHandler):
        def __init__(self, *args, **kwargs):
            super().__init__(*args, directory=directory, **kwargs)
        
        def log_message(self, format, *args):
            # 静默HTTP服务器日志
            pass
    
    try:
        server = HTTPServer(('localhost', port), CustomHTTPRequestHandler)
        print(f"HTTP服务器已启动: http://localhost:{port}")
        print("提示: 按 Ctrl+C 可停止服务器")
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n服务器已停止")
    except OSError as e:
        if "Address already in use" in str(e):
            print(f"端口 {port} 已被占用，请尝试其他端口")
        else:
            print(f"启动服务器失败: {e}")

def generate_allure_report(allure_results_dir, allure_report_dir):
    """生成 Allure 报告"""
    try:
        # 先检查 allure 命令是否可用
        check_cmd = ["allure", "--version"]
        check_result = subprocess.run(check_cmd, capture_output=True, text=True, shell=True)
        if check_result.returncode != 0:
            print("警告: 未找到 allure 命令，跳过 Allure 报告生成")
            return
            
        cmd = ["allure", "generate", str(allure_results_dir), "-o", str(allure_report_dir), "--clean"]
        result = subprocess.run(cmd, capture_output=True, text=True, shell=True)
        if result.returncode == 0:
            print(f"Allure 报告已生成: {allure_report_dir}")
            
            # 启动HTTP服务器
            print("\n" + "=" * 50)
            print("启动HTTP服务器以查看Allure报告...")
            print("注意: Allure报告需要通过HTTP服务器访问，不能直接打开HTML文件")
            print("=" * 50)
            
            # 在后台线程中启动服务器
            server_thread = threading.Thread(
                target=start_http_server, 
                args=(str(allure_report_dir),), 
                daemon=True
            )
            server_thread.start()
            
            # 等待服务器启动
            time.sleep(2)
            
            # 自动打开浏览器
            try:
                webbrowser.open('http://localhost:8080')
                print("已自动打开浏览器访问报告")
            except Exception as e:
                print(f"自动打开浏览器失败: {e}")
                print("请手动访问: http://localhost:8080")
            
            # 保持服务器运行
            try:
                print("\n服务器正在运行中...")
                print("按 Enter 键继续执行脚本，或按 Ctrl+C 停止")
                input()
            except KeyboardInterrupt:
                print("\n脚本已停止")
                
        else:
            print(f"生成 Allure 报告失败: {result.stderr}")
    except FileNotFoundError:
        print("警告: 未找到 allure 命令，跳过 Allure 报告生成")
    except Exception as e:
        print(f"生成 Allure 报告时出错: {e}")

def main():
    parser = argparse.ArgumentParser(description="执行 Robot Framework 测试")
    parser.add_argument(
        "--test-path", 
        default="tests/module",
        help="测试文件或目录路径 (默认: tests/module)"
    )
    parser.add_argument(
        "--output-dir",
        default="results",
        help="输出目录 (默认: results)"
    )
    parser.add_argument(
        "--include",
        action="append",
        help="包含的标签"
    )
    parser.add_argument(
        "--exclude",
        action="append",
        help="排除的标签"
    )
    parser.add_argument(
        "--exclude-dir",
        action="append",
        help="排除的文件夹路径 (相对于测试路径)"
    )
    parser.add_argument(
        "--variable",
        action="append",
        help="变量设置 (格式: key:value)"
    )
    parser.add_argument(
        "--no-allure",
        action="store_true",
        help="不生成 Allure 报告"
    )
    
    args = parser.parse_args()
    
    # 检查测试路径
    test_path = Path(args.test_path)
    if not test_path.exists():
        print(f"错误: 测试路径不存在: {test_path}")
        sys.exit(1)
    
    # 创建输出目录
    output_dir = create_output_dir(args.output_dir)
    
    # 处理变量
    variables = {}
    if args.variable:
        for var in args.variable:
            if ":" in var:
                key, value = var.split(":", 1)
                variables[key] = value
            else:
                print(f"警告: 变量格式不正确，忽略: {var}")
    
    print("=" * 60)
    print("Robot Framework 测试执行器")
    print("=" * 60)
    print(f"测试路径: {test_path.absolute()}")
    print(f"输出目录: {output_dir.absolute()}")
    if args.include:
        print(f"包含标签: {', '.join(args.include)}")
    if args.exclude:
        print(f"排除标签: {', '.join(args.exclude)}")
    if args.exclude_dir:
        print(f"排除文件夹: {', '.join(args.exclude_dir)}")
    if variables:
        print(f"变量: {variables}")
    print("=" * 60)
    
    # 执行测试
    exit_code = run_robot_tests(
        test_path=test_path,
        output_dir=output_dir,
        include_tags=args.include,
        exclude_tags=args.exclude,
        exclude_dirs=args.exclude_dir,
        variables=variables
    )
    
    print("\n" + "=" * 60)
    print("测试执行完成")
    print("=" * 60)
    print(f"退出码: {exit_code}")
    print(f"RF 报告位置:")
    print(f"  - 输出文件: {output_dir / 'output.xml'}")
    print(f"  - 日志文件: {output_dir / 'log.html'}")
    print(f"  - 报告文件: {output_dir / 'report.html'}")
    
    # 生成 Allure 报告
    if not args.no_allure:
        allure_results_dir = output_dir / "allure-results"
        allure_report_dir = output_dir / "allure-report"
        if allure_results_dir.exists():
            generate_allure_report(allure_results_dir, allure_report_dir)
            print(f"  - Allure 报告: {allure_report_dir / 'index.html'}")
    
    print("=" * 60)
    
    # 返回测试结果
    sys.exit(exit_code)

if __name__ == "__main__":
    import sys
    # 指定要执行的测试路径
    #sys.argv = ['run_by_rf.py', '--test-path', 'tests/module/Login'] #Login目录
    sys.argv = ['run_by_rf.py', '--test-path', 'tests/module', '--exclude-dir', 'FusePoint'] #执行特定文件夹并排除某些目录
    # 也可以添加其他参数
    # sys.argv = ['run_by_rf.py', '--test-path', 'tests/module/Login', '--include', 'smoke']
    # sys.argv = ['run_by_rf.py', '--test-path', 'tests/module', '--exclude-dir', 'Clearing', '--exclude-dir', 'KTP_Verfification']
    main()
