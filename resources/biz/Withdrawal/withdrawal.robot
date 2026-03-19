*** Settings ***
Resource    ../../../resources/api/Withdrawal/withdrawal_v2.robot
Resource    ../../../resources/api/underwriting/assignToMe.robot

Resource    ../../../resources/util/utilCommon.robot

*** Keywords ***
Get Valid Bank Card
    [Documentation]    查询银行卡数据，返回第一个有效银行卡
    [Arguments]    ${fusetoken}
    ${response}=    Get Bank Account List    ${fusetoken}
    ${data}=    Get From Dictionary    ${response.json()}    data

    ${bankName}=    Set Variable    ${None}
    ${bankUid}=    Set Variable    ${None}
    ${bankAccountNumber}=    Set Variable    ${None}

    FOR    ${index}    ${element}    IN ENUMERATE    @{data}
        Log    ${index}: ${element}
        ${status}=    Get From Dictionary    ${element}    referenceStatus
        ${bankName}=    Get From Dictionary    ${element}    bankName
        ${bankUid}=    Get From Dictionary    ${element}    bankUid
        ${bankAccountNumber}=    Get From Dictionary    ${element}    bankAccountNumber

        ${is_valid}=    Evaluate    ${status} == 4

        Exit For Loop If    ${is_valid}
    END
    IF    ${is_valid}
        RETURN    ${bankAccountNumber}    ${bankUid}    ${bankName}
    ELSE
        Fail    没有有效银行卡
    END

Check Balance Is Enough
    [Documentation]    检查余额是否足够提现
    [Arguments]    ${fusetoken}    ${withdrawAmount}
    ${response}=    Get Account Balance    ${fusetoken}
    ${data}=    Get From Dictionary    ${response.json()}    data
    ${balance}=    Get From Dictionary    ${data}    bonus
    ${withdrawAmount}=    Convert To Number    ${withdrawAmount}
    ${is_enough}=    Evaluate    ${balance} >= ${withdrawAmount}

    Should Be True    ${is_enough}

Send Auto Withdrawal Post Request
    [Documentation]    发送自动提现申请
    [Arguments]    ${fusetoken}    ${bankAccountNumber}    ${bankUid}    ${bankName}    ${withdrawAmount}
    ${response}=    Send Withdrawal Request And Get Response Data    ${fusetoken}    ${bankAccountNumber}    ${bankUid}    ${bankName}    ${withdrawAmount}
    ${jsonResult}=    Set Variable    ${response.json()}
    RETURN    ${jsonResult}

the response should exceeded-limit prompt and prompt use manual withdrawal
    [Arguments]    ${jsonResult}
    ${message}=    Set Variable    ${jsonResult}[data][message]
    Should Be Equal    ${message}    You have exceeded daily instant withdrawal limit, you can only proceed the withdrawal by using manual disbursement. This process will take two working days maximum.
    

Send Manual Withdrawal Post Request
    [Documentation]    发送手动提现申请
    [Arguments]    ${fusetoken}   ${bankCardNo}    ${bankUid}    ${bankName}    ${withdrawAmount}
    ${response}=    Send Withdrawal Request And Get Response Data    ${fusetoken}    ${bankCardNo}    ${bankUid}    ${bankName}    ${withdrawAmount}    manuallyWithdraw=true 
    ${jsonResult}=    Set Variable    ${response.json()}
    RETURN    ${jsonResult}


The response should contain the withdrawalId
    [Arguments]    ${jsonResult}
    ${data}=    Get From Dictionary    ${jsonResult}    data
    ${withdrawalId}=    Get From Dictionary    ${data}    withdrawalId
    Should Not Be Empty    ${withdrawalId}
    Set Test Variable    ${withdrawalId}    ${withdrawalId}

Check Bonus History List should contain Withdrawal Id And Correct Amount and status
    [Documentation]    检查提现流水列表是否包含指定的提现Id，且金额是否与提现的金额相等、状态是否正确
    [Arguments]    ${fusetoken}    ${withdrawalId}    ${withdrawalAmount}    ${is_Increase}
    ${response}=    Get Withdrawal History List    ${fusetoken}
    ${jsonResult}=    Set Variable    ${response.json()}
    
    ${withdrawalId_history_list}=    Get From Dictionary    ${jsonResult}[data]    data
    ${withdrawalId_in_list}=    Set Variable    ${None}
    ${withdrawalAmount_in_list}=    Set Variable    ${None}
    ${withdrawStatus}=    Set Variable    ${None}
    ${withdrawal_type}=    Set Variable    ${None}
    FOR    ${index}    ${element}    IN ENUMERATE    @{withdrawalId_history_list}
        Log    ${index}: ${element}
        ${withdrawalId_in_list}=    Get From Dictionary    ${element}    withdrawId
        ${withdrawalAmount_in_list}=    Get From Dictionary    ${element}    withdrawAmount
        # 转换成整型
        ${withdrawalAmount_in_list}=    Evaluate    str(int(${withdrawalAmount_in_list}))
        ${withdrawStatus}=    Get From Dictionary    ${element}    withdrawStatus
        Exit For Loop If    '${withdrawalId_in_list}'=='${withdrawalId}'
    END

    Should Be Equal    ${withdrawalId_in_list}    ${withdrawalId}
    Should Be Equal    ${withdrawalAmount_in_list}    ${withdrawalAmount}
    # 判断提现类型
    # 如果提现状态 = 5 /6 /99, is_add = true, 否则为false
    IF    ${withdrawStatus} in [5,6,99]
        Set Test Variable    ${is_add}    True
    ELSE
        Set Test Variable    ${is_add}    False
    END
    # is_add应等于false
    Should be equal    ${is_add}    ${is_Increase}

Get And Verify Task Id
    [Documentation]    这是一个内部辅助关键字，用来把两个步骤连起来: 1. 查询列表；2. 判断是否有指定的taskId
    [Arguments]    ${bossToken}    ${withdrawalId}    ${method_type}
    # 1. 发起请求
    IF    '${method_type}' == 'Task_Mgmt_Verify'
        ${response}=    [Task Mgmt] Get Withdrawal Verification Task Mgmt List    ${bossToken}    ${withdrawalId}
    ELSE IF    '${method_type}' == 'Task_Verify'
        ${response}=    [Task] Get Withdrawal Verification Task List    ${bossToken}    ${withdrawalId}
    ELSE IF    '${method_type}' == 'Task_Mgmt_Payment'
        ${response}=    [Task Mgmt] Get Withdrawal Payment Task Mgmt List    ${bossToken}    ${withdrawalId}
    ELSE IF    '${method_type}' == 'Task_Payment'
        ${response}=    [Task] Get Withdrawal Payment Task List    ${bossToken}    ${withdrawalId}
    ELSE
        Log    ${method_type} is not supported
    END
    ${json}=    Set Variable    ${response.json()} 
    # 2. 调用装好的校验逻辑
    # 如果该关键字内部的 Should Be Equal 失败，Wait Until... 就会捕获并触发下一次重试
    The response of task list should contain the taskId    ${json}    ${withdrawalId}

[Task Mgmt] Use withdrawalId Searching in Withdrawal Verification Task Mgmt List and Get taskId
    [Documentation]    根据withdrawalId 查询Task-Mgmt - Withdrawal Verification Task List, 找不到指定的taskId则重试
    [Arguments]    ${bossToken}    ${withdrawalId}
    # 将“发请求”和“校验逻辑”打包在一起进行 5 次重试
    Wait Until Keyword Succeeds    5x    5s    Get And Verify Task Id    ${bossToken}    ${withdrawalId}    method_type=Task_Mgmt_Verify
    # 重试成功后，taskId 已经在校验关键字里被 Set Test Variable 了，可以直接返回
    RETURN    ${taskId}



The response of task list should contain the taskId
    [Arguments]    ${jsonResult}    ${withdrawalId}
    ${taskList}=    Set Variable    ${jsonResult['data']['data']}
    ${withdrawalId_in_taskList}=    Set Variable    ${None}
    FOR    ${index}    ${element}    IN ENUMERATE    @{taskList}
        Log    ${index}: ${element}
        ${withdrawalId_in_taskList}=    Get From Dictionary    ${element}    withdrawId
        ${taskId}=    Get From Dictionary    ${element}    id
        Exit For Loop If    '${withdrawalId_in_taskList}'=='${withdrawalId}'
    END
    Should Be Equal    ${withdrawalId_in_taskList}    ${withdrawalId}
    Set Test Variable    ${taskId}    ${taskId}

[Task] Use withdrawalId Searching in Withdrawal Verification Task List and Get taskId
    [Documentation]    根据withdrawalId 查询Task - Withdrawal Verification Task List, 找不到指定的taskId则重试
    [Arguments]    ${bossToken}    ${withdrawalId}
    # 将“发请求”和“校验逻辑”打包在一起进行 5 次重试
    Wait Until Keyword Succeeds    5x    5s    Get And Verify Task Id    ${bossToken}    ${withdrawalId}    method_type=Task_Verify
    # 重试成功后，taskId 已经在校验关键字里被 Set Test Variable 了，可以直接返回
    RETURN    ${taskId}

[Withdrawal Verification] Approve Withdrawal Verification Task
    [Arguments]    ${bossToken}    ${withdrawalId}    ${taskId}
    #1. 获取当前任务对应的jsonBody
    ${response}=    Approve Withdrawal Task    ${bossToken}    ${withdrawalId}    ${taskId}
    ${jsonResult}=    Set Variable    ${response.json()}
    Set Test Variable    ${jsonResult}    ${response.json()}



Assign the Task To Me
    [Arguments]     ${bossToken}    ${taskId}
    # 将taskId变成列表
    ${taskIds}=    Create List    ${taskId}
    ${response}    assignToMe.Send Request And Get Response Data    ${bossToken}    ${taskIds}
    Set Test Variable    ${jsonResult}    ${response.json()}


[Task Mgmt] Use withdrawalId Searching in Withdrawal Payment Task Mgmt List and Get taskId
    [Documentation]    根据withdrawalId 查询Task-Mgmt - Withdrawal Payment Task List, 找不到指定的taskId则重试
    [Arguments]    ${bossToken}    ${withdrawalId}
    # 将“发请求”和“校验逻辑”打包在一起进行 5 次重试
    Wait Until Keyword Succeeds    5x    5s    Get And Verify Task Id    ${bossToken}    ${withdrawalId}    method_type=Task_Mgmt_Payment
    # 重试成功后，taskId 已经在校验关键字里被 Set Test Variable 了，可以直接返回
    RETURN    ${taskId}


[Task] Use withdrawalId Searching in Withdrawal Payment Task List and Get taskId
    [Documentation]    根据withdrawalId 查询Task - Withdrawal Payment Task List, 找不到指定的taskId则重试
    [Arguments]    ${bossToken}    ${withdrawalId}
    # 将“发请求”和“校验逻辑”打包在一起进行 5 次重试
    Wait Until Keyword Succeeds    5x    5s    Get And Verify Task Id    ${bossToken}    ${withdrawalId}    method_type=Task_Payment
    # 重试成功后，taskId 已经在校验关键字里被 Set Test Variable 了，可以直接返回
    RETURN    ${taskId}

[Withdrawal Payment] Approve Withdrawal Payment Task
    [Documentation]    审批打款任务
    [Arguments]    ${bossToken}    ${withdrawalId}    ${taskId}
    #1. 获取当前任务对应的jsonBody
    ${response}=    [Withdrawal Payment] Approve Withdrawal Task    ${bossToken}    ${withdrawalId}    ${taskId}
    Set Test Variable    ${jsonResult}    ${response.json()}

Decline Withdrawal Payment Task
    [Documentation]    拒绝打款任务
    [Arguments]    ${bossToken}    ${withdrawalId}    ${taskId}
    #1. 获取当前任务对应的jsonBody
    ${response}=    Decline Withdrawal Task    ${bossToken}    ${withdrawalId}    ${taskId}
    Set Test Variable    ${jsonResult}    ${response.json()}

