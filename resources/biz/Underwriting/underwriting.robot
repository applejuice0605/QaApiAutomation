*** Settings ***
Resource    ../../../resources/api/underwriting/underwritingV2_list_manager.robot
Resource    ../../../resources/api/underwriting/assignToMe.robot
Resource    ../../../resources/api/underwriting/underwritingV2_list_todo.robot
Resource    ../../../resources/api/underwriting/approval.robot

Resource    ../../../resources/util/utilCommon.robot

*** Keywords ***

[Order Review Task] I send request to underwritingV2/list/manager API
    [Arguments]    ${bossToken}    ${orderNo}   ${existsAssignee}
    ${response}    underwritingV2_list_manager.Send Request And Get Response Data    ${bossToken}    ${orderNo}     existsAssignee=${existsAssignee}

    Set Test Variable    ${jsonResult}    ${response.json()}
    Log    ${jsonResult}


[toOffline Task] I send request to underwritingV2/list/manager API
    [Arguments]    ${bossToken}    ${orderNo}   ${existsAssignee}
    Sleep    10s
    ${response}    underwritingV2_list_manager.Send Request And Get Response Data    ${bossToken}    ${orderNo}     existsAssignee=${existsAssignee}

    Set Test Variable    ${jsonResult}    ${response.json()}
    Log    ${jsonResult}




I send request to underwritingV2/list/todo API
    [Arguments]    ${bossToken}    ${orderNo}
    Sleep    10s
    ${response}    underwritingV2_list_todo.Send Request And Get Response Data    ${bossToken}    ${orderNo}
    Set Test Variable    ${jsonResult}    ${response.json()}
    Log    ${jsonResult}




[Order Review Task] I send request to approve API
    [Arguments]    ${bossToken}    ${orderNo}   ${AP_POSITIVE_DATA}
    #1. 获取当前任务对应的jsonBody
    ${jsonBody}    Set Variable   ${AP_POSITIVE_DATA["underwriting_OrderReviewTask_Approve_toOffline"]}

    #2. 依次处理每个任务
    ${total}  Set Variable    ${jsonResult}[data][total]
    FOR    ${counter}    IN RANGE    0    ${total}
        Log    ${counter}
        #2.1. 从manager接口获取task信息：任务id...
        ${taskId}    Get From Dictionary    ${jsonResult}[data][data][${counter}]    id

        #2.2. update jsonBody
        ${jsonBody}=    Update Value To Json    ${jsonBody}    $.data.orderId    ${orderId}
        ${jsonBody}=    Update Value To Json    ${jsonBody}    $.taskId    ${taskId}

        #3. convert jsonBody to string
        ${strBody}  Convert Json To String    ${jsonBody}

        #4. send request and get response data
        ${response}    approval.Send Request And Get Response Data    ${bossToken}    ${strBody}

        #5. check response
        Should Be True    ${response.json()}[code] == 200
    END

[toOffline Task] I send request to approve API to approve toOffline task
    [Arguments]    ${bossToken}    ${orderNo}   ${AP_POSITIVE_DATA}
    #1. 获取当前任务对应的jsonBody
    ${jsonBody}    Set Variable   ${AP_POSITIVE_DATA["underwriting_toOfflineTask_Approve"]}

    #2. 依次处理每个任务
    ${total}  Set Variable    ${jsonResult}[data][total]
    FOR    ${counter}    IN RANGE    0    ${total}
        Log    ${counter}
        ${taskId}    Get From Dictionary    ${jsonResult}[data][data][${counter}]    id
        ${startTime}     Get From Dictionary    ${jsonResult}[data][data][${counter}]    startTime
        ${endTime}     Get From Dictionary    ${jsonResult}[data][data][${counter}]    endTime
        ${underwritingInsuranceTime}=    Get Effective Time
        ${policyNumber}    Get From Dictionary    ${jsonResult}[data][data][${counter}]    slipId

        #2.1. update jsonBody
        ${jsonBody}=    Update Value To Json    ${jsonBody}    $.data.orderId    ${orderId}
        ${jsonBody}=    Update Value To Json    ${jsonBody}    $.taskId    ${taskId}
        ${jsonBody}=    Update Value To Json    ${jsonBody}    $.data.startTime    ${startTime}000
        ${jsonBody}=    Update Value To Json    ${jsonBody}    $.data.endTime    ${endTime}000
        ${jsonBody}=    Update Value To Json    ${jsonBody}    $.data.underwritingInsuranceTime    ${underwritingInsuranceTime}
        ${jsonBody}=    Update Value To Json    ${jsonBody}    $.data.policyNumber    ${policyNumber}

        #3. convert jsonBody to string
        ${strBody}  Convert Json To String    ${jsonBody}

        #4. send request and get response data
        ${response}    approval.Send Request And Get Response Data    ${bossToken}    ${strBody}

        #5. check response
        Should Be True    ${response.json()}[code] == 200
    END


[toOffline Task] I send request to approve API to decline toOffline task
    [Arguments]    ${bossToken}    ${orderNo}   ${AP_POSITIVE_DATA}
    #1. 获取当前任务对应的jsonBody
    ${jsonBody}    Set Variable   ${AP_POSITIVE_DATA["decline"]}

    #2. update jsonBody
    ${taskId}    Get From Dictionary    ${jsonResult}[data][data][0]    id


    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.data.orderId    ${orderId}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.taskId    ${taskId}

    #3. convert jsonBody to string
    ${strBody}  Convert Json To String    ${jsonBody}

    #4. send request and get response data
    ${response}    approval.Send Request And Get Response Data    ${bossToken}    ${strBody}

    #5. check response
    Should Be True    ${response.json()}[code] == 200





the response should contain taskId
    [Arguments]     ${jsonResult}
    ${total}  Set Variable    ${jsonResult}[data][total]
    Should Be True    ${total} > 0
    Log     ${jsonResult}[data][data][0][id]
    Should Not Be Empty    ${jsonResult}[data][data][0][id]



I send request to assigneToMe API
    [Arguments]     ${jsonResult}   ${bossToken}
    Log    ${jsonResult}
    ${total}    Set Variable    ${jsonResult}[data][total]
    ${taskIds}  Create List
    FOR    ${counter}    IN RANGE    0    ${total}
        Log    ${counter}
        ${taskId}    Get From Dictionary    ${jsonResult}[data][data][${counter}]    id
        Append To List    ${taskIds}    ${taskId}
    END
    Log     ${taskIds}

    ${response}    assignToMe.Send Request And Get Response Data    ${bossToken}    ${taskIds}
    Set Test Variable    ${jsonResult}    ${response.json()}






