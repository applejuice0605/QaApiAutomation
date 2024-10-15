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