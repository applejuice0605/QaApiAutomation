
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

