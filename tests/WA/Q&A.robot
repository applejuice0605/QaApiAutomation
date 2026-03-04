*** Settings ***
Library    RequestsLibrary
Library    ExcelHandler.py  WITH NAME    ExcelHandler
Library    Collections
Library    SSELibrary.py    WITH NAME    SSELibrary


Resource    ../../resources/biz/Login/login.robot
Resource    ../WAFLOW/FAPI-001-ask premium-Discount-quotation-demo1.robot




#Suite Setup    初始化测试环境
Suite Teardown  清理测试环境

*** Variables ***
${EXCEL_PATH}      resources/data/general_QA.xlsx
${SHEET_NAME}      Sheet1
${CHAT_FLOW_KEY}   e14294c9-742f-48ff-99ac-527b35b779c2
${API_BASE_URL}    https://rd-dify-sit.fuse.co.id/console/api/apps/
#${authorization}   Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiNTUyYmRiODktNTlkOC00NDExLWJiZmYtMjM3MGQwOWQ4MTljIiwiZXhwIjoxNzUyODMwMDU4LCJpc3MiOiJTRUxGX0hPU1RFRCIsInN1YiI6IkNvbnNvbGUgQVBJIFBhc3Nwb3J0In0.UsB27JkXWCUm8mET2d3uE6gXMujuaoFqg9eMde10i34
${column_input}    1
${column_output}    2
${column_KB_Callback}    3

*** Test Cases ***
自动化接口测试
    初始化测试环境
    遍历测试用例
    # 该测试用例通过模板自动遍历所有数据行


*** Keywords ***
初始化测试环境
    # 获取Dify的token
    ${access_token}=    Login to Dify
    Set Test Variable    ${access_token}
    Log    ${access_token}

    # 打开Excel文件
    ${wb}=   ExcelHandler.Open Excel    ${EXCEL_PATH}    ${SHEET_NAME}
    Set Test Variable    ${wb}

    # 创建API会话
    Create Session    api_session    ${API_BASE_URL}
    Log    初始化测试环境




遍历测试用例
    # 获取Excel总行数
    ${total_rows} =    ExcelHandler.Get Row Count
    # 过滤标题行
    ${total_rows} =    Evaluate    ${total_rows} - 1
    Log    ${total_rows}
    # 遍历每一行数据
#    FOR    ${row_num}    IN RANGE    2    ${total_rows + 1}
    FOR    ${row_num}    IN RANGE    2    3
        ${input}=    ExcelHandler.Get Cell Value    ${row_num}  ${column_input}
        Log    ${input}


        ${response} =    执行接口请求    ${input}
        记录结果    ${row_num}    ${column_output}    ${response}
#        验证并记录结果    ${row_num}    ${response}
    END





记录结果
    [Arguments]     ${row_num}    ${column_output}    ${response}

    # 过滤字典数据，只取event = workflow_finished的数据
    ${answer}=    Evaluate    [d for d in ${response} if d['event'] == 'workflow_finished']
    Log     ${answer}
    Log     ${answer[0]}
    ${answer}=    Set Variable    ${answer[0]}[data][outputs][answer]
    Log     ${answer}
    ExcelHandler.Write Cell Value    ${row_num}    ${column_output}    ${answer}

    # 过滤字典数据，只取 data-》node_id": "1711528915811" / "title": "知识检索"的数据，记录outputs
#    ${filtered_data}=    Evaluate    [d for d in ${response} if d['data']['node_id'] == '1711528915811']
#    Log    ${filtered_data}
#    Log    ${filtered_data[0]}[data][outputs][result]





    FOR    ${item}    IN    @{response}
        # 获取${value}的data字段
        ${data}=    Get From Dictionary    ${item}    data
        Log    ${data}
        # 获取${data}outputs
        ${node_id}=    Get From Dictionary    ${data}    node_id
        Log    ${node_id}

        IF    ${node_id} == 1711528915811
            # 该系节点是政府车辆信息映射
            Log    ${item}[data][outputs]
            # 将outputs转成字符串
            ${outputs}=    Convert To String    ${item}[data][outputs]
            ExcelHandler.Write Cell Value    ${row_num}    ${column_output}    ${outputs}
            BREAK
        END
    END


Log Inputs and Outputs
    [Arguments]    ${inputs}    ${outputs}
    Log    ouput is ${inputs}
    Log    outputs is ${outputs}


清理测试环境
    ExcelHandler.Close Excel
    Delete All Sessions


执行接口请求
    [Arguments]    ${input_data}
    ${url}=   Set Variable     ${API_BASE_URL}${CHAT_FLOW_KEY}/advanced-chat/workflows/draft/run

    # 拼装字符串
    ${prefix}=    Set Variable    Bearer
    ${authorization}=   Catenate    ${prefix}    ${access_token}
    Log     ${authorization}

    ${headers}=    Create Dictionary    authorization=${authorization}  Accept=*/*  Content-Type=application/json
    ${payload}=    Set Variable   {"files":[],"inputs":{},"query":"${input_data}","conversation_id":""}
    Log    ${url}
    Log    ${headers}
    Log    ${payload}
    Create Session    api_session    ${url}
    ${response} =    POST On Session    api_session     url=${url}    headers=${headers}  data=${payload}
    Log    ${response.text}

    ${text_str} =    Evaluate    str(r'''${response.text}''')
    Log    ${text_str}
    # 将字符串中的event: ping: 替换成空字符串
    ${text_str}=    Evaluate    r'''${text_str}'''.replace('event: ping', '')
    # 去掉字符串中的换行符
    ${text_str}=    Evaluate    r'''${text_str}'''.replace('\\n', '')
    # 将字符串中的data: 替换成 ,
    ${new_string}=    Evaluate    r'''${text_str}'''.replace('data: ', ',')
    # 去除字符串开头的,
    ${new_string}=    Evaluate    r'''${new_string}'''.lstrip(',')
    # 在字符串开头和结尾加上[]
    ${new_string}=    Evaluate    r'''[${new_string}]'''
    Log    ${new_string}

    # 1. 处理返回的流式数据
    # 将字符串转换为字典
    ${data}=    Evaluate    json.loads(r'''${new_string}''')
    Log    ${data}

    # 过滤字典数据，只取event = workflow_finished 或 = workflow_finished的数据
    ${filtered_data}=    Evaluate    [d for d in ${data} if d['event'] == 'node_finished' or d['event'] == 'workflow_finished']
    RETURN  ${filtered_data}

验证并记录结果
    [Documentation]    政府车型库
    [Arguments]    ${row_num}    ${actual_data}    ${expected_data}

    # 2025-05-26
    # 1. 验证workflow节点的执行状态 - success
#        -> 并记录，写在对应列-workflow status
    # 2. 验证知识库检索结果的执行状态
#        -> 并记录，写在对应列-knowledge status
    # 3. 记录知识库检索结果的输出
#        写在对应列-knowledge output（知识库检索结果）
    # 4. 记录知识库检索结果的，检索的数据库：ouput->titl
#        写在对应列-knowledge db（检索的知识库）
    # 5. 记录workflow节点的最后输出





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
    FOR    ${item}    IN    @{actual_data}
        # 初始化is_allowed
        ${is_allowed}=    Set Variable    False

        # 获取${value}的data字段
        ${data}=    Get From Dictionary    ${item}    data
        Log    ${data}
        # 获取${data}node_id
        ${node_id}=    Get From Dictionary    ${data}    node_id
        Log    ${node_id}

        IF    ${node_id} == 1745920589742
            # 该系节点是政府车辆信息映射
            Log Inputs and Outputs    ${item}[data][inputs]    ${item}[data][outputs]
            # 判断ouput的数据
            # 1. 判断检索的知识库 与 国家是否一致
            ${is_equal}=    Evaluate    "${item}[data][outputs][0][value]" == "${item}[data][inputs][0][value]"
            # 2. 如果不一致，在acutal_data中添加一条记录，记录不一致的节点
        END

        # 判断${node_id}是否在允许列表中
        ${is_allowed}=    Evaluate    "${node_id}" in @{allowed_ids_type_2}
        # node_id 在 允许列表中，则打印${value}[data][inputs]和${value}[data][outputs]，并判断
        # ${is_allowed}=    Run Keyword And Return Status    Should Be True    ${node_id} in @{allowed_ids_type_2}
        Run Keyword If    ${is_allowed}
        ...    Log Inputs and Outputs    ${item}[data][inputs]    ${item}[data][outputs]

    END

    RETURN    ${response.json()}

















    ${is_match} =    Run Keyword And Return Status
    ...    Dictionaries Should Be Equal    ${actual_data}    ${expected_data}
    ExcelHandler.Write Results    ${row_num}    ${actual_data}    ${is_match}









