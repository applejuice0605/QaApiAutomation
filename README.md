# 使用教程
安装



# 初始化环境一定需要 poetry
安装步骤参考：
https://yanxi123.com/post/2023/12/python-poetry/#%E4%B8%80%E5%AE%89%E8%A3%85-poetry

## MAC

### 先安装 pipx
brew install pipx
pipx ensurepath

### 命令行自动完成（通过 tab 键快速完成命名输入）
pipx completions

### 安装allure 
PS：生成测试报告使用

需要安装allure
https://developer.baidu.com/article/details/2802237
参考文章
https://blog.csdn.net/baidu_24752135/article/details/131556729
参考之二：
https://blog.csdn.net/qq_37615098/article/details/103434726



# 初始化
PS: 拉取代码之后，需要初始化一次项目，加载虚拟环境的依赖包
poetry install 
PS：使用 python 3.10 ，不要使用 3.12 或者以上
每次要执行项目代码，需要进入虚拟环境
poetry shell

## 打开可视化编辑
poetry run ride.py

## 运行测试用例
poetry run robot  --listener allure_robotframework:log4 --variable DATA_FILE:testData/data002_VN.csv --i debug tests/app/exampleAppByDataAndVar.robot 

poetry run robot  --listener allure_robotframework:log4 --variable DATA_FILE:data/data002_VN.csv  tests/module/Login/TestLogin.robot

PS： poetry run robot 用例路径/用例文件.robot 


## 使用 run.py 执行测试（推荐）

项目根目录下的 `run.py` 支持按 **resources/api** 下的模块执行用例，并可选择生成 **RF 报告** 或 **Allure 报告**，报告按「模块名 + 报告类型 + 时间戳」自动命名。

### 环境要求

- 已安装：`robotframework`、`robotframework-requests`、`robotframework-jsonlibrary`
- 使用 `--allure` 时还需：`allure-robotframework`、本机已安装 Allure 命令行（用于生成报告）

若使用 Poetry，先进入虚拟环境：`poetry shell`，再执行下述命令；或使用 `poetry run python run.py ...`。

### 命令格式

```bash
python run.py [--module 模块名] [--rf | --allure]
```

| 参数 | 说明 |
|------|------|
| `--module NAME` | 指定模块名（resources/api 下目录名，如 Login、payment）。不传则执行全部模块。 |
| `--rf` | 生成 Robot Framework 报告（log.html、report.html、output.xml），**默认**。 |
| `--allure` | 生成 Allure 报告；完成后会启动本地 HTTP 服务并尝试打开浏览器查看。 |

不指定 `--rf` 或 `--allure` 时，默认按 **RF 报告** 生成。

### 示例

```bash
# 仅执行 Login 模块，生成 RF 报告（默认）
python run.py --module Login

# 仅执行 Login 模块，生成 Allure 报告（会启动 HTTP 服务并打开浏览器）
python run.py --module Login --allure

# 执行全部模块，生成 RF 报告
python run.py --rf

# 执行全部模块，生成 Allure 报告
python run.py --allure
```

### 报告输出位置与命名

- 报告根目录：项目下的 **results/** 目录。
- 单模块：`results/<模块名>_<rf|allure>_<yyyy-mm-dd_HH-MM-SS>/`
- 全部模块：`results/all_<rf|allure>_<yyyy-mm-dd_HH-MM-SS>/`

示例：`results/Login_rf_2026-03-03_15-30-00/`、`results/Login_allure_2026-03-03_15-33-57/`。

- **RF 模式**：报告目录内包含 `log.html`、`report.html`、`output.xml`。
- **Allure 模式**：报告目录内仅包含 `allure-results/`、`allure-report/`；浏览器需通过脚本启动的 **http://127.0.0.1:8080** 访问（不能直接打开 index.html 的 file://，否则数据无法加载）。脚本会提示「按 Enter 键结束服务并退出」，在结束前可一直访问该地址查看报告。


# 生成测试报告
allure generate -c -o ./report ./log4

# 可视化访问测试报告
allure open ./report/


# debug 
由于IDE 的兼容问题
需要在命令行运行才能进行debug

需要使用依赖（已经安装）：
robotframework-debuglibrary 

debug 执行：
和普通运行一样

用例里打上debug，即可实现debug，在控制台进入交互模式
${变量名字}
可以直接在里面执行关键字或变量


# 可视化编辑






# 项目路径介绍
<pre>

.
├── README.md
├── Resources
│	├── Common.robot
│	└── page
│	    └── LoginPage
│	        ├── LoginPage.py
│	        ├── LoginPage.resource
├── app  
│	├── app-uat-debug-ID.apk
│	├── app-uat-debug-VN.apk
│	└── app-uat-debug.apk
├── data
│	├── data001.csv
│	└── data002_VN.csv
├── log4
│	├── 测试报告原始日志，可以忽略
├── poetry.lock
├── pyproject.toml
├── report
│	├── 测试报告路径，每次运行都需要重新生成
├── selenium-screenshot-1.png
└── tests
    ├── bussiness    业务测试用例-区分国家
    │	├── id
    │	├── th
    │	└── vn
    ├── example
    │	├── 示范例子
    └── module
        └── Login
            └── TestLogin.robot  具体的功能测试用例

</pre>


# 教程
https://docs.robotframework.org/docs/getting_started/videos

# CI集成
https://docs.robotframework.org/docs/using_rf_in_ci_systems/ci/jenkins


# 自定义Library
https://docs.robotframework.org/docs/extending_robot_framework/custom-libraries/python_library

# 测试生命周期的勾子
https://docs.robotframework.org/docs/extending_robot_framework/listeners_prerun_api/listeners


# 并行运行
robotframework-pabot
https://docs.robotframework.org/docs/parallel

# 测试报告格式化参考
https://docs.robotframework.org/docs/reporting_alternatives


# 区分 VN、TH、ID； sit 、UAT、PROD 区分
1. 测试数据区分:
   使用命令参数来切换
2. 测试用例的区分，使用 tag 和 if 变量的方式进行动态处理
   PS: 同一个keyWord 不同的行为
3. 使用测试模版实现
   测试模版传入不同的行为


# robotframework 的语法
https://robotframework-userguide-cn.readthedocs.io/zh-cn/latest/CreatingTestData/CreatingUserKeywords.html#user-keyword-syntax

https://blog.csdn.net/taxuebufeng/article/details/132085269


# 下单webview。