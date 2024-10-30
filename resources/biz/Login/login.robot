*** Settings ***
Library    RequestsLibrary
Library    Collections
Library    String
Library    XML

Resource    ../../api/Login/fuse_user_login.robot
Resource    ../../api/Login/api_bylogin.robot
Resource    ../../api/Login/api_login.robot

Variables   ../../varfile_defvar.py

*** Keywords ***
Login to Application using mobile
    ${resonse}  api_bylogin.Send Request And Get Response Data      ${loginAccount}     ${password}
    ${openId}   Set Variable     ${resonse.json()}[data][0][openId]
    ${tenantId}   Set Variable     ${resonse.json()}[data][0][tenantId]
    ${response}  api_login.Send Request And Get Response Data    ${loginAccount}     ${password}    ${openId}    ${tenantId}
    ${token}    Set Variable    ${response.json()}[data][token]
    RETURN    ${token}

Login to Application using KTP
    ${resonse}  fuse_user_login.Send Request And Get Response Data    password=${password}  loginWay=4  ktpNo=${ktpNo}
    ${loginAccount}     Get Dictionary Values    ${resonse.json()}[resultObj]    accountId
    ${token}=    Login to Application using mobile
    RETURN    ${token}

Login to Application using email
    ${resonse}  fuse_user_login.Send Request And Get Response Data    password=${password}  loginWay=3  email=${email}
    ${loginAccount}    Get Dictionary Values    ${resonse.json()}[resultObj]    accountId
    ${token}=   Login to Application using mobile
    RETURN    ${token}

