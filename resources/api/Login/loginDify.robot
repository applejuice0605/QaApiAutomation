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
    [Arguments]    ${loginAccount}    ${password}
    ${base_url}=   Set Variable     https://rd-dify-sit.fuse.co.id
    ${path}=   Set Variable     /console/api/login
    ${headers}=    Create Dictionary    Content-Type=application/json   Accept=*/*  authorization=Bearer
#    ${payload}=    Create Dictionary    email=nora.cai@fuse.co.id  password=Csb2337763269   language=zh-Hans    remember_me=true
    ${payload}=    Set Variable    {"email":"${loginAccount}","password":"${password}","language":"zh-Hans", "remember_me": "true"}
    # 2. 发送请求
    ${response}=    httpCommon.Send Post Request And Get Response Data    ${base_url}    ${path}    ${headers}    ${payload}

    RETURN    ${response}
