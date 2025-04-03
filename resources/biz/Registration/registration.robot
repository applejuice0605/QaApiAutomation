*** Settings ***
Library    RequestsLibrary
Library    Collections
Library    String
Library    XML
Library    ../../env/load_env.py

Resource    ../../api/Registration/partner_invited_get_url.robot
Resource    ../../api/Registration/verificationCode_send.robot
Resource    ../../api/Registration/partner_register.robot

Variables   ../../varfile_defvar.py

*** Keywords ***
Register by share link
    [Arguments]    ${token}     ${mobile}
    ${resonse}  partner_invited_get_url.Send Request And Get Response Data    ${token}
    ${inviteOpenId}   Set Variable     ${resonse.json()}[data][inviteOpenId]

    verificationCode_send.Send Request And Get Response Data    ${mobile}

    ${resonse}  partner_register.Send Request And Get Response Data    ${token}     ${mobile}    ${inviteOpenId}
    ${tenantId}   Set Variable     ${resonse.json()}[data][0][tenantId]