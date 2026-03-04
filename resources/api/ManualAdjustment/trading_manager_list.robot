*** Settings ***

Library    RequestsLibrary

Resource    ../../util/httpCommon.robot


*** Keywords ***
# 发送请求
Send Request And Get Response Data
    #payload的existsAssignee参数需要根据实际boss的指派规则来设置
    [Arguments]    ${bossToken}     ${transactionId}    ${existsAssignee}=true
    # 1. 准备请求数据：请求路径、请求头、请求数据
    ${base_url}=   Set Variable     https://boss-uat.fuse.co.id
    ${path}=   Set Variable     /api/account/trading/manager/list
    ${headers}=    Create Dictionary    Content-Type=application/json    clientType=application/json;charset=UTF-8    appCode=IDP_BOSS  fusetoken=${bossToken}

    ${payload}=    Set Variable     {"requestId":"5c5d2312-6871-4a8b-8203-a2e8ed6ccbfd","pageNum":1,"pageSize":20,"transactionId":"${transactionId}"}
    # 2. 发送请求
    ${response}=    httpCommon.Send Post Request And Get Response Data    ${base_url}    ${path}    ${headers}    ${payload}

    RETURN    ${response}