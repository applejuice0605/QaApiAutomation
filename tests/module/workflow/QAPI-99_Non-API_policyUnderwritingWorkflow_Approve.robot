*** Settings ***
Library    RequestsLibrary
Library    Collections
Library    String
Library    XML
Library    SeleniumLibrary
Library    DateTime
Library    JSONLibrary

Resource    ../../../resources/biz/Login/login.robot
Resource    ../../../resources/biz/order/property/property_order.robot

Resource    ../../../resources/api/underwriting/underwritingV2_list_manager.robot
Resource    ../../../resources/api/underwriting/assignToMe.robot
Resource    ../../../resources/api/underwriting/underwritingV2_list_todo.robot
Resource    ../../../resources/api/underwriting/approval.robot

Resource    ../../../resources/util/utilCommon.robot

#Setup Test
#Suite Setup     Setup Data Testing
#Suite Teardown    Finally Log the orderNo    ${orderNo}


*** Variables ***
${BODY_FILE_PATH}    resources/data/ApprovalDTO_workflow.json
${taskName}     Order Review Task

*** Test Cases ***
Non-API_policyUnderwritingWorkflow_Approve
    [Tags]    uat
    Given Setup Data Testing
    When I have an underwriting order and have logined to Boss
    Then [Order Review Task] I send request to underwritingV2/list/manager API
    Then the status code should be 200
    And the response should contain taskId
    Then I send request to assigneToMe API
    Then the status code should be 200
    Then I send request to underwritingV2/list/todo API
    Then the status code should be 200
    And the response should contain taskId
    Then [Order Review Task] I send request to approve API


    Then [toOffline Task] I send request to underwritingV2/list/manager API
    Then the status code should be 200
    And the response should contain taskId
    Then I send request to assigneToMe API
    Then the status code should be 200
    Then I send request to underwritingV2/list/todo API
    Then the status code should be 200
    And the response should contain taskId
    Then [toOffline Task] I send request to approve API

    Then finally Log the OrderNo




*** Keywords ***
Setup Data Testing
    ${AP_POSITIVE_DATA}=    Load JSON From File    ${BODY_FILE_PATH}    encoding=UTF-8
    Set Test Variable    ${AP_POSITIVE_DATA}

I have an underwriting order and have logined to Boss
    # 调用登录接口
    ${token}  login.Login to Application using mobile
    # 调用下单业务
    ${orderInfo}    property_order.Property Order Pay Now without discount    ${token}
    Log     ${orderInfo}
    Set Test Variable    ${orderNo}    ${orderInfo[0]}
    Set Test Variable    ${orderId}    ${orderInfo[1]}
    Set Test Variable    ${token}

    # 调用登录Boss业务
    ${bossToken}    login.Login to Boss
    Set Test Variable    ${bossToken}

    Sleep    10s



[Order Review Task] I send request to underwritingV2/list/manager API
    ${response}    underwritingV2_list_manager.Send Request And Get Response Data    ${bossToken}    ${orderNo}

    Set Test Variable    ${jsonResult}    ${response.json()}
    Log    ${jsonResult}


[toOffline Task] I send request to underwritingV2/list/manager API
    Sleep    10s

    ${response}    underwritingV2_list_manager.Send Request And Get Response Data    ${bossToken}    ${orderNo}     existsAssignee=true

    Set Test Variable    ${jsonResult}    ${response.json()}
    Log    ${jsonResult}




I send request to underwritingV2/list/todo API
    Sleep    10s
    ${response}    underwritingV2_list_todo.Send Request And Get Response Data    ${bossToken}    ${orderNo}
    Set Test Variable    ${jsonResult}    ${response.json()}
    Log    ${jsonResult}




[Order Review Task] I send request to approve API
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

[toOffline Task] I send request to approve API
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





the response should contain taskId
    ${total}  Set Variable    ${jsonResult}[data][total]
    Should Be True    ${total} > 0
    Log     ${jsonResult}[data][data][0][id]
    Should Not Be Empty    ${jsonResult}[data][data][0][id]



I send request to assigneToMe API
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
























the status code should be 200
    Log    ${jsonResult}
    Should Be Equal As Numbers    ${jsonResult}[code]    200

finally Log the OrderNo
    Log    ${orderNo}



