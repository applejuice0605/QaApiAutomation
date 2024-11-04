*** Settings ***
Documentation
...    slip/process API
...    BASE_URL: https://cashier-uat.fuse.co.id
...    path: /cashier/partner/payment/slip/channel/process
...    POST
...    headers: {'Content-Type': 'application/json','clientType': 'ANDROID','appCode': 'IDP_FUSE_PRO', 'fusetoken': 'token'}
...    payload: {"paymentScheme": 1,"payerType": 2,"bonusDeduction": 0,"orderId": "","securityCode": "","selectType": 2,"pointsDeduction": 0,"methodCode": "9203"}

Library    RequestsLibrary
Library    JSONLibrary

Resource    ../../util/httpCommon.robot


*** Variables ***
${extJson}

*** Keywords ***
Send Request And Get Response Data
    [Arguments]    ${token}   ${securityCode}    ${amount}    ${methodCode}  ${bank}=BCA
    # 1. 准备请求数据：请求路径、请求头、请求数据
    ${base_url}=   Set Variable     https://cashier-uat.fuse.co.id
    ${path}=   Set Variable     /api/cashier/partner/payment/slip/channel/process
    ${headers}=    Create Dictionary    Content-Type=application/json    clientType=ANDROID    appCode=IDP_FUSE_PRO    fusetoken=${token}
    Log     ${methodCode}
    Run Keyword If     ${methodCode} == 9203     Set Test Variable    ${extJson}    {"mobileNumber": "+628123268987"}
    ...  ELSE IF    ${methodCode} == 9204   Set Test Variable    ${extJson}    {"bankCode": "${bank}"}
    ${payload}=    Set Variable     {"amount": ${amount},"methodCode": "${methodCode}","securityCode": "${securityCode}","extJson": ${extJson}}


    # 2. 发送请求
    ${response}=    httpCommon.Send Post Request And Get Response Data    ${base_url}    ${path}    ${headers}    ${payload}

    RETURN    ${response}