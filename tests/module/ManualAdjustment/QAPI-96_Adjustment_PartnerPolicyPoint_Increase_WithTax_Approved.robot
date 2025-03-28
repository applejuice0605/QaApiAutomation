*** Settings ***
Library    RequestsLibrary
Library    Collections
Library    String
Library    XML
Library    SeleniumLibrary
Library    DateTime
Library    JSONLibrary

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
${transactionType}  policyPoint


*** Test Cases ***
Manual Adjustment Partner Policy Point Increase With Tax Approved
    [Tags]    uat
    Given Setup Data Testing
    When Login Boss Success
    Then manualAdjustment.Submit Manual Adjustment Requeqst without Tax    ${AP_POSITIVE_DATA}    ${bossToken}    ${transactionAmount}      ${flowType}     transactionType=${transactionType}
    Then manualAdjustment.the response of Submit Request API should contain transactionId  ${jsonResult}
    
    Then manualAdjustment.Send Request To adjustment_review_list_manager API to get taskId in Mgt>>Manual Injection Review List    ${bossToken}    ${transactionId}    ${AP_POSITIVE_DATA["Manual_Injection_ReviewTask_existsAssignee"]}
    Then The status code should be 200    ${jsonResult}[code]
    And manualAdjustment.the response should contain taskId    ${jsonResult}

    Then Assigne Task to me    ${bossToken}    ${taskId}
    And The status code should be 200    ${jsonResult}[code]

    Then manualAdjustment.Send Request To adjustment_review_list_todo API to get taskId in Flow>>Manual Injection Review Todo List    ${bossToken}    ${transactionId}
    Then The status code should be 200    ${jsonResult}[code]
    And manualAdjustment.the response should contain taskId    ${jsonResult}

    Then manualAdjustment.Approve Manual Injection Review Task    ${bossToken}    ${taskId}
    Then The status code should be 200    ${jsonResult}[code]

    Then finally Log the transactionId ${transactionId}






*** Keywords ***
Setup Data Testing
    #1.加载调账的json
    ${AP_POSITIVE_DATA}=    Load JSON From File    ${BODY_FILE_PATH}    encoding=UTF-8
    Set Test Variable    ${AP_POSITIVE_DATA}

Login Boss Success
    ${bossToken}    login.Login to Boss     ${env_vars}[BOSS_ACCOUNT]    ${env_vars}[BOSS_PASSWORD]
    Set Test Variable    ${bossToken}

