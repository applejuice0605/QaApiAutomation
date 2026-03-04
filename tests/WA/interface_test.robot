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
${authorization}   Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiNTUyYmRiODktNTlkOC00NDExLWJiZmYtMjM3MGQwOWQ4MTljIiwiZXhwIjoxNzQ3ODc2ODI3LCJpc3MiOiJTRUxGX0hPU1RFRCIsInN1YiI6IkNvbnNvbGUgQVBJIFBhc3Nwb3J0In0.CgLrJMKbL9g2bR1E_sESPZbsi_2DiNUWHhmBae67IQ4
#${cookies}    {"_ga": "GA1.1.880719924.1688297494", "_ga_3JZJ9RJG7D": "GS1.1.1688297494.1.1.1688297494.0.0.0", "_ga_3JZJ9RJG
${payload}    {"inputs":{"result":"TOYOTA,AVANZA 1.3 E M/T (F653RM-GMDFJ),2019","type":"2"},"files":[]}

*** Keywords ***
初始化测试环境
#    ExcelHandler.Open Excel    ${EXCEL_PATH}    ${SHEET_NAME}
#    Create Session    api_session    ${API_BASE_URL}
    Log    初始化测试环境

清理测试环境
    ExcelHandler.Close Excel
    Delete All Sessions

测试SSELibrary事件流
    [Arguments]    ${input_data}
    ${url}=   Set Variable     ${API_BASE_URL}${CHAT_FLOW_KEY}/workflows/draft/run
    ${headers}=    Create Dictionary    authorization=${authorization}  Accept=*/*  Content-Type=application/json
    ${payload}=    Set Variable   {"inputs":${input_data}, "files":[]}
    Log    ${url}
    Log    ${headers}
    Log    ${payload}
    # 打开事件流连接
    ${status}=    SSELibrary.Open Event Stream    ${url}    headers=${headers}
    # 读取事件
    ${events}=    SSELibrary.Read Events    max_events=20    timeout=10
    Should Not Be Empty    ${events}
    Log    ${events}
#    FOR    ${event}    IN    @{events}
#        验证事件格式    ${event}
#    END




测试 SSE 事件流
    [Arguments]    ${input_data}
    ${url}=   Set Variable     ${API_BASE_URL}${CHAT_FLOW_KEY}/workflows/draft/run
    ${headers}=    Create Dictionary    authorization=${authorization}  Accept=*/*  Content-Type=application/json
    ${payload}=    Set Variable   {"inputs":${input_data}, "files":[]}
    Log    ${url}
    Log    ${headers}
    Log    ${payload}
    Create Session    api_session    ${url}
    ${response} =    POST On Session    api_session     url=${url}    headers=${headers}  data=${payload}

    ${sse}=    Open SSE Stream    http://api.example.com/events
    ${events}=    Read SSE Events    ${sse}    max_events=3
    Should Not Be Empty    ${events}
    FOR    ${event}    IN    @{events}
        Log    收到事件：${event}
    END


    # 持续读取事件
    Log    持续读取事件
    WHILE    True
        ${event}=    SSE.Read Sse Events    ${response}
        Exit For Loop If    not ${event}
        Log    Received event: ${event}
    END





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
    # 持续读取事件
    Log    持续读取事件
    WHILE    True
        ${event}=    SSE.Read Sse Events    ${response}
        Exit For Loop If    not ${event}
        Log    Received event: ${event}
    END


    ${result}=  Set Variable   ${response.json()}
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
#        ${response} =    执行接口请求    ${input}
        ${response} =    测试SSELibrary事件流    ${input}
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










