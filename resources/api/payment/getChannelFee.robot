*** Settings ***
Documentation
...    slip/process API
...    BASE_URL: https://cashier-uat.fuse.co.id
...    path: /api/cashier/partner/payment/slip/getChannelFee
...    POST
...    headers: {'Content-Type': 'application/json','clientType': 'ANDROID','appCode': 'IDP_FUSE_PRO', 'fusetoken': 'token'}
...    payload: {"paymentScheme": 1,"payerType": 2,"bonusDeduction": 0,"orderId": "","securityCode": "","selectType": 2,"pointsDeduction": 0,"methodCode": "9203"}

Library    RequestsLibrary
Library    JSONLibrary

Resource    ../../util/httpCommon.robot

*** Keywords ***
Send Request And Get Response Data
    [Arguments]    ${payerType}     ${token}   ${securityCode}   ${methodCode}    ${bank}=BCA
    # 1. 准备请求数据：请求路径、请求头、请求数据
    ${base_url}=   Set Variable     https://cashier-uat.fuse.co.id
    ${headers}=    Get appHeader By PayerType    ${payerType}    ${token}

    ${payerTypeStr}    httpCommon.Get String PayerType    ${payerType}
    Log    ${payerTypeStr}
    ${path}=   Set Variable     /api/cashier/${payerTypeStr}/payment/slip/getChannelFee


    Log     ${methodCode}
    Run Keyword If     ${methodCode} == 9203     Set Test Variable    ${payload}    {"channelCode":"xendit","securityCode":"${securityCode}","methodCode":"9203"}
    ...  ELSE IF    ${methodCode} == 9204   Set Test Variable    ${payload}    {"bankCode": "${bank}", "channelCode": "xendit", "securityCode": "${securityCode}", "methodCode": "9204"}
#    ...  ELSE IF    ${methodCode} == 9202   Set Test Variable    ${extJson}    {"installmentNumber":${installmentNumber},"bankCode":"BCA"}

    # 2. 发送请求
    ${response}=    httpCommon.Send Post Request And Get Response Data    ${base_url}    ${path}    ${headers}    ${payload}

    RETURN    ${response}
