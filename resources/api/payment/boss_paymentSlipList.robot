*** Settings ***
Library    RequestsLibrary
Library    JSONLibrary

Resource    ../../util/httpCommon.robot

*** Keywords ***
Send Request And Get Response Data
    [Arguments]    ${bossToken}   ${paymentBillNo}
    # 1. 准备请求数据：请求路径、请求头、请求数据
    ${base_url}=   Set Variable     https://cashier-uat.fuse.co.id
    ${path}=   Set Variable     /api/cashier/boss/payment/slip/list
    ${headers}=    Create Dictionary    Content-Type=application/json    clientType=application/json;charset=UTF-8    appCode=IDP_BOSS  fusetoken=${bossToken}
    ${payload}=    Set Variable     {"paymentBillingNo": "${paymentBillNo}"}
    # 2. 发送请求
    ${response}=    httpCommon.Send Post Request And Get Response Data    ${base_url}    ${path}    ${headers}    ${payload}

    RETURN    ${response}