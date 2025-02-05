*** Settings ***
Resource    ../../../resources/api/ManualAdjustment/trading_manager_add.robot
Resource    ../../../resources/api/ManualAdjustment/trading_manager_preAdd.robot
Resource    ../../../resources/api/ManualAdjustment/trading_manager_list.robot
Resource    ../../../resources/api/ManualAdjustment/ticketItem_bpm_manager.robot
Resource    ../../../resources/api/ManualAdjustment/adjustment_review_list_todo.robot
Resource    ../../../resources/api/ManualAdjustment/adjustment_approval.robot

Resource    ../../../resources/api/underwriting/assignToMe.robot
Resource    ../../../resources/api/underwriting/approval.robot

Resource    ../../../resources/util/utilCommon.robot

*** Keywords ***
Deal with json body for add manual adjustment
    [Arguments]    ${AP_POSITIVE_DATA}  ${bossToken}     ${transactionAmount}   ${totalAmount}  ${calculateTaxType}    ${flowType}     ${transactionType}   ${incomeTax}=0
    # 1. 获取add manual adjustment request的jsonBody
    ${jsonBody}     Set Variable    ${AP_POSITIVE_DATA["add_ManualAdjustment"]}
    # 2. updateJsonBody
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.transactionAmount    ${transactionAmount}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.calculateTaxType    ${calculateTaxType}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.incomeTax    ${incomeTax}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.totalAmount    ${totalAmount}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.flowType    ${flowType}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.transactionType    ${transactionType}
    IF    "${transactionType}" == "policyBonus"
         ${jsonBody}=    Update Value To Json    ${jsonBody}    $.walletAccount    partnerCommission
    ELSE IF    "${transactionType}" == "policyPoint"
         ${jsonBody}=    Update Value To Json    ${jsonBody}    $.walletAccount    partnerSpecialBonus
    END
    Log     ${jsonBody}
    # 3. convert jsonBody to string
    ${strBody}  Convert Json To String    ${jsonBody}

    RETURN    ${strBody}



Submit Manual Adjustment Requeqst without Tax
    [Arguments]     ${AP_POSITIVE_DATA}    ${bossToken}     ${transactionAmount}    ${flowType}     ${transactionType}
    ${strBody}=    Deal with json body for add manual adjustment   ${AP_POSITIVE_DATA}  ${bossToken}     ${transactionAmount}   ${transactionAmount}  flowType=${flowType}  calculateTaxType=0  transactionType=${transactionType}
    # send request
    ${response}    trading_manager_add.Send Request And Get Response Data    ${bossToken}    ${strBody}
    Set Test Variable    ${jsonResult}     ${response.json()}
    Log    ${jsonResult}


Submit Manual Adjustment Requeqst with Tax
    [Arguments]     ${AP_POSITIVE_DATA}    ${bossToken}     ${transactionAmount}    ${flowType}     ${transactionType}
    ${strBody}=    Deal with json body for add manual adjustment    ${AP_POSITIVE_DATA}  ${bossToken}     ${transactionAmount}   totalAmount=0    flowType=${flowType}  calculateTaxType=1  transactionType=${transactionType}
    # send request to preAdd
    ${response}    trading_manager_preAdd.Send Request And Get Response Data    ${bossToken}    ${strBody}
    ${incomeTax}    Set Variable    ${response.json()}[data][incomeTax]
    ${totalAmount}    Set Variable    ${response.json()}[data][totalAmount]
    # send request to add
    ${strBody}=    Deal with json body for add manual adjustment    ${AP_POSITIVE_DATA}  ${bossToken}     ${transactionAmount}   ${totalAmount}    flowType=${flowType}  calculateTaxType=1     incomeTax=${incomeTax}  transactionType=${transactionType}
    ${response}    trading_manager_add.Send Request And Get Response Data    ${bossToken}    ${strBody}
    Set Test Variable    ${jsonResult}     ${response.json()}
    Log    ${jsonResult}

the response should contain transactionId
    [Arguments]     ${jsonResult}
    Should Not Be Empty    ${jsonResult}[data][transactionId]
    Set Test Variable    ${transactionId}    ${jsonResult}[data][transactionId]





Send Request To ticketItem_bpm_manager API to get taskId in Mgt>>Manual Injection Review List
    [Documentation]     Business operation: search transactionId in TaskMgt>>Manual Injection Review List
    [Arguments]     ${bossToken}    ${transactionId}    ${existsAssignee}
    Sleep    3s
    ${response}    ticketItem_bpm_manager.Send Request And Get Response Data    ${bossToken}    ${transactionId}     ${existsAssignee}
    Set Test Variable    ${jsonResult}    ${response.json()}
    Log    ${jsonResult}

the response should contain taskId
    [Arguments]     ${jsonResult}
    Should Not Be Empty    ${jsonResult}[data][data][0][id]
    Set Test Variable    ${taskId}    ${jsonResult}[data][data][0][id]


Assigne Task to me
    [Documentation]     Business operation: assign task to me
    [Arguments]     ${bossToken}    ${taskId}
    ${taskIds}  Create List
    Append To List    ${taskIds}    ${taskId}
    Log     ${taskIds}

    ${response}    assignToMe.Send Request And Get Response Data    ${bossToken}    ${taskIds}
    Set Test Variable    ${jsonResult}    ${response.json()}
    Log    ${jsonResult}



Send Request To adjustment_review_list_todo API to get taskId in Flow>>Manual Injection Review Todo List
    [Documentation]     Business operation: search transactionId in Task>>Manual Injection Review List
    [Arguments]     ${bossToken}    ${transactionId}
    Sleep    5s
    ${response}    adjustment_review_list_todo.Send Request And Get Response Data    ${bossToken}    ${transactionId}
    Set Test Variable    ${jsonResult}    ${response.json()}
    Log    ${jsonResult}


Approve Manual Injection Review Task
    [Documentation]     Business operation: approve Manual Injection Review Task
    [Arguments]     ${bossToken}    ${taskId}
    ${response}    adjustment_approval.Send Request And Get Response Data    ${bossToken}    ${taskId}  action=Approval
    Set Test Variable    ${jsonResult}    ${response.json()}
    Log    ${jsonResult}


Reject Manual Injection Review Task
    [Documentation]     Business operation: approve Manual Injection Review Task
    [Arguments]     ${bossToken}    ${taskId}
    ${response}    adjustment_approval.Send Request And Get Response Data    ${bossToken}    ${taskId}  action=Decline
    Set Test Variable    ${jsonResult}    ${response.json()}
    Log    ${jsonResult}


finally Log the transactionId ${transactionId}
    Log    ${transactionId}






