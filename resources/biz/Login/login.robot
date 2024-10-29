*** Settings ***
Library    RequestsLibrary
Library    Collections
Library    String
Library    XML

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


