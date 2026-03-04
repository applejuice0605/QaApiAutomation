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
    [Arguments]    ${token}    ${amount}     ${referenceNo}
    # 1. 准备请求数据：请求路径、请求头、请求数据
    ${base_url}=   Set Variable     https://api.xendit.co
    ${path}=   Set Variable     /callback_virtual_accounts/external_id=${referenceNo}/simulate_payment
    ${headers}=    Create Dictionary    Host=api.xendit.co  Connection=keep-alive    charset=utf-8   Authorization=Basic eG5kX2RldmVsb3BtZW50X1JOODZyQWFwV1RvRnJxb3dqTUM3Zm5tYnVMaXZQblg4NjYwUlVNRFpGdWp2N1A2bDl3eU9sWmpSSWhxODUyOg==    Content-Type=application/json

    ${payload}=    Set Variable     {"amount": ${amount}}
    # 2. 发送请求
    ${response}=    httpCommon.Send Post Request And Get Response Data    ${base_url}    ${path}    ${headers}    ${payload}

    RETURN    ${response}

https://api.xendit.co/callback_virtual_accounts/external_id=4F9DE3BFDD5E436BA8740B73A4412B6C/simulate_payment
https://api.xendit.co/callback_virtual_accounts/external_id=8CD58AE7F5E54F16A405222C7D592648/simulate_payment

Basic eG5kX2RldmVsb3BtZW50X1JOODZyQWFwV1RvRnJxb3dqTUM3Zm5tYnVMaXZQblg4NjYwUlVNRFpGdW
Basic eG5kX2RldmVsb3BtZW50X1JOODZyQWFwV1RvRnJxb3dqTUM3Zm5tYnVMaXZQblg4NjYwUlVNRFpGdWp2N1A2bDl3eU9sWmpSSWhxODUyOg==