*** Settings ***

Library    RequestsLibrary

Resource    ../../util/httpCommon.robot

Variables   ../../varfile_defvar.py


*** Keywords ***

# 发送请求
Send Request And Get Response Data
    [Arguments]    ${mobile}   ${sms_code}  ${inviteFuseId}

    # 1. 准备请求数据：请求路径、请求头、请求数据
        # 优化：根据环境加载域名sit/uat/pre
    ${base_url}=   Set Variable     https://ptr-${env}.fuse.co.id
    ${path}=   Set Variable     /api/prm/partner/register
        # 优化：根据平台加载headers:boss/fusepro
    ${headers}=    Create Dictionary    Content-Type=application/json    clientType=ANDROID    appCode=IDP_FUSE_PRO
    ${payload}=    Set Variable     {"idd":"62","mobile":"${mobile}","companyName":"","nickname":"Nora_API_REG","password":"123456a","code1":"9","code2":"1","code3":"9","code4":"6","accountType":1,"CORPORATE_ARTICLE_OF_ASSOCIATION":[],"CORPORATE_PERMISSION_DOCUMENT":[],"CORPORATE_PIC_KTP":[],"CORPORATE_TAX_DOCUMENT":[],"CORPORATE_POWER_OF_ATTORNEY":[],"email":"nora@fuseinsurtech.com","inviteFuseId":"${inviteFuseId}","c":"JnRlbmFudElkPTEwMDA2NjImbGlua0Zvcm09MSZjaGFubmVsPVNoYXJl","region":"id","channel":"Share","tenantId":"1000662","linkForm":"1","verificationCode":"${sms_code}","inviteType":1,"language":"en_US","attachmentList":[]}

    # 2. 发送请求
    ${response}=    httpCommon.Send Post Request And Get Response Data    ${base_url}    ${path}    ${headers}    ${payload}

    RETURN    ${response}