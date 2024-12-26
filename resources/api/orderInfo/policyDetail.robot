*** Settings ***
Library    RequestsLibrary
Library    JSONLibrary

Resource    ../../util/httpCommon.robot

*** Keywords ***
POST FusePro:/api/order/v2/slip/slipLs
    [Arguments]    ${token}   ${orderId}
    # 1. 准备请求数据：请求路径、请求头、请求数据
    ${base_url}=   Set Variable     https://ptr-uat.fuse.co.id
    ${path}=   Set Variable     /api/order/v2/slip/slipLs
    ${headers}=    Create Dictionary    Content-Type=application/json    clientType=ANDROID    appCode=IDP_FUSE_PRO    fusetoken=${token}
#    ${payload}=    Set Variable     {"orderId":${orderId}}
    ${payload}=    Set Variable     {"orderId":"${orderId}"}
    # 2. 发送请求
    ${response}=    httpCommon.Send Post Request And Get Response Data    ${base_url}    ${path}    ${headers}    ${payload}

    RETURN    ${response}