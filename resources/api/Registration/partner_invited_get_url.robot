*** Settings ***

Library    RequestsLibrary

Resource    ../../util/httpCommon.robot

Variables   ../../varfile_defvar.py


*** Keywords ***

# 发送请求
Send Request And Get Response Data
    [Arguments]    ${token}

    # 1. 准备请求数据：请求路径、请求头、请求数据
        # 优化：根据环境加载域名sit/uat/pre
    ${base_url}=   Set Variable     https://ptr-${env}.fuse.co.id
    ${path}=   Set Variable     /api/partner/invited/get/url
        # 优化：根据平台加载headers:boss/fusepro
    ${headers}=    Create Dictionary    Content-Type=application/json    clientType=ANDROID    appCode=IDP_FUSE_PRO     tenantId=1000662    fusetoken=${token}
    ${payload}=    Set Variable     {}

    # 2. 发送请求
    ${response}=    httpCommon.Send Post Request And Get Response Data    ${base_url}    ${path}    ${headers}    ${payload}

    RETURN    ${response}