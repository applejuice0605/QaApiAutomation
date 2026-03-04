*** Settings ***
Documentation
...    slip/process API
...    BASE_URL: https://cashier-uat.fuse.co.id
...    path: api/cashier/partner/payment/slip/process
...    POST
...    headers: {'Content-Type': 'application/json','clientType': 'ANDROID','appCode': 'IDP_FUSE_PRO', 'fusetoken': 'token'}
...    payload: {"paymentScheme": 1,"payerType": 2,"bonusDeduction": 0,"orderId": "","securityCode": "","selectType": 2,"pointsDeduction": 0,"methodCode": "9203"}
...    paymentScheme: 1 (FullPayment), 2 (NetPayment), 3 (SuperNetPayment)
...    payerType: 1 (CustomerPay), 2 (PartnerPay)   ----need to confirm
...    selectType: 1 (Bonus), 2 (Points), 3 (Bonus & Points)   ----need to confirm
...    methodCode: 9203 (), 9204 (), 9205 ()   ----need to confirm


Library    RequestsLibrary
Library    JSONLibrary

Resource    ../../util/httpCommon.robot

*** Keywords ***
Send Request And Get Response Data
    [Arguments]    ${payerType}     ${token}   ${selectType}     ${paymentScheme}    ${orderId}    ${securityCode}     ${bonusDeduction}=0    ${pointsDeduction}=0     ${methodCode}=""
    # 1. 准备请求数据：请求路径、请求头、请求数据
    ${base_url}=   Set Variable     https://cashier-uat.fuse.co.id
    ${headers}=    Get appHeader By PayerType    ${payerType}    ${token}

    ${payerTypeStr}    httpCommon.Get String PayerType    ${payerType}
    Log    ${payerTypeStr}
    ${path}=   Set Variable     api/cashier/${payerTypeStr}/payment/slip/process

    ${payload}=    Set Variable     {"paymentScheme": ${paymentScheme},"payerType": ${payerType},"bonusDeduction": ${bonusDeduction},"orderId": "${orderId}","securityCode": "${securityCode}","selectType": ${selectType},"pointsDeduction": ${pointsDeduction},"methodCode": ${methodCode}}

    # 2. 发送请求
    ${response}=    httpCommon.Send Post Request And Get Response Data    ${base_url}    ${path}    ${headers}    ${payload}

    RETURN    ${response}




Partner Pay Send Request And Get Response Data
    [Arguments]    ${token}   ${selectType}     ${paymentScheme}    ${orderId}    ${securityCode}     ${bonusDeduction}=0    ${pointsDeduction}=0     ${methodCode}=9204
    # 1. 准备请求数据：请求路径、请求头、请求数据
    ${base_url}=   Set Variable     https://cashier-uat.fuse.co.id
    ${path}=   Set Variable     api/cashier/partner/payment/slip/process
    ${headers}=    Create Dictionary    Content-Type=application/json    clientType=ANDROID    appCode=IDP_FUSE_PRO    fusetoken=${token}
    ${payload}=    Set Variable     {"paymentScheme": ${paymentScheme},"payerType": 2,"bonusDeduction": ${bonusDeduction},"orderId": "${orderId}","securityCode": "${securityCode}","selectType": ${selectType},"pointsDeduction": ${pointsDeduction},"methodCode": ${methodCode}}

    # 2. 发送请求
    ${response}=    httpCommon.Send Post Request And Get Response Data    ${base_url}    ${path}    ${headers}    ${payload}

    RETURN    ${response}

Customer Pay Send Request And Get Response Data
    [Arguments]    ${token}   ${orderId}    ${securityCode}     ${bonusDeduction}=0    ${pointsDeduction}=0
    # 1. 准备请求数据：请求路径、请求头、请求数据
    ${base_url}=   Set Variable     https://cashier-uat.fuse.co.id
    ${path}=   Set Variable     api/cashier/customer/payment/slip/process
    ${headers}=    Create Dictionary    Content-Type=application/json    x-5a-temp-token=${token}
#    在app选中customer pay-> click continue时调用该接口，select type = 1
    ${payload}=    Set Variable     {"paymentScheme": 1,"payerType": 1,"bonusDeduction": ${bonusDeduction},"orderId": "${orderId}","securityCode": "${securityCode}","selectType": 2,"pointsDeduction": ${pointsDeduction},"methodCode": ""}

    # 2. 发送请求
    ${response}=    httpCommon.Send Post Request And Get Response Data    ${base_url}    ${path}    ${headers}    ${payload}

    RETURN    ${response}