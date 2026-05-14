# Changelog

本文档记录项目的代码修改、功能变更与修复。

## [Unreleased]

### 新增

- **单文件执行 `--file`**：`run.py` 支持指定单个 `.robot` 文件执行（与 `--module` 二选一），报告目录名使用文件名（stem），可与 `--include`/`--exclude`、Lark 推送等组合使用。
- **Tag 过滤 `--include` / `--exclude`**：`run.py` 支持按 Robot Framework tag 过滤用例。`--include TAG [TAG ...]` 只运行包含指定 tag 的用例，`--exclude TAG [TAG ...]` 排除指定 tag；可与 `--module` 或 `--file` 组合使用。
- **Lark 消息增加执行时长**：推送到飞书的消息中增加「执行时长 Duration」字段，格式为 `Xm Ys` 或 `Zs`。
- **Lark 消息增加报告时间**：推送到飞书的卡片正文中增加「报告时间 Report Time」（脚本执行结束时间，格式 `YYYY-MM-DD HH:MM:SS`）。
- **Lark 消息改为卡片形式**：飞书推送由富文本 post 改为交互卡片（interactive card），支持 lark_md 富文本（加粗、斜体等），并保留「报告链接」按钮。
- **Lark 报告链接直达 RF 报告**：当配置了报告根 URL（`report_url` 或 `LARK_REPORT_BASE_URL`）且为 RF 报告时，飞书消息中的「报告链接」直接指向 `report.html`，点击即可在浏览器中打开本次执行结果。
- **环境变量 `LARK_REPORT_BASE_URL`**：CI 中可通过该环境变量传入报告根 URL（与 `--report-url` / config 中 `report_url` 同义），优先级为：命令行 `--report-url` > `LARK_REPORT_BASE_URL` > config。

### 变更

- **敏感变量文件**：`resources/varfile_defvar.py` 停止版本跟踪，仅本地使用；新增 `resources/varfile_defvar.example.py` 模板；`.gitignore` 明确忽略 `resources/varfile_defvar.py`。历史提交若曾含明文密码请轮换。
- **模块发现逻辑**（`run.py`）：`get_available_modules()` 改为同时扫描 `resources/api` 与 `tests/module` 子目录并取并集作为可选模块列表。仅存在于 `tests/module` 的模块（如 Clearing）也可通过 `--module Clearing` 执行；执行路径仍优先 `tests/module/<模块名>`，不存在时再使用 `resources/api/<模块名>`。
- **GitHub Actions**（`.github/workflows/run-tests.yml`）：
  - 增加「Prepare varfile_defvar.py」步骤：从 example 复制后，用 **Secrets** 注入：`VARFILE_ENV` → `env`（默认 `uat`）、`ARCHERY_NAME`/`ARCHERY_PWD` → `archeryName`/`archeryPwd`（Python repr 转义）。仓库 Settings → Secrets and variables → Actions 中可按需配置 `VARFILE_ENV`（如 `uat`/`sit`/`prod`）及 Archery 两个 Secret。
  - 当前 workflow 使用 `python run.py --rf`（全量）；若仅需 smoke 可改回 `--module Login`。
  - 使用 `LARK_REPORT_BASE_URL` 替代 `LARK_REPORT_LINK`，使飞书链接指向报告页而非 Actions 运行页。
  - 新增 `deploy-report` job：将 `results/` 部署到 GitHub Pages，便于点击飞书链接直接查看 report.html。
  - 支持 `workflow_dispatch`：可在 Actions 页手动点击 “Run workflow” 触发执行。
  - 新增步骤 “Output report URL for GitHub Pages”：在 test job 日志中输出本次报告的 GitHub Pages URL，便于在 deploy 完成后在浏览器中打开 `report.html`。

### 修复

- **Setting/UserLogout URL 行内注释导致 404**：移除 `resources/api/Setting/UserLogout.robot` 中 `${url}` 后的行内注释，避免注释被拼进 URL（出现 `%20#...`）导致请求 404。
- **Clearing 核保流程**（`QAPI-101` / `102` / `103` / `104`）：与 `resources/biz/Underwriting/underwriting.robot` 对齐——使用 `the response should contain taskIds`；manager/todo 响应写入 `${jsonResult}`；`assigneToMe` 与 approve 传入 `${taskResult}`（不再使用已删除的 `taskId` 关键字及错误的 `${orderNo}`/`${jsonResult}` 参数）。
- **Linux CI 资源路径大小写**：修复用例 `Resource` 引入路径中 `biz/underwriting` 与目录 `biz/Underwriting` 大小写不一致的问题，避免 Linux 下关键词加载失败（“No keyword ... found”）。
- **Clearing 用例关键字调用修正**：`QAPI-101-1` 的内部关键字由 `property_order` 调用改为 `vehicle_order`，与 `*** Settings ***` 引入的资源保持一致，避免 IDE/静态检查提示未定义关键字。
- **QAPI-41 DoubleOrder leading zeros 修复**：在 `resources/biz/order/Travel/travel_order.robot` 中把 `${identityNo} == '0'` 的条件判断改为对字符串加引号并使用 `IF ... ${identityNo}= Set Variable ...` 更新变量，避免 Robot/Python eval 将 `068...` 当“前导零整数”导致 `SyntaxError`。
- **QAPI-41 IF 条件引号修复**：修正 `resources/biz/order/Travel/travel_order.robot` 中 `identityNo` 默认参数从 `identityNo='0'` 改为 `identityNo=0`，避免出现表达式 `''0'' == '0'` 的 `Invalid IF condition`（引号重复导致的 SyntaxError）。
- **slipStatus 关键字级重试**：在 `resources/biz/orderInfo/getPolicyInfo.robot` 新增 `[Retry] Get slipStatus from Boss and verify`（默认 `5x`、每次间隔 `5s`），并按 `underwriting.robot` 同风格重构为“外层重试 + 内层 `Get And Verify ...`（`method_type` 分流）+ 单次请求关键字”，用于处理 Boss slip 状态延迟同步导致的偶发失败。
- **QAPI-99 保持原关键字调用并兼容重试**：`tests/module/Underwriting/QAPI-99...` 继续使用原两行关键字（请求 + 断言）；在 `resources/biz/orderInfo/getPolicyInfo.robot` 中将重试下沉到既有关键字实现，且将“Send request to Boss:/api/oms/slip/v2/list API to get slipStatus”关键字本身改为内置重试（`Wait Until Keyword Succeeds 5x 5s`），保证调用方式不变也能自动重试。
- **ArcheryCookieGenerator 导入报错**（CI）：移除 `resources/util/ArcheryCookieGenerator.py` 中“导入即执行”的调试代码；`get_archery_cookie` 改为从 Session cookies 读取 `csrftoken/sessionid` 并对缺失场景抛出可读错误，避免 `NoneType.split`。
- **GitHub Actions**：在「Run tests」前增加「Prepare results directory」步骤（`mkdir -p results && touch results/.gitkeep`），避免 run 未生成报告时 upload-artifact 报错 “No files were found with the provided path: results/”；报告 URL 输出步骤改为仅在有报告子目录时打印链接。
- **GitHub Actions 依赖安装**：项目使用 Poetry（无 requirements.txt），workflow 改为先 `pip install poetry` 再 `poetry install --no-interaction`，运行命令改为 `poetry run python run.py ...`；Python 版本与 pyproject.toml 一致改为 3.10。
- **Python 版本约束**：pyproject.toml 保持 `python = "3.10.9"`；CI 中通过 `setup-python` 指定 `python-version: '3.10.9'`，与项目一致，避免 Poetry 报版本不兼容及 lock 与 pyproject 不一致。移除 CI 中的「Sync lock file」步骤，避免在 runner 上执行 `poetry lock` 带来的虚拟环境创建与网络问题。
- **CI 依赖改为 pip + requirements-ci.txt**：CI 不再使用 Poetry 安装（避免 robotframework-ride 拉取的 wxPython 在无头 Linux 上 PEP 517 构建失败）。新增 `requirements-ci.txt`，仅包含跑 Login RF 与 run.py 所需依赖（robotframework、robotframework-requests、robotframework-jsonlibrary、requests、python-dotenv）；workflow 改为 `pip install -r requirements-ci.txt` 与 `python run.py ...`。
- **GitHub Pages 404 说明**：deploy-report 发布到 **gh-pages** 分支；README 增加「若报告链接 404」说明，要求 Settings → Pages 选择 Deploy from a branch、分支 gh-pages、目录 / (root)。workflow 中显式设置 `publish_branch: gh-pages`，并增加「List files to deploy」步骤便于核对发布内容。

- **Login by Email 用例**（`tests/module/Login/QAPI-4_Login_by_Email.robot`）：关键字 `The status code should be 200` 需要传入状态码参数；两处调用已改为传入 `${jsonResult}[code]`，修复 “expected 1 argument, got 0” 报错。

### 文档

- **README**：增加「完整演示：Login 模块 RF 报告 + Lark + 点击链接查看报告」说明（本地验证与 CI 演示）；更新 report_url 表格与 GitHub Actions 示例（Login 模块、LARK_REPORT_BASE_URL、deploy-report）；补充 RF 报告链接指向 report.html 的说明。
