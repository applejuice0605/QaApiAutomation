*** Settings ***
Library    Collections


*** Keywords ***
The status code should be 200
    [Arguments]    ${code}
    Should Be Equal As Numbers   ${code}    200

The response message should be Success
    [Arguments]     ${jsonResult}
    Should Be Equal As Strings    ${jsonResult}[message]    SUCCESS

The response data should not be null
    [Arguments]     ${jsonResult}
    Should Not Be Empty    ${jsonResult}[data]

The response data total should be greater than 0
    [Arguments]     ${jsonResult}
    Should Be True    ${jsonResult}[data][total] > 0

The response data should contain the keyword ${keyword}
    [Arguments]     ${jsonResult}    ${keyword}
    Should Contain    ${jsonResult}[data][list]    ${keyword}


Finally Log the orderNo
    [Arguments]    ${orderNo}
    Log    ${orderNo}

The response should contain the value quoteNo and rfqNo
    [Arguments]    ${jsonResult}
    Should Contain    ${jsonResult}[data]   rfqNo
    Should Contain    ${jsonResult}[data]   quoteNo
    Set Test Variable    ${rfqNo}    ${jsonResult}[data][rfqNo]
    Set Test Variable    ${quoteNo}    ${jsonResult}[data][quoteNo]


The response should contain the value orderNo and orderId
    [Arguments]    ${jsonResult}
    Should Contain    ${jsonResult}[data]   orderNo
    Should Contain    ${jsonResult}[data]   orderIdLs
    Set Test Variable    ${orderNo}    ${jsonResult}[data][orderNo]
    ${orderIds}  Create List    ${jsonResult}[data][orderIdLs]
    ${orderId}  Get From List    ${jsonResult}[data][orderIdLs]    0
    Set Test Variable    ${orderId}



