*** Settings ***
Documentation
...    Login by ktp and return userAccount(loginAccount)
...    BASE_URL: https://app-uat.fuseinsurtech.com
...    path: insurance-finance-vs-api/api/fuse/user/login
...    POST
...    headers: {'Content-Type': 'application/json','clientType': 'ANDROID','appCode': 'IDP_FUSE_PRO'}
...    payload: {"loginAccount": "628123268987", "password": "268987"}

Library    RequestsLibrary

Resource    ../../util/httpCommon.robot

Variables   ../../varfile_defvar.py


*** Keywords ***
# 发送请求
Send Request And Get Response Data
    #定义Arguments的变量不是必填
    [Arguments]    ${password}   ${loginWay}    ${ktpNo}=''    ${email}=''  ${mobile}=''
    # 1. 准备请求数据：请求路径、请求头、请求数据
    ${base_url}=   Set Variable     https://app-${env}.fuseinsurtech.com
    ${path}=   Set Variable     /insurance-finance-vs-api/api/fuse/user/login
    ${headers}=    Create Dictionary    Content-Type=application/json    clientType=ANDROID    appCode=IDP_FUSE_PRO
    ${payload}=    Set Variable     {"customPhone": "${mobile}", "ktpNo": "${ktpNo}", "email": "${email}", "loginWay": "${loginWay}","loginPassWord": "${password}","countryCode": "02130000000000","vision": "5.22.0.0-uat","appVersion": "5.22.0.0-uat","loginErrorTimes": "0", "deviceId": "72a5e5babac4eebc4776a745153f4097d5491fec55eb09ff2be7a310603c5aca","osVision": "12","systemVersion": "12", "udid": "V417IR","phoneModel": "ALA-AN70","phoneType": "HONOR", "deviceType": "Android"}


    # 2. 发送请求
    ${response}=    httpCommon.Send Post Request And Get Response Data    ${base_url}    ${path}    ${headers}    ${payload}

    RETURN    ${response}