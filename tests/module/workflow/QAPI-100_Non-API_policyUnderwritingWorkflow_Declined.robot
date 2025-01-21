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
Resource    ../../../resources/biz/underwriting/underwriting.robot
Resource    ../../../resources/biz/orderInfo/getPolicyInfo.robot


Resource    ../../../resources/util/utilCommon.robot
Resource    ../../../resources/util/assertUtil.robot
Resource    ../../../resources/resource.robot

#Setup Test
Test Setup    Setup Env Variable
Test Teardown    Delete All Sessions


*** Variables ***
${ORDER_MSG_BODY_FILE_PATH}     EQVET_Property_PlaceOrderData.json
${BODY_FILE_PATH}    resources/data/Underwriting_ApprovalDTO_workflow.json
${isAdvancePremium}    0
${slipStatus}   4

*** Test Cases ***
API_policyUnderwritingWorkflow_Declined
    [Tags]    uat
    Given Setup Data Testing
    When I have an underwriting order and have logined to Boss
    Then [Order Review Task] I send request to underwritingV2/list/manager API  ${bossToken}    ${orderNo}   ${ORDER_MSG_AP_POSITIVE_DATA["UNDERWRITING_ORDER_REVIEW_EXISTSASSIGNEE"]}
    Then The status code should be 200    ${jsonResult}[code]
    And the response should contain taskId    ${jsonResult}
    Then I send request to assigneToMe API     ${jsonResult}   ${bossToken}
    Then The status code should be 200    ${jsonResult}[code]
    Then I send request to underwritingV2/list/todo API    ${bossToken}    ${orderNo}
    Then The status code should be 200    ${jsonResult}[code]
    And the response should contain taskId    ${jsonResult}
    Then [Order Review Task] I send request to approve API      ${bossToken}    ${orderNo}   ${AP_POSITIVE_DATA}


    Then [toOffline Task] I send request to underwritingV2/list/manager API  ${bossToken}    ${orderNo}   ${ORDER_MSG_AP_POSITIVE_DATA["UNDERWRITING_OFFLINE_EXISTSASSIGNEE"]}
    Then The status code should be 200    ${jsonResult}[code]
    And the response should contain taskId    ${jsonResult}
    Then I send request to assigneToMe API     ${jsonResult}   ${bossToken}
    Then The status code should be 200    ${jsonResult}[code]
    Then I send request to underwritingV2/list/todo API    ${bossToken}    ${orderNo}
    Then The status code should be 200    ${jsonResult}[code]
    And the response should contain taskId    ${jsonResult}
    Then [toOffline Task] I send request to approve API to decline toOffline task      ${bossToken}    ${orderNo}   ${AP_POSITIVE_DATA}

    Then Send request to Boss:/api/oms/slip/v2/list API to get slipStatus    ${bossToken}    ${orderNo}
    Then The response's slipStatus should be ${slipStatus}   ${jsonResult}

    Then finally Log the OrderNo ${orderNo}






*** Keywords ***
Setup Data Testing
    #1.加载下单的产品数据
    Log    ${ORDER_MSG_BODY_FILE_PATH}
    Log    ${env_vars}[DATA_BASEURL]
    ${ORDER_MSG_BODY_FILE_PATH}    Set Variable    ${env_vars}[DATA_BASEURL]${ORDER_MSG_BODY_FILE_PATH}
    Log    ${ORDER_MSG_BODY_FILE_PATH}
    ${ORDER_MSG_AP_POSITIVE_DATA}=    Load JSON From File    ${ORDER_MSG_BODY_FILE_PATH}
    Set Test Variable    ${ORDER_MSG_AP_POSITIVE_DATA}

    #2.加载核保的json
    ${AP_POSITIVE_DATA}=    Load JSON From File    ${BODY_FILE_PATH}    encoding=UTF-8
    Set Test Variable    ${AP_POSITIVE_DATA}



I have an underwriting order and have logined to Boss
    # 调用登录接口
    ${token}=   login.Login to Application using mobile     ${env_vars}[FUSE_ACCOUNT]    ${env_vars}[FUSE_PASSWORD]
    ${bossToken}    login.Login to Boss     ${env_vars}[BOSS_ACCOUNT]    ${env_vars}[BOSS_PASSWORD]
    # 调用询价业务
    property_order.I send the quotation request to savebinderrfq API    ${ORDER_MSG_AP_POSITIVE_DATA}    ${token}
    assertUtil.The response should contain the value quoteNo and rfqNo    ${jsonResult}
    # 调用下单业务
    property_order.I send the place order request to createrfqorder API     ${ORDER_MSG_AP_POSITIVE_DATA}    ${token}    ${rfqNo}    ${quoteNo}    ${isAdvancePremium}
    assertUtil.The response should contain the value orderNo and orderId    ${jsonResult}

    Log     ${orderNo}
    Log     ${orderId}
    Set Test Variable    ${bossToken}

    Sleep    10s

#
#
#
#[Order Review Task] I send request to underwritingV2/list/manager API
#    ${response}    underwritingV2_list_manager.Send Request And Get Response Data    ${bossToken}    ${orderNo}     existsAssignee=${env_vars}[UNDERWRITING_ORDER_REVIEW_EXISTSASSIGNEE]
#
#    Set Test Variable    ${jsonResult}    ${response.json()}
#    Log    ${jsonResult}
#
#
#[toOffline Task] I send request to underwritingV2/list/manager API
#    Sleep    10s
#
#    ${response}    underwritingV2_list_manager.Send Request And Get Response Data    ${bossToken}    ${orderNo}     existsAssignee=${env_vars}[UNDERWRITING_OFFLINE_EXISTSASSIGNEE]
#
#    Set Test Variable    ${jsonResult}    ${response.json()}
#    Log    ${jsonResult}
#
#
#
#
#I send request to underwritingV2/list/todo API
#    Sleep    10s
#    ${response}    underwritingV2_list_todo.Send Request And Get Response Data    ${bossToken}    ${orderNo}
#    Set Test Variable    ${jsonResult}    ${response.json()}
#    Log    ${jsonResult}
#
#
#
#
#[Order Review Task] I send request to approve API
#    #1. 获取当前任务对应的jsonBody
#    ${jsonBody}    Set Variable   ${AP_POSITIVE_DATA["underwriting_OrderReviewTask_Approve_toOffline"]}
#
#    #2. 依次处理每个任务
#    ${total}  Set Variable    ${jsonResult}[data][total]
#    FOR    ${counter}    IN RANGE    0    ${total}
#        Log    ${counter}
#        #2.1. 从manager接口获取task信息：任务id...
#        ${taskId}    Get From Dictionary    ${jsonResult}[data][data][${counter}]    id
#
#        #2.2. update jsonBody
#        ${jsonBody}=    Update Value To Json    ${jsonBody}    $.data.orderId    ${orderId}
#        ${jsonBody}=    Update Value To Json    ${jsonBody}    $.taskId    ${taskId}
#
#        #3. convert jsonBody to string
#        ${strBody}  Convert Json To String    ${jsonBody}
#
#        #4. send request and get response data
#        ${response}    approval.Send Request And Get Response Data    ${bossToken}    ${strBody}
#
#        #5. check response
#        Should Be True    ${response.json()}[code] == 200
#    END
#
#[toOffline Task] I send request to approve API
#    #1. 获取当前任务对应的jsonBody
#    ${jsonBody}    Set Variable   ${AP_POSITIVE_DATA["decline"]}
#
#    #2. update jsonBody
#    ${taskId}    Get From Dictionary    ${jsonResult}[data][data][0]    id
#
#
#    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.data.orderId    ${orderId}
#    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.taskId    ${taskId}
#
#    #3. convert jsonBody to string
#    ${strBody}  Convert Json To String    ${jsonBody}
#
#    #4. send request and get response data
#    ${response}    approval.Send Request And Get Response Data    ${bossToken}    ${strBody}
#
#    #5. check response
#    Should Be True    ${response.json()}[code] == 200
#
#
#
#the response should contain taskId
#    ${total}  Set Variable    ${jsonResult}[data][total]
#    Should Be True    ${total} > 0
#    Log     ${jsonResult}[data][data][0][id]
#    Should Not Be Empty    ${jsonResult}[data][data][0][id]
#
#
#
#
#I send request to assigneToMe API
#    Log    ${jsonResult}
#    ${total}    Set Variable    ${jsonResult}[data][total]
#    ${taskIds}  Create List
#    FOR    ${counter}    IN RANGE    0    ${total}
#        Log    ${counter}
#        ${taskId}    Get From Dictionary    ${jsonResult}[data][data][${counter}]    id
#        Append To List    ${taskIds}    ${taskId}
#    END
#    Log     ${taskIds}
#
#    ${response}    assignToMe.Send Request And Get Response Data    ${bossToken}    ${taskIds}
#    Set Test Variable    ${jsonResult}    ${response.json()}

