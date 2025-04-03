*** Settings ***
Library    Collections

Library    RequestsLibrary

Resource    ../util/httpCommon.robot

Variables   ../varfile_defvar.py
#
#*** Test Cases ***
#Test Case 1
#    Get Invite Link SMS Code    812390000002

*** Keywords ***
#Login in Archery
#    [Arguments]    ${username}    ${password}
#    ${response}=    Login    ${username}    ${password}
#    Should Be Equal As Numbers    ${response.status_code}    200
#    ${json}=    To Json    ${response.content}
#    ${token}=    Get From Dictionary    ${json}    token

Get Invite Link SMS Code
    [Arguments]     ${mobile}
    # 1. 准备请求数据：请求路径、请求头、请求数据
    ${base_url}=   Set Variable    https://rd-dms.fuseinsurtech.com
    ${path}=   Set Variable     /query/
    ${headers}=    Create Dictionary    cookie=csrftoken=hZIUazTWWHXwNr7lUBWKwuE8U50G1BYC71By6id1rwjKqQFMD2Efvz4IbUdPsUtT; sessionid=95pahr5qsab4ya7z8mkfcr5axonwfx5m   x-csrftoken=hZIUazTWWHXwNr7lUBWKwuE8U50G1BYC71By6id1rwjKqQFMD2Efvz4IbUdPsUtT
    ${payload}=    Create Dictionary    instance_name=ID_UAT_CORE_MYSQL8.0      db_name=message     schema_name=null   tb_name=sms_record  sql_content=select data->'$.verificationCade' from message.sms_record where mobile='62${${mobile}}' order by id desc limit 1   limit_num=100

    # 2. 发送请求
    ${response}=    httpCommon.Send Post Request And Get Response Data    ${base_url}    ${path}    ${headers}    ${payload}
    
    Log    ${response.json()}
    Log    ${response.json()}[data][rows][0][0]
#    ${original_str}=    Set Variable  ${response.json()}[data][rows][0][0]
    ${sms_code}     Evaluate    ${response.json()}[data][rows][0][0].strip('"')
    RETURN    ${sms_code}

