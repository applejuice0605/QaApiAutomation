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
    ${headers}=    Create Dictionary    cookie=__adroll_fpc=6be6a387174f9054dd65546054f7611d-1760584004092; _fbp=fb.1.1760584006506.534717559103612633; csrftoken=hA105hAVK9EX7MDngnoHgCScI92RWEElGBQzNtNU0G0Hi4AwfCVYNGdOWygp2HYq; sessionid=aq6evtekcnw1az9vdimlfxdkrywkyr52   x-csrftoken=hA105hAVK9EX7MDngnoHgCScI92RWEElGBQzNtNU0G0Hi4AwfCVYNGdOWygp2HYq
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
    ${headers}=    Create Dictionary    cookie=csrftoken=rQqCatPDDYW4Ylykn9u2ypF2UZ1rRxLqDWxYGpRRej33CUa7Nfza0uJNANzHNCE8; sessionid=wzjc0c96d5i3x6kxxln7ibi5vtf8sncw; __adroll_fpc=6be6a387174f9054dd65546054f7611d-1760584004092; _fbp=fb.1.1760584006506.534717559103612633   x-csrftoken=rQqCatPDDYW4Ylykn9u2ypF2UZ1rRxLqDWxYGpRRej33CUa7Nfza0uJNANzHNCE8
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
    ${headers}=    Create Dictionary    cookie=csrftoken=rQqCatPDDYW4Ylykn9u2ypF2UZ1rRxLqDWxYGpRRej33CUa7Nfza0uJNANzHNCE8; sessionid=wzjc0c96d5i3x6kxxln7ibi5vtf8sncw; __adroll_fpc=6be6a387174f9054dd65546054f7611d-1760584004092; _fbp=fb.1.1760584006506.534717559103612633   x-csrftoken=rQqCatPDDYW4Ylykn9u2ypF2UZ1rRxLqDWxYGpRRej33CUa7Nfza0uJNANzHNCE8

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

