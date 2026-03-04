*** Settings ***
Library    RequestsLibrary
Library    Collections
Library    String
Library    XML
Library    ../../env/load_env.py
Resource    ../../api/Login/fuse_user_login.robot
Resource    ../../api/Login/api_bylogin.robot
Resource    ../../api/Login/api_login.robot
Resource    ../../api/Login/boss/login.robot
Resource    ../../api/Login/boss/bylogin.robot
Resource    ../../api/Login/loginDify.robot

Variables   ../../varfile_defvar.py

*** Keywords ***
Login to Application using mobile
    [Arguments]    ${loginAccount}=628123268987    ${password}=268987
    ${resonse}  api_bylogin.Send Request And Get Response Data      ${loginAccount}     ${password}     loginMethod=mobile
    ${openId}   Set Variable     ${resonse.json()}[data][0][openId]
    ${tenantId}   Set Variable     ${resonse.json()}[data][0][tenantId]
    ${response}  api_login.Send Request And Get Response Data    ${loginAccount}     ${password}    ${openId}    ${tenantId}    loginMethod=mobile
    ${token}    Set Variable    ${response.json()}[data][token]
    RETURN    ${token}

Login to Application using KTP
    [Arguments]    ${ktpNo}=6398630909968523    ${password}=268987
    ${response}    api_bylogin.Send Request And Get Response Data    ${ktpNo}    ${password}     loginMethod=nationId
    Set Test Variable    ${openId}  ${response.json()}[data][0][openId]
    Set Test Variable    ${tenantId}  ${response.json()}[data][0][tenantId]
    ${response}    api_login.Send Request And Get Response Data    ${ktpNo}    ${password}    ${openId}    ${tenantId}   loginMethod=nationId

#    Set Test Variable    ${jsonResult}    ${response.json()}
#    Log    ${jsonResult}
#
#    Log    ${jsonResult}[data][token]
#    ${resonse}  fuse_user_login.Send Request And Get Response Data    password=${password}  loginWay=4  ktpNo=${ktpNo}
#    ${loginAccount}     Get Dictionary Values    ${resonse.json()}[resultObj]    accountId
    ${token}=    Set Variable    ${response.json()}[data][token]
    RETURN    ${token}


Login to Application using email
    ${resonse}  fuse_user_login.Send Request And Get Response Data    password=${password}  loginWay=3  email=${email}
    ${loginAccount}    Get Dictionary Values    ${resonse.json()}[resultObj]    accountId
    ${token}=   Login to Application using mobile
    RETURN    ${token}

Login to Boss
    [Arguments]    ${BossAccount}=ceo001    ${BossPassword}=Fuse!001
    ${resonse}  bylogin.Send Request And Get Response Data      ${BossAccount}     ${BossPassword}
    ${openId}   Set Variable     ${resonse.json()}[data][1][openId]
    ${tenantId}   Set Variable     ${resonse.json()}[data][1][tenantId]
    ${response}  login.Send Request And Get Response Data    ${BossAccount}     ${BossPassword}    ${openId}    ${tenantId}
    ${token}    Set Variable    ${response.json()}[data][token]
    RETURN    ${token}

Login to Application With Mobile ${mobile} And Password ${password}
    ${resonse}  api_bylogin.Send Request And Get Response Data      ${mobile}     ${password}
    ${openId}   Set Variable     ${resonse.json()}[data][0][openId]
    ${tenantId}   Set Variable     ${resonse.json()}[data][0][tenantId]
    ${response}  api_login.Send Request And Get Response Data    ${mobile}     ${password}    ${openId}    ${tenantId}
    ${token}    Set Variable    ${response.json()}[data][token]
#    Change Env    TOKEN    ${token}
    RETURN    ${token}


Login to Dify
    [Arguments]    ${loginAccount}=nora.cai@fuse.co.id    ${password}=Csb2337763269.
    ${resonse}  loginDify.Send Request And Get Response Data      ${loginAccount}     ${password}
    ${access_token}   Set Variable     ${resonse.json()}[data][access_token]
    RETURN    ${access_token}


