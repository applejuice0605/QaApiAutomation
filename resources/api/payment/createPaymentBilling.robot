*** Settings ***
Documentation
...    when you place a order and click "confirm continue to pay", this api will be called
...    BASE_URL: https://cashier-uat.fuse.co.id
...    path: /api/paymentBilling/create
...    POST
...    headers: {'Content-Type': 'application/json','clientType': 'ANDROID','appCode': 'IDP_FUSE_PRO', 'fusetoken': 'token'}
...    payload: {"paymentScheme": 1,"payerType": 2,"bonusDeduction": 0,"orderId": "","securityCode": "","selectType": 2,"pointsDeduction": 0,"methodCode": "9203"}

Library    RequestsLibrary
Library    JSONLibrary

Resource    ../../util/httpCommon.robot

*** Keywords ***
Send Request And Get Response Data
    [Arguments]    ${token}   ${securityCode}
    # 1. 准备请求数据：请求路径、请求头、请求数据
    ${base_url}=   Set Variable     https://cashier-uat.fuse.co.id
    ${path}=   Set Variable     /api/paymentBilling/create
    ${headers}=    Create Dictionary    Content-Type=application/json    clientType=ANDROID    appCode=IDP_FUSE_PRO    fusetoken=${token}
    ${payload}=    Set Variable     {"securityCode": "${securityCode}","methodCode": "9203","channelCode": "xendit"}
    # 2. 发送请求
    ${response}=    httpCommon.Send Post Request And Get Response Data    ${base_url}    ${path}    ${headers}    ${payload}

    RETURN    ${response}