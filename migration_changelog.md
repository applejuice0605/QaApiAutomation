# 新加坡 UAT (sg-uat) 域名迁移与问题修复清单

本文件详细记录了在新加坡 UAT (`sg-uat`) 域名迁移以及测试环境排查中，所有修改的文件、域名调整、潜在遗漏项排查以及语法修复内容，供后续追溯和回滚参考。

---

## 一、 公共资源文件中原硬编码域名的替换清单 (A)

以下是公共资源（Resource & Library）中原先硬编码的 `-uat` 域名，已被系统化替换为新加坡 `sg-uat` 后缀的清单：

| 序号 | 模块 / 文件路径 | 原硬编码域名 (UAT) | 替换后域名 (新加坡 sg-uat) | 作用描述 |
|---|---|---|---|---|
| 1 | `resources/lib/Common.robot` | `https://app-uat.fuseinsurtech.com/...` | `https://app-sg-uat.fuseinsurtech.com/...` | App 登录和常用网关接口地址 |
| 2 | `resources/Boss/LoginBoss/LoginBoss.robot` | `https://sso-uat.fuse.co.id/...` | `https://sso-sg-uat.fuse.co.id/...` | Boss 登录服务域名 |
| 3 | `resources/biz/order/Car/SaveBinderRFQ.robot` | `https://ptr-uat.fuse.co.id/...` | `https://ptr-sg-uat.fuse.co.id/...` | 询价及报价处理域名 |
| 4 | `resources/biz/order/Car/getCarCoupon.robot` | `https://ptr-uat.fuse.co.id/...` | `https://ptr-sg-uat.fuse.co.id/...` | 优惠券获取域名 |
| 5 | `resources/biz/order/Car/CreateBinderOrder.robot` | `https://ptr-uat.fuse.co.id/...` | `https://ptr-sg-uat.fuse.co.id/...` | 订单绑定及创建域名 |
| 6 | `resources/api/Withdrawal/withdrawal_v2.robot` | `https://ptr-uat.fuse.co.id/...`<br>`https://boss-uat.fuse.co.id/...` | `https://ptr-sg-uat.fuse.co.id/...`<br>`https://boss-sg-uat.fuse.co.id/...` | 提现 V2 接口的 Partner 与 Boss 域名 |
| 7 | `resources/api/Withdrawal/withdrawal.robot` | `https://ptr-uat.fuse.co.id/...`<br>`https://boss-uat.fuse.co.id/...` | `https://ptr-sg-uat.fuse.co.id/...`<br>`https://boss-sg-uat.fuse.co.id/...` | 提现审批流程接口 |
| 8 | `resources/api/boss/slip_v2_list.robot` | `https://boss-uat.fuse.co.id/...` | `https://boss-sg-uat.fuse.co.id/...` | 支付水单 V2 接口域名 |
| 9 | `resources/api/order/saveBinderRfqOrder.robot` | `https://ptr-uat.fuse.co.id/...` | `https://ptr-sg-uat.fuse.co.id/...` | 订单保存核心接口 |
| 10 | `resources/api/order/getAvailableCoupon.robot` | `https://ptr-uat.fuse.co.id/...` | `https://ptr-sg-uat.fuse.co.id/...` | 可用优惠券接口 |
| 11 | `resources/api/order/generateQuotePDF.robot` | `https://ptr-uat.fuse.co.id/...` | `https://ptr-sg-uat.fuse.co.id/...` | PDF 导出报价单接口 |
| 12 | `resources/api/order/createBinderOrder.robot` | `https://ptr-uat.fuse.co.id/...` | `https://ptr-sg-uat.fuse.co.id/...` | 创建绑定订单接口 |
| 13 | `resources/api/ManualAdjustment/trading_manager_preAdd.robot` | `https://boss-uat.fuse.co.id/...` | `https://boss-sg-uat.fuse.co.id/...` | 手工调整预新增接口 |
| 14 | `resources/api/ManualAdjustment/trading_manager_list.robot` | `https://boss-uat.fuse.co.id/...` | `https://boss-sg-uat.fuse.co.id/...` | 手工调整列表管理接口 |
| 15 | `resources/api/ManualAdjustment/trading_manager_add.robot` | `https://boss-uat.fuse.co.id/...` | `https://boss-sg-uat.fuse.co.id/...` | 手工调整新增接口 |
| 16 | `resources/api/ManualAdjustment/ticketItem_bpm_manager.robot` | `https://boss-uat.fuse.co.id/...` | `https://boss-sg-uat.fuse.co.id/...` | BPM 工单管理接口 |
| 17 | `resources/api/ManualAdjustment/BonusAdjustment.robot` | `https://boss-uat.fuse.co.id/...`<br>`https://tmp-uat.fuse.co.id/...` | `https://boss-sg-uat.fuse.co.id/...`<br>`https://tmp-sg-uat.fuse.co.id/...` | 奖金调整及临时审核接口 |
| 18 | `resources/api/ManualAdjustment/adjustment_review_list_todo.robot` | `https://tmp-uat.fuse.co.id/...` | `https://tmp-sg-uat.fuse.co.id/...` | 调整待办评审列表 |
| 19 | `resources/api/ManualAdjustment/adjustment_review_list_manager.robot` | `https://boss-uat.fuse.co.id/...` | `https://boss-sg-uat.fuse.co.id/...` | 调整管理评审列表 |
| 20 | `resources/api/ManualAdjustment/adjustment_approval.robot` | `https://boss-uat.fuse.co.id/...`<br>`https://tmp-uat.fuse.co.id/...` | `https://boss-sg-uat.fuse.co.id/...`<br>`https://tmp-sg-uat.fuse.co.id/...` | 手工调整审批流程接口 |
| 21 | `resources/api/Profile/partner.robot` | `https://app-uat.fuseinsurtech.com/` | `https://app-sg-uat.fuseinsurtech.com/` | Partner 基础接口域名 |
| 22 | `resources/api/Profile/updateProfile.robot` | `https://app-uat.fuseinsurtech.com/...` | `https://app-sg-uat.fuseinsurtech.com/...` | 用户资料修改接口域名 |

---

## 二、 动态拼接域名的配置与排查情况 (B)

项目中包含若干通过变量动态拼接域名的机制，通过本次环境配置即可生效，不需要修改代码：

### 1. 拼接变量控制中心
*   **文件位置**: [`resources/varfile_defvar.py`](file:///d:/FuseProgram/RFAutomation-Fuse/API/coding/automation-test/resources/varfile_defvar.py)
*   **配置项**: `env = "sg-uat"` （当切换为新加坡环境时需配置为此值）
*   **环境变量源**: `.env` 的 `MAIN_ENV` 以及相关解析脚本。

### 2. 动态拼接逻辑点验证（无遗漏）
以下脚本会读取 `${env}` 变量并自动执行拼接：
*   **SSO 登录拼接点**:
    *   **文件**: `resources/api/Login/api_bylogin.robot`
    *   **逻辑**: 非 pre 环境下拼接为 `https://sso-${env}.fuse.co.id`。当 `env="sg-uat"` 时，自动指向 `https://sso-sg-uat.fuse.co.id`，符合预期。
*   **App 登录拼接点**:
    *   **文件**: `resources/api/Login/fuse_user_login.robot`
    *   **逻辑**: 非 pre 环境下拼接为 `https://app-${env}.fuseinsurtech.com`。当 `env="sg-uat"` 时，自动指向 `https://app-sg-uat.fuseinsurtech.com`，符合预期。

---

## 三、 其他服务域名的硬编码排查清单 (C)

除核心业务域名（sso, ptr, boss, cashier, tmp 等）外，项目中还存在其他辅助服务的硬编码域名，以下是其排查与保留说明：

### 1. DMS 数据库归档服务 (不涉及迁移)
*   **域名**: `https://rd-dms.fuseinsurtech.com`
*   **分布文件**:
    *   `resources/util/dbUtil.robot`
    *   `resources/util/ArcheryCookieGenerator.py`
    *   `resources/api/Login/loginA.robot`
*   **说明**: 该域名为研发团队内部的 Archery SQL 审核与数据库操作网关，属于全局通用系统，**不区分新加坡 regional UAT**。无需替换，保持原样。

### 2. Dify AI 与 Webhook 服务 (维持原状)
*   **域名**: `https://rd-dify-sit.fuse.co.id` / `https://pchat-uat.fuse.co.id`
*   **分布文件**: 主要分布在 `tests/WDifyUnitTest/` 目录以及部分 Webhook 单元测试中。
*   **说明**: 该模块属于 Dify AI 意图识别测试和 pchat 机器人的对接单测，其服务未迁移到新加坡 UAT。继续保留现有的 sit/uat 通用域名以确保工具可用性。

---

## 四、 语法错误与 IDE 兼容性问题清理记录 (D)

为解决迁移后执行时 IDE 的高亮红线警告和可能引发的编译错误，进行了如下修复：

### 1. `resources/api/payment/mock/mockVA.robot`
*   **修改内容**: 对文件末尾第 30-34 行的散落调试 URL 与 Basic 认证头信息加上了 `#` 前缀进行注释化。
*   **原因**: 避免 Robot Framework 语法引擎将普通文本误识别为关键字，修复了整个文件的报错状态。

### 2. `resources/api/PaymentBillingFlow/UploadPaymentProof_v1.robot`
*   **修改内容 1**: 在 `*** Settings ***` 中显式添加 `Library    Collections` 导入。
    *   **原因**: 解决 IDE 无法解析 `Get From Dictionary` 和 `Get From List` 的警告。
*   **修改内容 2**: 将请求体 Body 字符里面的阿里云 OSS 地址的 query 参数中的 `&` 符号统一转义为了 `\&`。
    *   **原因**: 彻底解决 Robot IDE 将 `&OSSAccessKeyId` 和 `&Signature` 误识别为不合法字典变量导致的语法红线，且转义后不影响实际请求结果。

### 3. `resources/lib/SignGenerator.py`
*   **修改内容**: 注释了类中的 `get_keyword_names()` 辅助方法。
    *   **原因**: 原方法使该 Python 库被识别为混合库，但由于缺少对应的运行驱动函数，导致 IDE 提示“加载库失败/未发现关键字”。注释后恢复为标准静态库 API，使 IDE 能够完美提取并关联 `generate_sign` 关键字。

---

## 五、 如何进行回滚
如需回滚以上所有变更，可以直接通过 Git 丢弃修改，或直接参考 **一、公共资源文件中原硬编码域名的替换清单** 中的“原硬编码域名 (UAT)”列数据进行手工恢复。
