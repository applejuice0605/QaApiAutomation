*** Settings ***
Resource    ../../lib/Common.robot
Variables   ../../varfile_defvar.py

*** Variables ***
${withdrawal_url}=  https://ptr-sg-uat.fuse.co.id/api/local/id/bankCard/withdraw
${check_partnerCode_url}=  https://boss-sg-uat.fuse.co.id/api/prm/partner/manager/list
${check_manualWithdrawalTaskId_url}=  https://boss-sg-uat.fuse.co.id/api/trading/withdrawal/bpm/manager/verification/list
${withdrawalVerifation_assign}=  https://boss-sg-uat.fuse.co.id/api/bpm/runtime/self/assign
${withdrawalVerifation_review}=  https://boss-sg-uat.fuse.co.id/api/bpm/flow/approval
${withdrawalPayment_assign}=  https://boss-sg-uat.fuse.co.id/api/bpm/runtime/self/assign
${withdrawalPaymentConfirm_url}=  https://boss-sg-uat.fuse.co.id/api/bpm/flow/approval
${withdrawalSession}=  withdrawalSession
${manual_withdrawal}=   https://ptr-sg-uat.fuse.co.id/api/local/id/bankCard/withdraw/manual
${withdrawalPaymentTaskId}=  https://boss-sg-uat.fuse.co.id/api/trading/withdrawal/bpm/manager/payment/list
${withdrawalPaymentAssign}=  https://boss-sg-uat.fuse.co.id/api/bpm/runtime/self/assign
${BalanceHistory_url}=  https://ptr-sg-uat.fuse.co.id/api/account/flow/list/v2
${add_bank_account_url}=  https://ptr-sg-uat.fuse.co.id/api/local/id/bankCard/add
*** Keywords ***

# 发起提现请求
Send Withdrawal Request And Get Response Data
    [Arguments]    ${fusetoken}   ${bankCardNo}    ${bankUid}    ${bankName}    ${withdrawAmount}    ${manuallyWithdraw}=false
    # 1. 准备请求数据：请求路径、请求头、请求数据
    # 根据环境加载提现base url，默认是UAT
    Run Keyword If    '${env}' == 'pre'
    ...    Set Test Variable    ${base_url}    https://ptr.fuse.co.id/
    ...  ELSE
    ...    Set Test Variable    ${base_url}    https://ptr-${env}.fuse.co.id/
    
    ${path}    Set Variable    /api/prm/withdraw/auto
    
    Log To Console  DEBUG_INFO: variable is |${manuallyWithdraw}|
    # 根据manuallyWithdraw加载提现类型
    IF    '${manuallyWithdraw}' == 'true'
        ${path}    Set Variable    /api/prm/withdraw/manual
    END
    Log    ${path}
    Log    ${manuallyWithdraw}

    ${headers}=  Create Dictionary      Content-Type=application/json   fusetoken=${fusetoken}  appCode=IDP_FUSE_PRO
    ${payload}=  Set Variable      {"bankCardNo":"${bankCardNo}","bankUid":${bankUid},"bankName":"${bankName}","bizSource":1,"withdrawAmount":"${withdrawAmount}","manuallyWithdraw":${manuallyWithdraw}}
    # 2. 发送请求
    ${response}=    httpCommon.Send Post Request And Get Response Data    ${base_url}    ${path}    ${headers}    ${payload}
    
    RETURN    ${response}


# 查询银行卡
Get Bank Account List
    [Arguments]    ${fusetoken}
    # 1. 准备请求数据：请求路径、请求头、请求数据
    # 根据环境加载提现base url，默认是UAT
    Run Keyword If    '${env}' == 'pre'
    ...    Set Test Variable    ${base_url}    https://ptr.fuse.co.id/
    ...  ELSE
    ...    Set Test Variable    ${base_url}    https://ptr-${env}.fuse.co.id/
    # curl -X POST -d '{}' 'https://ptr-sg-uat.fuse.co.id/api/partner/bank/account/list?_v=1773122899538_41445'
    ${path}    Set Variable    /api/partner/bank/account/list
    ${headers}=  Create Dictionary      Content-Type=application/json   fusetoken=${fusetoken}  appCode=IDP_FUSE_PRO
    ${payload}=  Set Variable      {}
    
    ${response}    httpCommon.Send Post Request And Get Response Data    ${base_url}    ${path}    ${headers}    ${payload}
    RETURN    ${response}

# 查询余额
Get Account Balance
    # curl -X POST -d '{}' 'https://ptr-sg-uat.fuse.co.id/api/local/prm/account/balance?_v=1773122899299_61595'
    [Arguments]    ${fusetoken}
    # 1. 准备请求数据：请求路径、请求头、请求数据
    # 根据环境加载提现base url，默认是UAT
    Run Keyword If    '${env}' == 'pre'
    ...    Set Test Variable    ${base_url}    https://ptr.fuse.co.id/
    ...  ELSE
    ...    Set Test Variable    ${base_url}    https://ptr-${env}.fuse.co.id/

    ${path}    Set Variable    /api/local/prm/account/balance
    ${headers}=  Create Dictionary      Content-Type=application/json   fusetoken=${fusetoken}  appCode=IDP_FUSE_PRO
    ${payload}=  Set Variable      {}
    
    ${response}    httpCommon.Send Post Request And Get Response Data    ${base_url}    ${path}    ${headers}    ${payload}
    RETURN    ${response}

Get Withdrawal History List
    [Documentation]    获取fusepro的流水列表，默认查询前20条
    # curl -X POST -d '{pageNum: 2, pageSize: 10}' 'https://ptr-sg-uat.fuse.co.id/api/withdraw/history/list?_v=1773125857612_89321'
    [Arguments]    ${fusetoken}    ${pageNum}=1    ${pageSize}=20
    # 1. 准备请求数据：请求路径、请求头、请求数据
    # 根据环境加载提现base url，默认是UAT
    Run Keyword If    '${env}' == 'pre'
    ...    Set Test Variable    ${base_url}    https://ptr.fuse.co.id/
    ...  ELSE
    ...    Set Test Variable    ${base_url}    https://ptr-${env}.fuse.co.id/

    ${path}    Set Variable    /api/withdraw/history/list
    ${headers}=  Create Dictionary      Content-Type=application/json   fusetoken=${fusetoken}  appCode=IDP_FUSE_PRO
    ${payload}=  Set Variable      {"pageNum":${pageNum},"pageSize":${pageSize}}
    
    ${response}    httpCommon.Send Post Request And Get Response Data    ${base_url}    ${path}    ${headers}    ${payload}
    RETURN    ${response}


# 查询Boss-Task Mgmt-Withdrawal Verification Task List
[Task Mgmt] Get Withdrawal Verification Task Mgmt List
    [Arguments]    ${bossToken}    ${withdrawalId}=${None}
    # 1. 准备请求数据：请求路径、请求头、请求数据
    # 根据环境加载提现base url，默认是UAT
    Run Keyword If    '${env}' == 'pre'
    ...    Set Test Variable    ${base_url}    https://boss.fuse.co.id/
    ...  ELSE
    ...    Set Test Variable    ${base_url}    https://boss-${env}.fuse.co.id/
    
    ${path}    Set Variable    /api/trading/withdrawal/bpm/manager/verification/list
    ${headers}=  Create Dictionary      Content-Type=application/json   fusetoken=${bossToken}  appCode=IDP_BOSS
    ${payload}=  Set Variable      {"endTask":0,"endProcess":0,"pageNum":1,"pageSize":20,"withdrawalId":"${withdrawalId}"}
    
    ${response}    httpCommon.Send Post Request And Get Response Data    ${base_url}    ${path}    ${headers}    ${payload}
    RETURN    ${response}

[Task] Get Withdrawal Verification Task List
    [Arguments]    ${bossToken}    ${withdrawalId}=${None}
    # 1. 准备请求数据：请求路径、请求头、请求数据
    # 根据环境加载提现base url，默认是UAT
    Run Keyword If    '${env}' == 'pre'
    ...    Set Test Variable    ${base_url}    https://boss.fuse.co.id/
    ...  ELSE
    ...    Set Test Variable    ${base_url}    https://boss-${env}.fuse.co.id/
    
    ${path}    Set Variable    api/trading/withdrawal/bpm/own/verification/list
    ${headers}=  Create Dictionary      Content-Type=application/json   fusetoken=${bossToken}  appCode=IDP_BOSS
    ${payload}=  Set Variable      {"endTask":0,"endProcess":0,"pageNum":1,"pageSize":20,"withdrawalId":"${withdrawalId}"}
    
    ${response}    httpCommon.Send Post Request And Get Response Data    ${base_url}    ${path}    ${headers}    ${payload}
    RETURN    ${response}


Approve Withdrawal Task
    [Arguments]    ${bossToken}    ${withdrawId}    ${taskId}
    # 1. 准备请求数据：请求路径、请求头、请求数据
    # 根据环境加载提现base url，默认是UAT
    Run Keyword If    '${env}' == 'pre'
    ...    Set Test Variable    ${base_url}    https://boss.fuse.co.id/
    ...  ELSE
    ...    Set Test Variable    ${base_url}    https://boss-${env}.fuse.co.id/
    
    ${path}    Set Variable    api/bpm/flow/approval
    ${headers}=  Create Dictionary      Content-Type=application/json   fusetoken=${bossToken}  appCode=IDP_BOSS
    ${payload}=  Set Variable      {"action":"Approval","workflow":"WithdrawalFlow","comment":{"classify1":"","classify2":""},"data":{"withdrawId":"${withdrawId}"},"taskId":"${taskId}"}
    
    ${response}    httpCommon.Send Post Request And Get Response Data    ${base_url}    ${path}    ${headers}    ${payload}
    RETURN    ${response}

[Task Mgmt] Get Withdrawal Payment Task Mgmt List
    [Arguments]    ${bossToken}    ${withdrawalId}
    # 1. 准备请求数据：请求路径、请求头、请求数据
    # 根据环境加载提现base url，默认是UAT
    Run Keyword If    '${env}' == 'pre'
    ...    Set Test Variable    ${base_url}    https://boss.fuse.co.id/
    ...  ELSE
    ...    Set Test Variable    ${base_url}    https://boss-${env}.fuse.co.id/
    
    ${path}    Set Variable    api/trading/withdrawal/bpm/manager/payment/list
    ${headers}=  Create Dictionary      Content-Type=application/json   fusetoken=${bossToken}  appCode=IDP_BOSS
    ${payload}=  Set Variable      {"endTask":0,"endProcess":0,"pageNum":1,"pageSize":20,"withdrawalId":"${withdrawalId}"}
    # 2. 发送请求
    ${response}    httpCommon.Send Post Request And Get Response Data    ${base_url}    ${path}    ${headers}    ${payload}
    RETURN    ${response}

[Task] Get Withdrawal Payment Task List
    [Arguments]    ${bossToken}    ${withdrawalId}
    # 1. 准备请求数据：请求路径、请求头、请求数据
    # 根据环境加载提现base url，默认是UAT
    Run Keyword If    '${env}' == 'pre'
    ...    Set Test Variable    ${base_url}    https://boss.fuse.co.id/
    ...  ELSE
    ...    Set Test Variable    ${base_url}    https://boss-${env}.fuse.co.id/
    
    ${path}    Set Variable    api/trading/withdrawal/bpm/own/payment/list
    ${headers}=  Create Dictionary      Content-Type=application/json   fusetoken=${bossToken}  appCode=IDP_BOSS
    ${payload}=  Set Variable      {"endTask":0,"endProcess":0,"pageNum":1,"pageSize":20,"withdrawalId":"${withdrawalId}"}
    # 2. 发送请求
    ${response}    httpCommon.Send Post Request And Get Response Data    ${base_url}    ${path}    ${headers}    ${payload}
    RETURN    ${response}


[Withdrawal Payment] Approve Withdrawal Task
    [Documentation]    审批打款任务
    [Arguments]    ${bossToken}    ${withdrawalId}    ${taskId}
    # 1. 准备请求数据：请求路径、请求头、请求数据
    # 根据环境加载提现base url，默认是UAT
    Run Keyword If    '${env}' == 'pre'
    ...    Set Test Variable    ${base_url}    https://boss.fuse.co.id/
    ...  ELSE
    ...    Set Test Variable    ${base_url}    https://boss-${env}.fuse.co.id/
    
    ${path}    Set Variable    api/bpm/flow/approval
    ${headers}=  Create Dictionary      Content-Type=application/json   fusetoken=${bossToken}  appCode=IDP_BOSS
    
    # 获取现在时间+20s的时间戳
    ${paymentTime}=    Evaluate    int(time.time() * 1000) + 20000
    ${payload}=  Set Variable      {"action":"ConfirmPayment","workflow":"WithdrawalFlow","comment":{"classify1":""},"data":{"attachmentIds":["fuse-id-core-prod-rw_images/20260310/ee7269b4b1574788b34a783d01455268.jpeg"],"paymentTime":${paymentTime},"withdrawId":"${withdrawalId}"},"taskId":"${taskId}"}
    # 2. 发送请求
    ${response}    httpCommon.Send Post Request And Get Response Data    ${base_url}    ${path}    ${headers}    ${payload}
    RETURN    ${response}

Decline Withdrawal Task
    [Documentation]    审批打款任务
    [Arguments]    ${bossToken}    ${withdrawalId}    ${taskId}
    # 1. 准备请求数据：请求路径、请求头、请求数据
    # 根据环境加载提现base url，默认是UAT
    Run Keyword If    '${env}' == 'pre'
    ...    Set Test Variable    ${base_url}    https://boss.fuse.co.id/
    ...  ELSE
    ...    Set Test Variable    ${base_url}    https://boss-${env}.fuse.co.id/
    
    ${path}    Set Variable    api/bpm/flow/approval
    ${headers}=  Create Dictionary      Content-Type=application/json   fusetoken=${bossToken}  appCode=IDP_BOSS
    
    ${payload}=  Set Variable      {"action":"Decline","workflow":"WithdrawalFlow","comment":{"classify1":"","content":"test"},"data":{"withdrawId":"${withdrawalId}","comments":"test"},"taskId":"${taskId}"}
    # 2. 发送请求
    ${response}    httpCommon.Send Post Request And Get Response Data    ${base_url}    ${path}    ${headers}    ${payload}
    RETURN    ${response}
