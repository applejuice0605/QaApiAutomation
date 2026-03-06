# Changelog

本文档记录项目的代码修改、功能变更与修复。

## [Unreleased]

### 新增

- **Lark 报告链接直达 RF 报告**：当配置了报告根 URL（`report_url` 或 `LARK_REPORT_BASE_URL`）且为 RF 报告时，飞书消息中的「报告链接」直接指向 `report.html`，点击即可在浏览器中打开本次执行结果。
- **环境变量 `LARK_REPORT_BASE_URL`**：CI 中可通过该环境变量传入报告根 URL（与 `--report-url` / config 中 `report_url` 同义），优先级为：命令行 `--report-url` > `LARK_REPORT_BASE_URL` > config。

### 变更

- **GitHub Actions**（`.github/workflows/run-tests.yml`）：
  - 执行命令改为仅跑 Login 模块示例：`python run.py --module Login --rf`。
  - 使用 `LARK_REPORT_BASE_URL` 替代 `LARK_REPORT_LINK`，使飞书链接指向报告页而非 Actions 运行页。
  - 新增 `deploy-report` job：将 `results/` 部署到 GitHub Pages，便于点击飞书链接直接查看 report.html。
  - 支持 `workflow_dispatch`：可在 Actions 页手动点击 “Run workflow” 触发执行。
  - 新增步骤 “Output report URL for GitHub Pages”：在 test job 日志中输出本次报告的 GitHub Pages URL，便于在 deploy 完成后在浏览器中打开 `report.html`。

### 修复

- **GitHub Actions**：在「Run tests」前增加「Prepare results directory」步骤（`mkdir -p results && touch results/.gitkeep`），避免 run 未生成报告时 upload-artifact 报错 “No files were found with the provided path: results/”；报告 URL 输出步骤改为仅在有报告子目录时打印链接。
- **GitHub Actions 依赖安装**：项目使用 Poetry（无 requirements.txt），workflow 改为先 `pip install poetry` 再 `poetry install --no-interaction`，运行命令改为 `poetry run python run.py ...`；Python 版本与 pyproject.toml 一致改为 3.10。
- **Python 版本约束**：pyproject.toml 保持 `python = "3.10.9"`；CI 中通过 `setup-python` 指定 `python-version: '3.10.9'`，与项目一致，避免 Poetry 报版本不兼容及 lock 与 pyproject 不一致。移除 CI 中的「Sync lock file」步骤，避免在 runner 上执行 `poetry lock` 带来的虚拟环境创建与网络问题。
- **CI 依赖改为 pip + requirements-ci.txt**：CI 不再使用 Poetry 安装（避免 robotframework-ride 拉取的 wxPython 在无头 Linux 上 PEP 517 构建失败）。新增 `requirements-ci.txt`，仅包含跑 Login RF 与 run.py 所需依赖（robotframework、robotframework-requests、robotframework-jsonlibrary、requests、python-dotenv）；workflow 改为 `pip install -r requirements-ci.txt` 与 `python run.py ...`。
- **GitHub Pages 404 说明**：deploy-report 发布到 **gh-pages** 分支；README 增加「若报告链接 404」说明，要求 Settings → Pages 选择 Deploy from a branch、分支 gh-pages、目录 / (root)。workflow 中显式设置 `publish_branch: gh-pages`，并增加「List files to deploy」步骤便于核对发布内容。

- **Login by Email 用例**（`tests/module/Login/QAPI-4_Login_by_Email.robot`）：关键字 `The status code should be 200` 需要传入状态码参数；两处调用已改为传入 `${jsonResult}[code]`，修复 “expected 1 argument, got 0” 报错。

### 文档

- **README**：增加「完整演示：Login 模块 RF 报告 + Lark + 点击链接查看报告」说明（本地验证与 CI 演示）；更新 report_url 表格与 GitHub Actions 示例（Login 模块、LARK_REPORT_BASE_URL、deploy-report）；补充 RF 报告链接指向 report.html 的说明。
