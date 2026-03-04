MCP 接口单元测试框架
🌟 项目简介本项目提供了一个高度模块化、灵活的 MCP (主控平台) 接口自动化单元测试框架。它专注于高效地执行接口测试，并集成了 Dify Workflow 进行智能化的接口返回结果对比和断言。


✨ 核心功能
1. 数据驱动测试: 从 Excel 文件 (test_cases.xlsx) 读取测试用例。
2. 模块化设计: 核心功能（文件I/O、Dify调用、多线程）均抽离为独立模块。
3. 灵活的执行控制:
4. 支持通过 main.py 切换 单线程 或 多线程 模式执行。
5. 支持通过设置 起始/结束索引 来执行特定的测试用例范围。
6. 智能比对: 调用 Dify Workflow 对 MCP 接口的返回结果和测试用例中的预期（预测的差距）进行比较。
7. 结果输出: 将 MCP 完整返回、Dify 比对结果和原始请求数据统一输出到指定的 Excel 文件中。
8. 路径控制: 输入和输出文件的路径在 main.py 中集中定义，方便配置绝对路径或相对路径。

📦 项目结构
/mcp_tester
├── /data
│   └── test_cases.xlsx     # ⬅️ 测试输入文件 (需手动创建并放入测试数据)
├── /results
│   └── test_results.xlsx   # ⬅️ 测试输出结果 (运行后自动生成)
├── /utils
│   ├── __init__.py         
│   ├── file_io.py          # 文件读写 (读输入/写输出)
│   └── dify_workflow.py    # MCP/Dify 接口调用
├── constants.py            # 全局配置：接口URL, Excel列名
├── executor.py             # 核心执行器：多线程/单线程调度
└── main.py                 # 程序入口：设置文件路径和运行参数


好的，根据您前面确定的项目结构和代码实现，我为您生成一个完整的 README.md 文件。

这个 README 将涵盖项目的介绍、功能、环境要求、文件结构、配置说明和运行指南。

MCP 接口单元测试框架
🌟 项目简介
本项目提供了一个高度模块化、灵活的 MCP (主控平台) 接口自动化单元测试框架。它专注于高效地执行接口测试，并集成了 Dify Workflow 进行智能化的接口返回结果对比和断言。

✨ 核心功能
数据驱动测试: 从 Excel 文件 (test_cases.xlsx) 读取测试用例。

模块化设计: 核心功能（文件I/O、Dify调用、多线程）均抽离为独立模块。

灵活的执行控制:

支持通过 main.py 切换 单线程 或 多线程 模式执行。

支持通过设置 起始/结束索引 来执行特定的测试用例范围。

智能比对: 调用 Dify Workflow 对 MCP 接口的返回结果和测试用例中的预期（预测的差距）进行比较。

结果输出: 将 MCP 完整返回、Dify 比对结果和原始请求数据统一输出到指定的 Excel 文件中。

路径控制: 输入和输出文件的路径在 main.py 中集中定义，方便配置绝对路径或相对路径。

📦 项目结构
/mcp_tester
├── /data
│   └── test_cases.xlsx     # ⬅️ 测试输入文件 (需手动创建并放入测试数据)
├── /results
│   └── test_results.xlsx   # ⬅️ 测试输出结果 (运行后自动生成)
├── /utils
│   ├── __init__.py         
│   ├── file_io.py          # 文件读写 (读输入/写输出)
│   └── dify_workflow.py    # MCP/Dify 接口调用
├── config.py            # 全局配置：接口URL, Excel列名
├── executor.py             # 核心执行器：多线程/单线程调度
└── main.py                 # 程序入口：设置文件路径和运行参数以及运行模型：dify / agent



🛠️ 依赖环境
本项目基于 Python 3.6+，需要安装以下依赖库：
    Bash
        pip install pandas openpyxl requests

⚙️ 配置指南
1. constants.py 配置
配置 MCP 和 Dify 接口的 URL 以及访问密钥。

Python
    # constants.py

    # --- MCP/Dify 接口配置 ---
    MCP_API_URL = "http://your_mcp_api_url/v1/interface"
    DIFY_API_KEY = "dify-workflow-api-key-xxxxxxxx"
    DIFY_WORKFLOW_URL = "http://your_dify_instance/v1/workflows/run"

    # ... Excel 列名配置 ... (通常不需要修改)

2. main.py 配置（运行参数及路径）
main.py 是唯一的入口文件，控制了程序的运行模式和文件路径。
    参数/变量描述/默认值
    TEST_DATA_FILE_PATH输入测试用例文件的完整路径。data/test_cases.xlsx
    RESULT_DATA_FILE_PATH输出测试结果文件的完整路径。results/test_results.xlsx
    START_INDEX开始执行的测试用例 Excel 行号索引（从 0 开始）。0
    END_INDEX结束执行的测试用例 Excel 行号索引。sys.maxsize
    USE_MULTITHREADINGTrue 启用多线程模式，False 启用单线程模式。True
    MAX_THREADS多线程模式下的最大线程数。10

3. 准备测试数据
在 /data 目录下创建 test_cases.xlsx，确保包含以下两列：
    列名 (配置于 constants.py),描述,示例内容
    接口请求JSON,调MCP接口所需的完整JSON字符串。,"{""user_id"": 123, ""query"": ""查询用户信息""}"
    预测的差距,期望 Dify Workflow 用于比对的预期结果描述或预期JSON。,"预期返回的 name 字段应为 ""Alice"" 且 status 为 200。"

🚀 运行指南
1. 创建目录:
    Bash
        mkdir data
        mkdir results
2. 放置数据: 将配置好的 test_cases.xlsx 放入 data 文件夹。
3. 执行测试:
    Bash
        python main.py


📊 结果输出
程序运行完毕后，将在 results 目录下生成 test_results.xlsx 文件。该文件包含以下关键列：
1. 案例序号: 原始 Excel 行号索引。
2. 接口请求JSON: 原始请求 JSON。
3. 预测的差距: 原始预期结果/差距描述。
4. MCP返回(整个Response): 接口调用返回的完整 JSON 字符串。
5. Dify比对结果: Dify Workflow 分析并返回的最终比对结果（例如：比对通过、失败原因等）。