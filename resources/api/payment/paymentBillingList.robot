*** Settings ***
Documentation
...    when you place a order and click "confirm continue to pay", this api will be called
...    BASE_URL: https://ptr-uat.fuse.co.id
...    path: /api/paymentBilling/list
...    POST
...    headers: {'Content-Type': 'application/json','clientType': 'ANDROID','appCode': 'IDP_FUSE_PRO', 'fusetoken': 'token'}
...    payload: {orderUid: "orderId",slipUids: ["slipNo1","slipNo2"]}

Library    RequestsLibrary
Library    JSONLibrary

Resource    ../../util/httpCommon.robot

*** Keywords ***
Send Request And Get Response Data
    [Documentation]     获取安全码，slipIds的参数为一个字典，形如：["slipNo1","slipNo2"]
    [Arguments]    ${token}   ${orderId}    ${slipIds}=[]
    # 1. 准备请求数据：请求路径、请求头、请求数据
    ${base_url}=   Set Variable     https://ptr-uat.fuse.co.id
    ${path}=   Set Variable     /api/paymentBilling/list
    ${headers}=    Create Dictionary    Content-Type=application/json    clientType=ANDROID    appCode=IDP_FUSE_PRO    fusetoken=${token}
    ${payload}=    Set Variable     {orderUid: "${orderId}",slipUids: ${slipIds}}

    # 2. 发送请求
    ${response}=    httpCommon.Send Post Request And Get Response Data    ${base_url}    ${path}    ${headers}    ${payload}

    RETURN    ${response}