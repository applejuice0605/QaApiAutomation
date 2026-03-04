# main.py

from executor import run_tests
import sys
import os 

# ------------------------------------------------------------------
# 🔔 配置区域 - 1: 文件路径
# 路径定义在 main.py 中，支持相对路径和绝对路径。

# 相对路径示例:
DATA_DIR = "data"     
RESULTS_DIR = "results" 
INPUT_FILENAME = "test_cases.xlsx"
OUTPUT_FILENAME = "test_results.xlsx"

# 构造完整路径
TEST_DATA_FILE_PATH = os.path.join(DATA_DIR, INPUT_FILENAME)
RESULT_DATA_FILE_PATH = os.path.join(RESULTS_DIR, OUTPUT_FILENAME)

# 绝对路径示例 (如果需要，取消注释并修改):
ROOT_PATH = "" 
# TEST_DATA_FILE_PATH = os.path.join(ROOT_PATH, "data", "Mcp_Quotation.xlsx")
# RESULT_DATA_FILE_PATH = os.path.join(ROOT_PATH, "results", "Mcp_Quotation_1204_1.xlsx")

# TEST_DATA_FILE_PATH = os.path.join(ROOT_PATH, "data", "MCP_list_policies.xlsx")
# RESULT_DATA_FILE_PATH = os.path.join(ROOT_PATH, "results", "MCP_list_policies_1204_2.xlsx")

TEST_DATA_FILE_PATH = os.path.join(ROOT_PATH, "data", "SF3.0.xlsx")
RESULT_DATA_FILE_PATH = os.path.join(ROOT_PATH, "results", "SF3.0_1205_1.xlsx")

# ------------------------------------------------------------------


def main():
    """
    主程序入口，设置运行参数和文件路径。
    """
    
    # 🔔 配置区域 - 2: 运行参数
    START_INDEX = 0      # 测试用例的开始 Index (Excel 行号减一)
    # END_INDEX = 35
    END_INDEX = sys.maxsize  # 测试用例的结束 Index。sys.maxsize 表示到文件末尾。
    USE_MULTITHREADING = False # True 为多线程, False 为单线程
    MAX_THREADS = 2    # 多线程模式下的最大线程数
    MODEL = "Agent"      # 运行模式: "MCP" 或 "Agent"

    # 调用 run_tests 并传入所有参数
    run_tests(
        test_data_file=TEST_DATA_FILE_PATH,
        result_data_file=RESULT_DATA_FILE_PATH,
        start_index=START_INDEX,
        end_index=END_INDEX,
        use_multithreading=USE_MULTITHREADING,
        max_workers=MAX_THREADS,
        model=MODEL
    )

if __name__ == "__main__":
    print("--- MCP 接口单元测试工具启动 ---")
    main()