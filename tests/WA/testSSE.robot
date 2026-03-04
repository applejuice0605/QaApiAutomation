*** Settings ***
Library    SSECustom.py    WITH NAME    SSE

*** Test Cases ***
测试 SSE 事件流
    ${sse}=    Open SSE Stream    http://api.example.com/events
    ${events}=    Read SSE Events    ${sse}    max_events=3
    Should Not Be Empty    ${events}
    FOR    ${event}    IN    @{events}
        Log    收到事件：${event}
    END