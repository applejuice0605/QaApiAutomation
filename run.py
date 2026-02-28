import subprocess
import os
import time


def main():
    # 设置要执行的 RF 脚本路径
    rf_script = "tests/module/Login/QAPI-4_Login_by_Email.robot"  # 这里替换为你的 RF 脚本路径
    allure_results_dir = f'./allure-results'

    # 检查并创建 allure-results 目录
    if not os.path.exists(allure_results_dir):
        os.makedirs(allure_results_dir)

    # 执行 Robot Framework 脚本并生成结果
    # run_robot_command = f' robot --listener allure_robotframework --outputdir results tests/module/Login/'
    run_robot_command = f'python -m robot --listener allure_robotframework  --outputdir {allure_results_dir} {rf_script}'
    subprocess.run(run_robot_command, shell=True)

    # 生成 Allure 报告
    current_time = time.strftime("%Y%m%d_%H%M%S")
    allure_report_dir = f'./allure-report-{current_time}'

    # 检查并创建 allure-report 目录
    if not os.path.exists(allure_report_dir):
        os.makedirs(allure_report_dir)

    generate_allure_report_command = f'allure generate {allure_results_dir} --output {allure_report_dir} --clean'
    subprocess.run(generate_allure_report_command, shell=True)

    print(f'Allure report generated at: {allure_report_dir}')


if __name__ == "__main__":
    main()