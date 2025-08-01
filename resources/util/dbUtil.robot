*** Settings ***
Library    Collections
Library    RequestsLibrary
Library    testAlert.py

Resource    ../util/httpCommon.robot
Resource    utilCommon.robot

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
    ${headers}=    Create Dictionary    cookie=csrftoken=cLd9hGQGEOi3fWS2F9DKRDy99QibsBIEasjO6nw3DEkNpFQ0KvQr7WWj42J3hj1x; sessionid=p0j75gx9sti8utub8f5d31iu416nijba   x-csrftoken=cLd9hGQGEOi3fWS2F9DKRDy99QibsBIEasjO6nw3DEkNpFQ0KvQr7WWj42J3hj1x
    ${payload}=    Create Dictionary    instance_name=ID_UAT_CORE_MYSQL8.0      db_name=message     schema_name=null   tb_name=sms_record  sql_content=select data->'$.verificationCade' from message.sms_record where mobile='62${${mobile}}' order by id desc limit 1   limit_num=100

    # 2. 发送请求
    ${response}=    httpCommon.Send Post Request And Get Response Data    ${base_url}    ${path}    ${headers}    ${payload}
    
    Log    ${response.json()}
    Log    ${response.json()}[data][rows][0][0]
#    ${original_str}=    Set Variable  ${response.json()}[data][rows][0][0]
    ${sms_code}     Evaluate    ${response.json()}[data][rows][0][0].strip('"')
    RETURN    ${sms_code}


Query
    [Arguments]     ${sql_content}
    # 1. 准备请求数据：请求路径、请求头、请求数据
    ${base_url}=   Set Variable    https://rd-dms.fuseinsurtech.com
    ${path}=   Set Variable     /query/
    ${headers}=    Create Dictionary    cookie=csrftoken=cLd9hGQGEOi3fWS2F9DKRDy99QibsBIEasjO6nw3DEkNpFQ0KvQr7WWj42J3hj1x; sessionid=p0j75gx9sti8utub8f5d31iu416nijba   x-csrftoken=cLd9hGQGEOi3fWS2F9DKRDy99QibsBIEasjO6nw3DEkNpFQ0KvQr7WWj42J3hj1x
    ${payload}=    Create Dictionary    instance_name=ID_UAT_CORE_MYSQL8.0      db_name=message     schema_name=null   tb_name=sms_record  sql_content=${sql_content}

    # 2. 发送请求
    ${response}=    httpCommon.Send Post Request And Get Response Data    ${base_url}    ${path}    ${headers}    ${payload}
    RETURN  ${response}
#    Log    ${response.json()}
#    Log    ${response.json()}[data][rows][0][0]
##    ${original_str}=    Set Variable  ${response.json()}[data][rows][0][0]
#    ${sms_code}     Evaluate    ${response.json()}[data][rows][0][0].strip('"')
#    RETURN    ${sms_code}


Query by Trace_id
    [Arguments]     ${trace_id}
    # 1. 准备请求数据：请求路径、请求头、请求数据
    ${base_url}=   Set Variable    https://rd-dms.fuseinsurtech.com
    ${path}=   Set Variable     /query/
    ${headers}=    Create Dictionary    cookie=csrftoken=cLd9hGQGEOi3fWS2F9DKRDy99QibsBIEasjO6nw3DEkNpFQ0KvQr7WWj42J3hj1x; sessionid=p0j75gx9sti8utub8f5d31iu416nijba   x-csrftoken=cLd9hGQGEOi3fWS2F9DKRDy99QibsBIEasjO6nw3DEkNpFQ0KvQr7WWj42J3hj1x

    ${payload}=    Create Dictionary    instance_name=ID_UAT_CORE_MYSQL8.0      db_name=message     schema_name=null   tb_name=sms_record  sql_content=select * from message.whatsapp_chat_record where trace_id = '${trace_id}' and reply_id is not null order by uid limit 10



    # 2. 发送请求
    ${response}=    httpCommon.Send Post Request And Get Response Data  url=${base_url}    path=${path}    headers=${headers}   body=${payload}
    ${response_data}=    Set Variable    ${response.content}

#    Log    ${response_data.__class__}
#    ${response_data}    Convert To String    ${response_data}
#    Log    ${response_data.__class__}
#    Log    ${response_data}
#    ${response_data}=    Evaluate    json.loads($response_data)
    ${response_data}=    Evaluate    json.loads(${response_data})
#    ${response_data}=   To Json    ${response_data}
    Log    ${response_data.__class__}
    Log    ${response_data}
    Should Be Equal As Strings    ${response_data}[msg]    ok
    ${response_data}=     Convert to Json     ${response_data}[data]
    RETURN  ${response_data}

