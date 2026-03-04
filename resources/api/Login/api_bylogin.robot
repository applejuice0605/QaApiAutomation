*** Settings ***
Documentation
...    Login by login account and password and Will get openId & tenantId
...    BASE_URL: https://sso-uat.fuse.co.id
...    path: /api/sso/h5/user/tenants/byLogin
...    POST
...    headers: {'Content-Type': 'application/json','clientType': 'ANDROID','appCode': 'IDP_FUSE_PRO'}
...    payload: {"loginAccount": "628123268987", "password": "268987"}

Library    RequestsLibrary

Resource    ../../util/httpCommon.robot

Variables   ../../varfile_defvar.py


*** Keywords ***

# 发送请求
Send Request And Get Response Data
    [Arguments]    ${loginAccount}    ${password}   ${loginMethod}

    # 1. 准备请求数据：请求路径、请求头、请求数据
        # 优化：根据环境加载域名sit/uat/pre
    Run Keyword If    '${env}' == 'pre'
    ...    Set Test Variable    ${base_url}    https://sso.fuse.co.id
    ...  ELSE
    ...    Set Test Variable    ${base_url}    https://sso-${env}.fuse.co.id


    ${path}=   Set Variable     /api/sso/h5/user/tenants/byLogin
        # 优化：根据平台加载headers:boss/fusepro
    ${headers}=    Create Dictionary    Content-Type=application/json    clientType=ANDROID    appCode=IDP_FUSE_PRO
    ${payload}=    Evaluate    json.dumps({"loginAccount": "${loginAccount}","password": "${password}", "loginMethod": "${loginMethod}"})

    # 2. 发送请求
    ${response}=    httpCommon.Send Post Request And Get Response Data    ${base_url}    ${path}    ${headers}    ${payload}

    RETURN    ${response}