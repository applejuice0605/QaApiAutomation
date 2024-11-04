*** Settings ***
Documentation
...    use to change change the payment status of the order using VA to pay
...    BASE_URL: https://cashier-uat.fuse.co.id
...    path: /api/paymentBilling/create
...    POST
...    headers: {'Content-Type': 'application/json','clientType': 'ANDROID','appCode': 'IDP_FUSE_PRO', 'fusetoken': 'token'}
...    payload: {"paymentScheme": 1,"payerType": 2,"bonusDeduction": 0,"orderId": "","securityCode": "","selectType": 2,"pointsDeduction": 0,"methodCode": "9203"}

Library    RequestsLibrary
Library    JSONLibrary

Resource    ../../../util/httpCommon.robot


*** Keywords ***
Send Request And Get Response Data
    [Arguments]    ${amount}     ${referenceNo}
    # 1. 准备请求数据：请求路径、请求头、请求数据
    ${base_url}=   Set Variable     https://api.xendit.co
    ${path}=   Set Variable     /callback_virtual_accounts/external_id=${referenceNo}/simulate_payment
    ${headers}=    Create Dictionary    Content-Type=application/json    appCode=IDP_FUSE_PRO    fusetoken=${token}   Authorization=Basic eG5kX2RldmVsb3BtZW50X1JOODZyQWFwV1RvRnJxb3dqTUM3Zm5tYnVMaXZQblg4NjYwUlVNRFpGdWp2N1A2bDl3eU9sWmpSSWhxODUyOg==

    ${payload}=    Set Variable     {"amount": ${amount}}
    # 2. 发送请求
    ${response}=    httpCommon.Send Post Request And Get Response Data    ${base_url}    ${path}    ${headers}    ${payload}

    RETURN    ${response}