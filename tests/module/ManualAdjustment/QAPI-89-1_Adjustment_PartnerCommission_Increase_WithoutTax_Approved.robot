*** Settings ***
Library    RequestsLibrary
Library    Collections
Library    String
Library    XML
Library    SeleniumLibrary
Library    DateTime
Library    JSONLibrary
Library    BuiltIn

Resource    ../../../resources/biz/Login/login.robot
Resource    ../../../resources/biz/ManualAdjustment/manualAdjustment.robot



Resource    ../../../resources/util/utilCommon.robot
Resource    ../../../resources/util/assertUtil.robot
Resource    ../../../resources/resource.robot

#Setup Test
Test Setup    Setup Env Variable
Test Teardown    Delete All Sessions



*** Variables ***
${BODY_FILE_PATH}    resources/data/ManualAdjustment_ApprovalDTO_workflow.json
${transactionAmount}    10000
${flowType}     add
${transactionType}  policyBonus


*** Test Cases ***
Manual Adjustment Partner Commission Increase Without Tax Approved
    [Tags]  notUsed
    Given Setup Data Testing
    When Login Boss Success
    Then manualAdjustment.Submit Manual Adjustment Requeqst without Tax    ${AP_POSITIVE_DATA}    ${bossToken}    ${transactionAmount}      ${flowType}     transactionType=${transactionType}
    Then the response should contain transactionId  ${jsonResult}

    Run Keyword And Ignore Error
    ...    Fail    "This keyword will fail to trigger retry"
    ...    AND    manualAdjustment.Send Request To adjustment_review_list_manager API to get taskId in Mgt>>Manual Injection Review List    ${bossToken}    ${transactionId}    ${AP_POSITIVE_DATA["Manual_Injection_ReviewTask_existsAssignee"]}
    ...    AND    The status code should be 200    ${jsonResult}[code]
    ...    AND    manualAdjustment.the response should contain taskId    ${jsonResult}

    Run Keyword And Ignore Error
    ...    Fail    "This keyword will fail to trigger retry"
    ...    AND    Assigne Task to me    ${bossToken}    ${taskId}
    ...    AND    The status code should be 200    ${jsonResult}[code]

    Run Keyword And Ignore Error
    ...    Fail    "This keyword will fail to trigger retry"
    ...    AND    manualAdjustment.Send Request To adjustment_review_list_todo API to get taskId in Flow>>Manual Injection Review Todo List    ${bossToken}    ${transactionId}
    ...    AND    The status code should be 200    ${jsonResult}[code]
    ...    AND    manualAdjustment.the response should contain taskId    ${jsonResult}

    Run Keyword And Ignore Error
    ...    Fail    "This keyword will fail to trigger retry"
    ...    AND    manualAdjustment.Approve Manual Injection Review Task    ${bossToken}    ${taskId}
    ...    AND    The status code should be 200    ${jsonResult}[code]

    Then finally Log the transactionId ${transactionId}







*** Keywords ***
Setup Data Testing
    #1.加载调账的json
    ${AP_POSITIVE_DATA}=    Load JSON From File    ${BODY_FILE_PATH}    encoding=UTF-8
    Set Test Variable    ${AP_POSITIVE_DATA}

Login Boss Success
    ${bossToken}    login.Login to Boss     ${env_vars}[BOSS_ACCOUNT]    ${env_vars}[BOSS_PASSWORD]
    Set Test Variable    ${bossToken}

