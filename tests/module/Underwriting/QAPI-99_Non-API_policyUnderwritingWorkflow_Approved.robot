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
Resource    ../../../resources/biz/Underwriting/underwriting.robot
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
${slipStatus}   3

*** Test Cases ***
Non-API_policyUnderwritingWorkflow_Approved
    [Tags]    uat
    Given Setup Data Testing
    When I have an underwriting order and have logined to Boss
    Then [Order Review Task] Using OrderNo Searching in Mgmt Task List    ${bossToken}    ${orderNo}   ${ORDER_MSG_AP_POSITIVE_DATA["UNDERWRITING_ORDER_REVIEW_EXISTSASSIGNEE"]}
    Then I send request to assigneToMe API     ${taskResult}   ${bossToken}
    Then The status code should be 200    ${jsonResult}[code]

    Then Using OrderNo Searching in Todo Task List    ${bossToken}    ${orderNo}
    Then [Order Review Task] I send request to approve API      ${bossToken}    ${taskResult}   ${AP_POSITIVE_DATA}

    Then [toOffline Review Task] Using OrderNo Searching in Mgmt Task List    ${bossToken}    ${orderNo}   ${ORDER_MSG_AP_POSITIVE_DATA["UNDERWRITING_OFFLINE_EXISTSASSIGNEE"]}
    Then I send request to assigneToMe API     ${taskResult}   ${bossToken}
    Then The status code should be 200    ${jsonResult}[code]

    Then Using OrderNo Searching in Todo Task List    ${bossToken}    ${orderNo}
    Then [toOffline Task] I send request to approve API to approve toOffline task   ${bossToken}    ${taskResult}   ${AP_POSITIVE_DATA}

    Then Send request to Boss:/api/oms/slip/v2/list API to get slipStatus    ${bossToken}    ${orderNo}
    Then The response's=${jsonResult} slipStatus should be ${slipStatus}

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



# [Order Review Task] Get the order review task in Underwriting Flow List

#     FOR    ${counter}    IN RANGE    1    5
#         Log    ${counter}
#     # 调用查询任务列表接口
#         [Order Review Task] I send request to underwritingV2/list/manager API  ${bossToken}    ${orderNo}   ${ORDER_MSG_AP_POSITIVE_DATA["UNDERWRITING_ORDER_REVIEW_EXISTSASSIGNEE"]}
#         The status code should be 200    ${jsonResult}[code]
#         BREAK If
#         Break If    the response should contain taskId    ${jsonResult}


#     END

