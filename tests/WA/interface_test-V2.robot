*** Settings ***
Library    RequestsLibrary
#Library    ExcelHandler    WITH NAME    ExcelHandler
Library    ExcelHandler.py  WITH NAME    ExcelHandler
#Library    SSECustom.py    WITH NAME    SSE
Library    Collections
Library    SSELibrary.py    WITH NAME    SSELibrary


Suite Setup    初始化测试环境
Suite Teardown  清理测试环境

*** Variables ***
${EXCEL_PATH}      resources/data/chatFlow.xlsx
${SHEET_NAME}      V2
${CHAT_FLOW_KEY}   31f725aa-dcce-4a92-a476-e4d14db2c3ed
${API_BASE_URL}    https://rd-dify-sit.fuse.co.id/console/api/apps/
${authorization}   Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiNTUyYmRiODktNTlkOC00NDExLWJiZmYtMjM3MGQwOWQ4MTljIiwiZXhwIjoxNzQ3OTYwNzkxLCJpc3MiOiJTRUxGX0hPU1RFRCIsInN1YiI6IkNvbnNvbGUgQVBJIFBhc3Nwb3J0In0.sn1Xz1FsH0fHwbpL0l-F90IBdp2UcqsyM25V_f9H0oM
${payload}    {"inputs":{"result":"TOYOTA,AVANZA 1.3 E M/T (F653RM-GMDFJ),2019","type":"2"},"files":[]}

*** Keywords ***

Log Inputs and Outputs
    [Arguments]    ${inputs}    ${outputs}
    Log    ouput is ${inputs}
    Log    outputs is ${outputs}

初始化测试环境
#    ExcelHandler.Open Excel    ${EXCEL_PATH}    ${SHEET_NAME}
#    Create Session    api_session    ${API_BASE_URL}
    Log    初始化测试环境

清理测试环境
    ExcelHandler.Close Excel
    Delete All Sessions


执行接口请求
    [Arguments]    ${input_data}
    ${url}=   Set Variable     ${API_BASE_URL}${CHAT_FLOW_KEY}/workflows/draft/run
    ${headers}=    Create Dictionary    authorization=${authorization}  Accept=*/*  Content-Type=application/json
    ${payload}=    Set Variable   {"inputs":${input_data}, "files":[]}
    Log    ${url}
    Log    ${headers}
    Log    ${payload}
    Create Session    api_session    ${url}
    ${response} =    POST On Session    api_session     url=${url}    headers=${headers}  data=${payload}
#    Log    ${response.content}
#    ${result}=    Set Variable    ${response.content}
#    ${type}     Evaluate    type(${result})
    Log    ${response.text}
#    ${type}     Evaluate    type(${response.text})
    ${text_str} =    Evaluate    str(r'''${response.text}''')
    Log    ${text_str}
    # 将字符串中的data: 替换成 ,
    ${new_string}=    Evaluate    r'''${text_str}'''.replace('data: ', ',')
    # 去除字符串开头的,
    ${new_string}=    Evaluate    r'''${new_string}'''.lstrip(',')
    # 在字符串开头和结尾加上[]
    ${new_string}=    Evaluate    r'''[${new_string}]'''


#
#
#    # 将字符串中的data: 替换成,“data: ”
#    ${new_string}=    Evaluate    r'''${response.text}'''.replace('data: ', ',"data": ')
#    Log    ${new_string}
#    # 去除字符串开头的,
#    ${new_string}=    Evaluate    r'''${new_string}'''.lstrip(',')
#    # 在字符串开头和结尾加上{
#    ${new_string}=    Evaluate    r'''{${new_string}}'''
#    Log    ${new_string}

    # 将字符串转换为字典
    ${data}=    Evaluate    json.loads(r'''${new_string}''')
    Log    ${data}

    # 过滤字典数据，只取event = node_finished的数据
    ${filtered_data}=    Evaluate    [d for d in ${data} if d['event'] == 'node_finished']
    Log    ${filtered_data}


    # 整个workflow有四类时间，workflow_started->node_started->node_finished->node_started->node_finished->...->node_started->node_finished->workflow_finished
    # 只需要关注node_finished事件的数据，关注他的执行状态，input，ouput
#    这类事件返回的数据中，如下面的json，data.node_id都是固定的
#    '''
#    {
#        "event": "node_finished",
#        "workflow_run_id": "b53ad17a-eed6-402c-8b4a-26ce07ef6460",
#        "task_id": "b0e8fc6c-9d72-4b5e-b0ca-ed9f5dfc90f9",
#        "data": {
#            "id": "31876dab-5883-4c14-b557-22a1f698ed33",
#            "node_id": "1745920589742",
#            "node_type": "knowledge-retrieval",
#            "title": "\u653f\u5e9c\u8f66\u8f86\u4fe1\u606f\u6620\u5c04",
#            "index": 4,
#            "predecessor_node_id": "1745920438631",
#            "inputs": {
#                "query": "toyota"
#            },
#            "process_data": null,
#            "outputs": {
#                "result": [
#                    ...省略
#                }
#            },
#            "status": "succeeded",
#            "error": null,
#            "elapsed_time": 1.299531,
#            "execution_metadata": null,
#            "created_at": 1747957229,
#            "finished_at": 1747957230,
#            "files": [],
#            "parallel_id": null,
#            "parallel_start_node_id": null,
#            "parent_parallel_id": null,
#            "parent_parallel_start_node_id": null,
#            "iteration_id": null,
#            "loop_id": null
#        }
#    }
#    '''

    # 定义需要检查的 nodeid 列表，针对不同的workflow
    #政府车型库flow的,type=2
    @{allowed_ids_type_2}=    Create List    1745920589742    1745920896053    17470433618670

    # 遍历字典
    FOR    ${item}    IN    @{filtered_data}
#        Log    ${item}
#        # 判断${item}的event字段是否 = node_finished
#        ${event}=    Get From Dictionary    ${item}    event
#        Log    ${event}
        # 初始化is_allowed
        ${is_allowed}=    Set Variable    False

        # 获取${value}的data字段
        ${data}=    Get From Dictionary    ${item}    data
        Log    ${data}
        # 获取${data}node_id
        ${node_id}=    Get From Dictionary    ${data}    node_id
        Log    ${node_id}
        # 判断${node_id}是否在允许列表中
        ${is_allowed}=    Evaluate    "${node_id}" in @{allowed_ids_type_2}
        # node_id 在 允许列表中，则打印${value}[data][inputs]和${value}[data][outputs]
        Run Keyword If    ${is_allowed}
        ...    Log Inputs and Outputs    ${item}[data][inputs]    ${item}[data][outputs]




#        # 初始化is_node_finished 和 is_allowed
#        ${is_node_finished}=    Set Variable    False
#        ${is_allowed}=    Set Variable    False
#        ${is_node_finished}=    Run Keyword And Return Status    Should Be Equal    ${event}    node_finished
#        # 的event = node_finished
#        IF    ${is_node_finished}
#            # 获取${value}的data字段
#            ${data}=    Get From Dictionary    ${item}    data
#            Log    ${data}
#            # 获取${data}node_id
#            ${node_id}=    Get From Dictionary    ${data}    node_id
#            Log    ${node_id}
#            # 判断${node_id}是否在允许列表中
#            ${is_allowed}=    Evaluate    "${node_id}" in @{allowed_ids_type_2}
#            # node_id 在 允许列表中，则打印${value}[data][inputs]和${value}[data][outputs]
#            Run Keyword If    ${is_allowed}
#            ...    Log Inputs and Outputs    ${item}[data][inputs]    ${item}[data][outputs]
#        END
    END




#    FOR    ${key}    IN    @{data.keys()}
#        Log    ${key}
#        ${value}=    Get From Dictionary    ${data}    ${key}
#        Log    ${value}
#        # 判断${value}的event字段是否 = node_finished
#        ${event}=    Get From Dictionary    ${value}    event
#        Log    ${event}
#        ${is_node_finished}=    Run Keyword And Return Status    Should Be Equal    ${event}    node_finished
#        # 的event = node_finished
#        IF    ${is_node_finished}
#            # 获取${value}的data字段
#            ${data}=    Get From Dictionary    ${value}    data
#            Log    ${data}
#            # 获取${data}node_id
#            ${node_id}=    Get From Dictionary    ${data}    node_id
#            Log    ${node_id}
#            # 判断${node_id}是否在允许列表中
#            ${is_allowed}=    Evaluate    "${node_id}" in @{allowed_ids_type_2}
#            # node_id 在 允许列表中，则打印${value}[data][inputs]和${value}[data][outputs]
#            Run Keyword If    ${is_allowed}
#            ...    Log  Inputs and Outputs    ${value}[data][inputs]    ${value}[data][outputs]
#        END
#    END
    # 打开事件流连接
    ${status}=    SSELibrary.Open Event Stream    ${url}
















#
#
#
#
##    ${type}     Evaluate    type(${text_str})
#    # 拆分字符串，用data:分割,用Evaluate方法
#    @{parts}=    Evaluate    r'''${text_str}'''.split('data:')
#    Evaluate    print(@{parts})
#    Log    @{parts}
##    ${res}=    Evaluate    ${text_str}.split('data:')[1]
#    Log    ${res}
#
#
#    # 持续读取事件
#    Log    持续读取事件
#    WHILE    True
#        ${event}=    SSE.Read Sse Events    ${response}
#        Exit For Loop If    not ${event}
#        Log    Received event: ${event}
#    END
#
#
#    ${result}=  Set Variable   ${response.json()}
    RETURN    ${response.json()}

验证并记录结果
    [Arguments]    ${row_num}    ${actual_data}    ${expected_data}
    ${is_match} =    Run Keyword And Return Status
    ...    Dictionaries Should Be Equal    ${actual_data}    ${expected_data}
    ExcelHandler.Write Results    ${row_num}    ${actual_data}    ${is_match}

遍历测试用例
    ExcelHandler.Open Excel    ${EXCEL_PATH}    ${SHEET_NAME}
#    ${total_rows} =    ExcelHandler.Get Row Count
#    FOR    ${row_num}    IN RANGE    2    ${total_rows + 1}
    FOR    ${row_num}    IN RANGE    2    5
        ${input}    ${expected} =    ExcelHandler.Read Row Data    ${row_num}
        Log    ${input}
        Log    ${expected}
        ${input}    Set Variable    {"result":"${input}","type":"2"}
        ${response} =    执行接口请求    ${input}
#        ${response} =    测试SSELibrary事件流    ${input}
        验证并记录结果    ${row_num}    ${response}    ${expected}
    END

*** Test Cases ***
自动化接口测试
    [Tags]    WA
#    ExcelHandler.Open Excel    ${EXCEL_PATH}    ${SHEET_NAME}
#    ExcelHandler.Hello
    遍历测试用例
    # 该测试用例通过模板自动遍历所有数据行


Valid Read Example
    [Tags]    WA
    ExcelHandler.Open Excel    ${EXCEL_PATH}    ${SHEET_NAME}   # 先初始化
    ${row}  Set Variable    2
    ${row} =    Evaluate    int(${row})

    ${value} =    ExcelHandler.Read Row Data    ${row}
    Log    ${value}
    ExcelHandler.Close Excel                             # 最后关闭










