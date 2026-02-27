*** Settings ***
Library    Collections
Library    RequestsLibrary

Resource    ../util/httpCommon.robot
Resource    utilCommon.robot

Variables   ../varfile_defvar.py

*** Variables ***
${csrftoken}    K5gpH4VFgaQ8W5VShL5Gz3Fo6y6sFeCGT9ILJWpKTkGPjMvk3GdDfVpMWkc02MoE
${sessionid}    hlw19wveu70dr5obyqokt22ph8inx2wi




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
    ${headers}=    Create Dictionary    cookie=csrftoken=${csrftoken}; sessionid=${sessionid}   x-csrftoken=${csrftoken}
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
    ${headers}=    Create Dictionary    cookie=csrftoken=${csrftoken}; sessionid=${sessionid}   x-csrftoken=${csrftoken}
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
    [Documentation]    查询数据库，根据trace_id查询WhatsApp聊天记录,返回聊天记录列表,如果没有数据继续查询直到查询到数据或者查询次数超过10次
    [Arguments]     ${trace_id}
    # 1. 准备请求数据：请求路径、请求头、请求数据
    ${base_url}=   Set Variable    https://rd-dms.fuseinsurtech.com
    ${path}=   Set Variable     /query/
    ${headers}=    Create Dictionary    cookie=csrftoken=${csrftoken}; sessionid=${sessionid}   x-csrftoken=${csrftoken}
    ${payload}=    Create Dictionary    instance_name=ID_UAT_CORE_MYSQL8.0      db_name=message     schema_name=null   tb_name=whatsapp_chat_record  sql_content=select * from message.whatsapp_chat_record where trace_id = '${trace_id}' order by uid limit 10
    Log    ${payload}

    # ${i}    Set Variable    0
    # FOR    ${i}    IN RANGE    10
    FOR    ${i}    IN RANGE    0    10
        Log    ${i}
        # 2. 发送请求
        ${response}=    httpCommon.Send Post Request And Get Response Data    ${base_url}    ${path}    ${headers}    ${payload}
        
        # 3. 解析响应数据
        ${response_data}=    Set Variable    ${response.json()}
        Log    ${response_data}
        Log    ${response_data.__class__}


        # 4. 校验响应数据
        # 校验rows字段是否存在且长度大于0
        Should Contain    ${response_data}[data]    rows
        ${len}    Evaluate    len(${response_data}[data][rows])
        Log    ${len.__class__}
        Run Keyword If    ${len} > 0    Log    ${response_data}[data][rows][0][0]
        IF    ${len} > 0
            BREAK
        END
        Sleep    5s
    END
    Log    ${response_data}
    
    IF    ${i} < 10
        Log    ${response_data}[data][rows][0]
        # 遍历rows字段，将每个元素添加到字典中
        ${result_dict}=    Create Dictionary
        ${column_list}=    Get From Dictionary    ${response_data}[data]    column_list
        ${row_data}=       Get From List         ${response_data}[data][rows]    0
        ${len}=            Get Length            ${column_list}
        Log    Columns length: ${len}
        
        # 定义需要进行 JSON 反序列化的字段
        @{JSON_FIELDS}=    Create List    conversation_metadata
        
        FOR    ${index}    IN RANGE    0    ${len}
            ${key}=    Set Variable    ${column_list}[${index}]
            ${value}=  Set Variable    ${row_data}[${index}]
            # --- 核心改进：JSON 反序列化 ---
            # 检查当前字段是否需要进行反序列化
            ${is_json_field}=    Run Keyword And Ignore Error    List Should Contain Value    ${JSON_FIELDS}    ${key}
            Log    need to parse ${key}

            IF    ${is_json_field}
                Log    Attempting to parse JSON field: ${key}
                # 使用 Evaluate 关键字调用 Python 的 json.loads()
                # Run Keyword And Ignore Error 用于捕获解析失败的情况
                ${parsed_value}=    Run Keyword And Ignore Error    Evaluate    json.loads('''${value}''')
                
                # 检查解析结果。如果解析成功，返回的是字典；如果失败，第一个元素是 'FAIL'
                IF    '${parsed_value[0]}' != 'FAIL'
                    ${value}=    Set Variable    ${parsed_value[1]}  # 使用解析后的字典
                    Log    Successfully parsed ${key} as Dictionary.
                ELSE
                    Log    WARNING: Failed to parse ${key} as JSON. Using original string.
                END
            END
            # --- JSON 反序列化结束 ---
    
            # 将键值对存入结果字典
            Set To Dictionary    ${result_dict}    ${key}    ${value}
        END
        RETURN    ${result_dict}
    ELSE
        Log    没有查询到数据
        RETURN    ${None}
    END

    #     FOR    ${index}    IN RANGE    0    ${len}
    #         Log    ${index}
    #         # 处理data字段，将其转换为字典
        
    #         Log    ${response_data}[data][column_list][${index}]
    #         Log    ${response_data}[data][rows][0][${index}]
    #         ${key}    Set Variable    ${response_data}[data][column_list][${index}]
    #         ${value}    Set Variable    '${response_data}[data][rows][0][${index}]'
    #         # 将value转换成字符串
    #         ${value}    Set Variable    ${value.strip('"')}
    #         Log    ${value}
    #         IF    '${response_data}[data][column_list][${index}]' == 'conversation_metadata'
    #             ${conversation_metadata}    Set Variable    ${response_data}[data][rows][0][${index}]
    #         ELSE
    #             Set To Dictionary    ${result_dict}    ${response_data}[data][column_list][${index}]    ${response_data}[data][rows][0][${index}]
    #         END
    #     END
    #     RETURN    ${result_dict}    ${conversation_metadata}
    # ELSE
    #     Log    没有查询到数据
    #     RETURN    ${null}
    # END