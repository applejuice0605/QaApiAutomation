*** Settings ***
Resource    ../../../resources/api/underwriting/underwritingV2_list_manager.robot
Resource    ../../../resources/api/underwriting/assignToMe.robot
Resource    ../../../resources/api/underwriting/underwritingV2_list_todo.robot
Resource    ../../../resources/api/underwriting/approval.robot

Resource    ../../../resources/util/utilCommon.robot

*** Keywords ***
[Order Review Task] Using OrderNo Searching in Mgmt Task List
    [Arguments]    ${bossToken}    ${orderNo}    ${existsAssignee}
    [Documentation]    根据OrderNo 查询Task-Mgmt - Underwriting Mgmt Task List, 找不到指定的taskId则重试
    # 将“发请求”和“校验逻辑”打包在一起进行 5 次重试
    Wait Until Keyword Succeeds    5x    5s    Get And Verify Task Id    bossToken=${bossToken}    orderNo=${orderNo}    existsAssignee=${existsAssignee}    method_type=Order_Review_Mgmt_Task_List
    # 重试成功后，taskId 已经在校验关键字里被 Set Test Variable 了，可以直接返回
    RETURN    ${taskResult}

[toOffline Review Task] Using OrderNo Searching in Mgmt Task List
    [Arguments]    ${bossToken}    ${orderNo}    ${existsAssignee}
    [Documentation]    根据OrderNo 查询Task-Mgmt - Underwriting Mgmt Task List, 找不到指定的taskId则重试
    # 将“发请求”和“校验逻辑”打包在一起进行 5 次重试
    Wait Until Keyword Succeeds    5x    5s    Get And Verify Task Id    bossToken=${bossToken}    orderNo=${orderNo}    existsAssignee=${existsAssignee}    method_type=ToOffline_Task_Mgmt_Task_List
    # 重试成功后，taskId 已经在校验关键字里被 Set Test Variable 了，可以直接返回
    RETURN    ${taskResult}


Using OrderNo Searching in Todo Task List
    [Arguments]    ${bossToken}    ${orderNo}    ${existsAssignee}=${None}
    [Documentation]    根据OrderNo 查询Task - Underwriting Todo Task List, 找不到指定的taskId则重试
    # 将“发请求”和“校验逻辑”打包在一起进行 5 次重试
    Wait Until Keyword Succeeds    5x    5s    Get And Verify Task Id    bossToken=${bossToken}    orderNo=${orderNo}    existsAssignee=${existsAssignee}    method_type=Underwriting_Task_List
    # 重试成功后，taskId 已经在校验关键字里被 Set Test Variable 了，可以直接返回
    RETURN    ${taskResult}


Get And Verify Task Id
    [Documentation]    这是一个内部辅助关键字，用来把两个步骤连起来: 1. 查询列表；2. 判断是否有指定的taskId
    [Arguments]     ${method_type}    ${bossToken}    ${orderNo}    ${existsAssignee}
    # 1. 发起请求
    IF    '${method_type}' == 'Order_Review_Mgmt_Task_List'
        ${response}=    [Order Review Task] I send request to underwritingV2/list/manager API    ${bossToken}    ${orderNo}    ${existsAssignee}
    ELSE IF    '${method_type}' == 'ToOffline_Task_Mgmt_Task_List'
        ${response}=    [toOffline Task] I send request to underwritingV2/list/manager API    ${bossToken}    ${orderNo}    ${existsAssignee}
    ELSE IF    '${method_type}' == 'Underwriting_Task_List'
        ${response}=    I send request to underwritingV2/list/todo API    ${bossToken}    ${orderNo}
    ELSE
        Log    ${method_type} is not supported
    END
    ${json}=    Set Variable    ${response.json()} 
    # 2. 调用装好的校验逻辑
    # 如果该关键字内部的 Should Be Equal 失败，Wait Until... 就会捕获并触发下一次重试
    the response should contain taskIds    ${json}



[Order Review Task] I send request to underwritingV2/list/manager API
    [Arguments]    ${bossToken}    ${orderNo}   ${existsAssignee}
    Sleep    10s
    ${response}    underwritingV2_list_manager.Send Request And Get Response Data    ${bossToken}    ${orderNo}     existsAssignee=${existsAssignee}
    RETURN    ${response}


[toOffline Task] I send request to underwritingV2/list/manager API
    [Arguments]    ${bossToken}    ${orderNo}   ${existsAssignee}
    Sleep    10s
    ${response}    underwritingV2_list_manager.Send Request And Get Response Data    ${bossToken}    ${orderNo}     existsAssignee=${existsAssignee}
    RETURN    ${response}




I send request to underwritingV2/list/todo API
    [Arguments]    ${bossToken}    ${orderNo}
    Sleep    10s
    ${response}    underwritingV2_list_todo.Send Request And Get Response Data    ${bossToken}    ${orderNo}
    RETURN    ${response}




[Order Review Task] I send request to approve API
    [Arguments]    ${bossToken}    ${taskResult}   ${AP_POSITIVE_DATA}
    #1. 获取当前任务对应的jsonBody
    ${jsonBody}    Set Variable   ${AP_POSITIVE_DATA["underwriting_OrderReviewTask_Approve_toOffline"]}
    
    #2. 依次处理每个任务
    # ${total}  Set Variable    ${jsonResult}[data][total]
    FOR    ${item}    IN    @{taskResult}
        Log    ${item}
        #2.1. 从taskResult中获取task信息：任务id 和 orderId
        ${taskId}    Get From Dictionary    ${item}    taskId
        ${orderId}    Get From Dictionary    ${item}    orderId
        ${slipUid}    Get From Dictionary    ${item}    slipUid

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
    [Arguments]    ${bossToken}     ${taskResult}    ${AP_POSITIVE_DATA}
    #1. 获取当前任务对应的jsonBody
    ${jsonBody}    Set Variable   ${AP_POSITIVE_DATA["underwriting_toOfflineTask_Approve"]}
    
    Log    ${taskResult}
    #2. 依次处理每个任务
    FOR    ${item}    IN    @{taskResult}
        Log    ${item}
        #2.1. 从taskResult中获取task信息：任务id 和 orderId
        ${taskId}    Get From Dictionary    ${item}    taskId
        ${orderId}    Get From Dictionary    ${item}    orderId
        ${policyNumber}    Get From Dictionary    ${item}    slipUid
        ${startTime}     Get From Dictionary    ${item}    startTime
        ${endTime}     Get From Dictionary    ${item}    endTime
        ${underwritingInsuranceTime}=    Get Effective Time

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


I send request to approve API to decline toOffline task
    [Arguments]    ${bossToken}    ${taskResult}   ${AP_POSITIVE_DATA}
    #1. 获取当前任务对应的jsonBody
    ${jsonBody}    Set Variable   ${AP_POSITIVE_DATA["decline"]}

    #2. 依次处理每个任务
    FOR    ${item}    IN    @{taskResult}
        Log    ${item}
        #2.1. 从taskResult中获取task信息：任务id 和 orderId
        ${taskId}    Get From Dictionary    ${item}    taskId
        ${orderId}    Get From Dictionary    ${item}    orderId

        #2.2. update jsonBody
        ${jsonBody}=    Update Value To Json    ${jsonBody}    $.data.orderId    ${orderId}
        ${jsonBody}=    Update Value To Json    ${jsonBody}    $.taskId    ${taskId}

        #3. convert jsonBody to string
        ${strBody}  Convert Json To String    ${jsonBody}

        #4. send request and get response data
        ${response}    approval.Send Request And Get Response Data    ${bossToken}    ${strBody}

        #5. check response
        Should Be True    ${response.json()}[code] == 200

        Exit For Loop If    ${response.json()}[code] == 200
    END





the response should contain taskIds
    [Documentation]    校验响应中是否包含taskIds, 并提取taskIds、orderIds、slipUids返回
    [Arguments]     ${jsonResult}
    ${total}  Set Variable    ${jsonResult}[data][total]
    Should Be True    ${total} > 0
    Log     ${jsonResult}[data][data][0][id]
    Should Not Be Empty    ${jsonResult}[data][data][0][id]

    # 提取taskId、orderIds、slipUids并返回
    ${taskResult}  Create List
    FOR    ${counter}    IN RANGE    0    ${total}
        Log    ${counter}
        ${result}  Create Dictionary
        ${taskId}    Get From Dictionary    ${jsonResult}[data][data][${counter}]    id
        ${orderId}    Get From Dictionary    ${jsonResult}[data][data][${counter}]    orderId
        ${slipUid}    Get From Dictionary    ${jsonResult}[data][data][${counter}]    slipId
        ${startTime}     Get From Dictionary    ${jsonResult}[data][data][${counter}]    startTime    default=${None}
        ${endTime}     Get From Dictionary    ${jsonResult}[data][data][${counter}]    endTime    default=${None}

        Set To Dictionary    ${result}    taskId=${taskId}    orderId=${orderId}    slipUid=${slipUid}    startTime=${startTime}    endTime=${endTime}

        Log    ${result}
        Append To List    ${taskResult}    ${result}
    END
    Log     ${taskResult}
    Set Test Variable    ${taskResult}
    RETURN    ${taskResult}



I send request to assigneToMe API
    [Arguments]     ${taskResult}   ${bossToken}
    # 从taskResult中提取taskIds
    ${taskIds}  Create List
    FOR    ${item}    IN    @{taskResult}
        ${taskId}    Get From Dictionary    ${item}    taskId
        Append To List    ${taskIds}    ${taskId}
    END
    Log     ${taskIds}

    ${response}    assignToMe.Send Request And Get Response Data    ${bossToken}    ${taskIds}
    Set Test Variable    ${jsonResult}    ${response.json()}






