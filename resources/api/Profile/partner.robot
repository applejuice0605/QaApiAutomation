*** Settings ***
Library    RequestsLibrary

Resource    ../../util/httpCommon.robot

*** Variables ***
# 优化：根据环境加载域名sit/uat/prod
${app_baseurl}  https://app-uat.fuseinsurtech.com/



*** Keywords ***
# 发送请求
Send register_getShortLink Request And Get Response Data
    [Documentation]     https://app-uat.fuseinsurtech.com/insurance-finance-vs-api/api/fuse/register/getShortLink
    [Arguments]    ${fusetoken}    ${inviteCode}

    # 1. 准备请求数据：请求路径、请求头、请求数据
    ${path}=   Set Variable     /insurance-finance-vs-api/api/fuse/register/getShortLink
        # 优化：根据平台加载headers:boss/fusepro
    ${headers}=    Create Dictionary    fusetoken=${fusetoken}
    ${payload}=    Set Variable    {"actualUrl": "https://app-uat.fuseinsurtech.com/h5/share_register/shareRegister.html?r=${inviteCode}","inviteCode": "${inviteCode}"}}

    # 2. 发送请求
    ${response}=    httpCommon.Send Post Request And Get Response Data    ${app_baseurl}    ${path}    ${headers}    ${payload}

    RETURN    ${response}


Send newVerificationCode Request And Get Response Data
    [Documentation]     https://app-uat.fuseinsurtech.com/insurance-finance-pre-service/pre/v2/agent/newVerificationCode
    [Arguments]    ${sign}    ${mobile}    ${languageType}    ${inviteCode}    ${recaptchaToken}

    # 1. 准备请求数据：请求路径、请求头、请求数据
    ${path}=   Set Variable     /insurance-finance-pre-service/pre/v2/agent/newVerificationCode
        # 优化：根据平台加载headers:boss/fusepro
    ${headers}=    Create Dictionary    sign=${sign}    mobile=${mobile}    languageType=${languageType}    invitationCode=${inviteCode}    recaptchaToken=${recaptchaToken}
    ${payload}=    Set Variable    {}



    # 2. 发送请求
    ${response}=    httpCommon.Send Post Request And Get Response Data    ${app_baseurl}    ${path}    ${headers}    ${payload}

    RETURN    ${response}

