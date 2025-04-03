*** Settings ***
Resource    ../../../resources/api/Withdrawal/account_flow_list_v2.robot

Resource    ../../../resources/util/utilCommon.robot

*** Keywords ***
Check Earning History
    [Arguments]    ${token}
    ${response}    account_flow_list_v2.Send Request And Get Response Data    ${token}
    Set Test Variable    ${jsonResult}    ${response.json()}
    Log    ${jsonResult}

#the response should contain the slipId=${slipId} and tradeAmount=${tradeAmount}
#    [Arguments]    ${jsonResult}

Check Partner Pay Full Payment Order's Commission Disbursed
    [Arguments]    ${token}     ${slipId}   ${expectedData}
    ${response}    account_flow_list_v2.Send Request And Get Response Data    ${token}
    ${data}     Set Variable    ${response.json()}[data][data]

    &{actualData}=    Create Dictionary
    Log    ${data}
    FOR    ${item}    IN    ${data}
        Log    ${item}
        IF    ${item}[slipId] == ${slipId}
            Set To Dictionary    &{actualData}    controlAccount=${item}[controlAccount]    transactionName=${item}[transactionName]
        END
    END
    Log    message

Check Commission Disbursed
    [Arguments]    ${token}     ${slipIds}   ${expected_data_count}
    Log    ${token}
    Sleep    15s
    ${response}    account_flow_list_v2.Send Request And Get Response Data    ${token}
    ${resultdata}     Set Variable    ${response.json()}[data][data]

    Log    ${slipIds}
    ${count}    Get Length    ${slipIds}

    FOR    ${i}    IN RANGE    0    ${count}
        Log    ${slipIds}[${i}]
        ${slipId}   Set Variable    ${slipIds}[${i}]
#    END
#    FOR    ${slipId}    IN   ${slipIds}
        Log    ${slipId}
        ${data}     Evaluate    list(filter(lambda item: item['bizId'] == '${slipId}', ${resultdata}))
        Log    ${data}
        ${len}      Evaluate     len(${data})
        Log    ${len}
        Should Be True    ${len} == ${expected_data_count}
    END




