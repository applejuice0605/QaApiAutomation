*** Settings ***

Documentation   接口描述、定义，请求体示例
...    Login by login account & password & tenantId & openId and Will get token
...    BASE_URL: https://sso-uat.fuse.co.id
...    path: /api/sso/app/user/login
...    POST
...    headers: {'Content-Type': 'application/json','clientType': 'ANDROID','appCode': 'IDP_FUSE_PRO'}
...    payload: {"password": "268989","loginAccount": "628123268989","tenantId": "1000662","openId": "LD8KXZGP3E74","deviceInfo": {"customPhone": "628123268987","loginWay": "0","loginPassWord": "268987","countryCode": "02130000000000","vision": "5.16.0.5-sit","appVersion": "5.16.0.5-sit","loginErrorTimes": "0","osVision": "9","systemVersion": "9","deviceId": "PQ3B.190801.07101020","udid": "PQ3B.190801.07101020","phoneModel": "TAS-AN00","phoneType": "HUAWEI","deviceType": "Android","latitude": "39.915000915","longitude": "116.403999328","language": "en_US"}}

Library    RequestsLibrary
Library    JSONLibrary
Resource    ../../util/httpCommon.robot
Variables   ../../varfile_defvar.py


*** Keywords ***
# 准备请求数据 not used now
Set Request Data
    [Arguments]    ${loginAccount}    ${password}   ${openId}   ${tenantId}
    Run Keyword If    '${env}' == 'pre'
    ...    Set Test Variable    ${base_url}    https://sso.fuse.co.id
    ...  ELSE
    ...    Set Test Variable    ${base_url}    https://sso-${env}.fuse.co.id



    Set Test Variable    ${path}     /api/sso/app/user/login
    ${header}=    Create Dictionary    Content-Type=application/json    clientType=ANDROID    appCode=IDP_FUSE_PRO
    Set Test Variable    ${headers}     ${header}
    ${payload}=    Evaluate    json.dumps({"password": "${password}","loginAccount": "${loginAccount}","tenantId": "${tenantId}","openId": "${openId}","deviceInfo": {"customPhone": "${loginAccount}","loginWay": "0","loginPassWord": "${password}","countryCode": "02130000000000","vision": "5.16.0.5-sit","appVersion": "5.16.0.5-sit","loginErrorTimes": "0","osVision": "9","systemVersion": "9","deviceId": "PQ3B.190801.07101020","udid": "PQ3B.190801.07101020","phoneModel": "TAS-AN00","phoneType": "HUAWEI","deviceType": "Android","latitude": "39.915000915","longitude": "116.403999328","language": "en_US"}})
    Set Test Variable    ${payload}     ${payload}

# 发送请求
Send Request And Get Response Data
    [Arguments]    ${loginAccount}    ${password}   ${openId}   ${tenantId}     ${loginMethod}
    # 1. 准备请求数据：请求路径、请求头、请求数据
    ${base_url}=   Set Variable     https://sso-${env}.fuse.co.id
    ${path}=   Set Variable     /api/sso/app/user/login
    ${headers}=    Create Dictionary    Content-Type=application/json    clientType=ANDROID    appCode=IDP_FUSE_PRO
    ${payload}=    Evaluate    json.dumps({"password": "${password}","loginAccount": "${loginAccount}","tenantId": "${tenantId}","openId": "${openId}", "loginMethod": "${loginMethod}"})

    # 发送请求
    ${response}=    httpCommon.Send Post Request And Get Response Data    ${base_url}    ${path}    ${headers}    ${payload}

    RETURN    ${response}
