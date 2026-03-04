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
Resource    ../../../util/utilCommon.robot


*** Variables ***
${FILE_PATH}    resources/data/mockPaymentData.json


*** Keywords ***
Send Request And Get Response Data
    [Arguments]    ${gross_amount}  ${reference_no}     ${payment_slip_no}
    Log    ${reference_no}
    Log    ${gross_amount}
    Log    ${payment_slip_no}

    # 1. 准备请求数据：请求路径、请求头、请求数据
    ${base_url}=   Set Variable     https://pg-uat.fuse.co.id/callback
    ${path}=   Set Variable     /mock/channel/midtrans/callback
    ${headers}=    Create Dictionary    Content-Type=application/json
    #1. getJsonBody
    ${jsonBody}=    utilCommon.Get Data From Jsonfile    ${FILE_PATH}    GoPay
    #2. updateJsonBody
    ${gross_amount}    Convert To String    ${gross_amount}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.gross_amount    ${gross_amount}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.order_id    ${reference_no}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.transaction_id    ${payment_slip_no}
    #3. Convert To String
    ${payload}=    Convert Json To String    ${jsonBody}
    # 3. 发送请求
    ${response}=    httpCommon.Send Post Request And Get Response Data    ${base_url}    ${path}    ${headers}    ${payload}

    RETURN    ${response}