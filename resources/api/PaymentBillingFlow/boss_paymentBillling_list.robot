*** Settings ***
Library    RequestsLibrary
Resource    ../../util/httpCommon.robot
Variables   ../../varfile_defvar.py

*** Keywords ***
# 发送请求
Send Request And Get Response Data
    [Arguments]    ${bossToken}     ${orderNo}      ${pageNo}=0     ${pageSize}=20
    # 1. 准备请求数据：请求路径、请求头、请求数据
    ${base_url}=   Set Variable     https://boss-${env}.fuse.co.id
    ${path}=   Set Variable     /api/paymentBilling/list
    ${headers}=    Create Dictionary    Content-Type=application/json    clientType=application/json;charset=UTF-8    appCode=IDP_BOSS  fusetoken=${bossToken}
    ${payload}=    Set Variable     {"pageNo": ${pageNo},"pageSize": ${pageSize},"multiFieldQuery": "${orderNo}"}


    # 2. 发送请求
    ${response}=    httpCommon.Send Post Request And Get Response Data    ${base_url}    ${path}    ${headers}    ${payload}

    RETURN    ${response}