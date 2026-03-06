# QA_Api_Automation

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
| `--lark-webhook URL` | 飞书/Lark 机器人 webhook 地址；执行完成后推送报告摘要与报告链接。 |
| `--report-url BASE_URL` | 报告访问地址前缀；与报告目录名拼接后作为 Lark 消息中的可点击链接。CI 中也可用环境变量 `LARK_REPORT_LINK` 直接指定完整链接（如 GitHub Actions 运行页 URL）。 |

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

### 飞书/Lark 推送（可选）

使用 `--lark-webhook` 时，执行结束后会向该 webhook 发送一条富文本消息，包含：

- **标题**：本次执行结果（通过/失败）、模块名、报告类型
- **正文**：模块列表、报告类型、退出码、通过/失败/跳过数量（从 output.xml 解析）
- **报告链接**：可点击的 URL，用于在飞书中打开本次报告。来源见下文「report_url / 报告链接」说明。

**Webhook 配置方式**：在飞书群聊 → 设置 → 群机器人 → 添加自定义机器人 → 复制 webhook 地址。可通过以下任一方式传入（优先级从高到低）：命令行 `--lark-webhook "复制的URL"`、环境变量 `LARK_WEBHOOK`、本地配置文件 `config/lark_config.json`（该文件已加入 .gitignore，不会提交到仓库）。使用配置文件时，可将 `config/lark_config.example.json` 复制为 `config/lark_config.json` 并填入 `webhook_url` 和可选的 `report_url`。报告根 URL 也可通过环境变量 `LARK_REPORT_BASE_URL` 传入（CI 中常用）。若机器人开启了「签名」或「关键词」校验，需在机器人设置里配置一致。

**report_url / 报告链接（如何填写）**：

| 场景 | 建议 |
|------|------|
| **仅本机跑** | 留空即可，飞书消息里会显示本机报告目录路径。 |
| **报告部署在固定前缀的 URL** | 填「报告根地址」。脚本会把本次报告目录名拼在后面；RF 报告时链接会指向 `report.html`，例如 `report_url` 填 `https://your-domain.com/artifacts`，链接即为 `https://your-domain.com/artifacts/Login_rf_2026-02-28_12-00-00/report.html`。适用于自建静态站、对象存储前缀等。 |
| **GitHub Actions（部署到 Pages，点击即看报告）** | 在 workflow 中设置环境变量 `LARK_REPORT_BASE_URL` 为 GitHub Pages 根 URL（如 `https://<owner>.github.io/<repo>/`），并将 `results/` 部署到 Pages；飞书中的链接会直接打开本次的 RF `report.html`。示例见下。 |
| **GitHub Actions（仅上传 artifact）** | 不填 `report_url`。设置环境变量 `LARK_REPORT_LINK` 为本次 Actions 运行页 URL，飞书中的链接指向该页，便于下载制品、查看日志。 |

**完整演示：Login 模块 RF 报告 + Lark + 点击链接查看报告**

- **本地快速验证**：执行 `python run.py --module Login --rf --lark-webhook <webhook>`（或使用 `config/lark_config.json` 配置 webhook）。执行后会推送摘要到飞书，此时报告链接为本机路径，仅本机可打开；若需本地「点击即看」，可对 `results/<报告目录>` 起 HTTP 服务并配合 `--report-url` 或 tunnel 工具。
- **CI 演示（推荐）**：push 到 `main` 后，workflow 会执行 Login 模块、生成 RF 报告、推送到 Lark，并将 `results/` 部署到 GitHub Pages；飞书中的「报告链接」会指向本次的 `report.html`，点击即可在浏览器中查看。需在仓库 **Settings → Pages** 中启用 GitHub Pages（发布自 gh-pages 分支或 GitHub Actions）。
- **手动执行并查看报告**：workflow 已支持 `workflow_dispatch`。在 GitHub 仓库 **Actions** 页选择 “Run tests”，点击 **Run workflow** 即可手动触发。执行完成后：(1) 飞书会收到消息，其中的链接即本次报告的 `report.html`；(2) 在本次运行的 **test** job 日志里，“Output report URL for GitHub Pages” 步骤会打印报告 URL（形如 `https://<owner>.github.io/<repo>/Login_rf_<时间戳>/report.html`）。等 **deploy-report** job 完成后，用该 URL 即可在浏览器中打开本次 RF 报告。

**GitHub Actions 示例**（Login 模块 + 推送 Lark + 报告部署到 Pages，链接直达 report.html）：

```yaml
# .github/workflows/run-tests.yml
on:
  push:
    branches: [main]
  workflow_dispatch:   # 支持在 Actions 页手动点击 “Run workflow” 执行
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.10.9'
      - name: Install Poetry
        run: pip install poetry
      - name: Install dependencies
        run: poetry install --no-interaction
      - name: Run tests and notify Lark
        env:
          LARK_WEBHOOK: ${{ secrets.LARK_WEBHOOK }}
          LARK_REPORT_BASE_URL: https://${{ github.repository_owner }}.github.io/${{ github.event.repository.name }}/
        run: poetry run python run.py --module Login --rf
      - name: Upload report artifact
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: test-results-${{ github.run_id }}
          path: results/
      - name: Output report URL for GitHub Pages
        if: always() && hashFiles('results/*') != ''
        run: |
          REPORT_DIR=$(ls results/ 2>/dev/null | head -1)
          if [ -n "$REPORT_DIR" ]; then
            echo "Report URL (available after deploy-report job):"
            echo "https://${{ github.repository_owner }}.github.io/${{ github.event.repository.name }}/$REPORT_DIR/report.html"
          fi

  deploy-report:
    needs: test
    runs-on: ubuntu-latest
    permissions:
      contents: write
    if: always() && (needs.test.result == 'success' || needs.test.result == 'failure')
    steps:
      - name: Download report artifact
        uses: actions/download-artifact@v4
        with:
          name: test-results-${{ github.run_id }}
      - name: Deploy report to GitHub Pages
        uses: peaceiris/actions-gh-pages@v4
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: .
          force_orphan: true
```

在仓库 Settings → Secrets 中配置 `LARK_WEBHOOK` 为飞书机器人 webhook 地址；在 Settings → Pages 中启用 GitHub Pages。运行后飞书消息里的「报告链接」会指向本次的 RF 报告页（report.html），点击即可在浏览器中查看。


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
