*** Settings ***
Library    Collections
Library    BuiltIn
Library    OperatingSystem

Resource    ../../../resources/biz/Login/login.robot
Resource    ../../../resources/biz/order/vehicle_order.robot
Resource    ../../../resources/biz/Payment/uploadPaymentProof_workflow.robot
Resource    ../../../resources/biz/Underwriting/underwriting.robot




Resource    ../../../resources/util/utilCommon.robot
Resource    ../../../resources/util/assertUtil.robot
Resource    ../../../resources/resource.robot

#Setup Test
Test Setup    Setup Env Variable
Test Teardown    Delete All Sessions



*** Variables ***
${ORDER_MSG_BODY_FILE_PATH}     Car_PlaceOrderData.json
${BODY_FILE_PATH}    resources/data/UploadPaymentProof_ApprovalDTO_workflow.json
${isAdvancePremium}    0
${slipStatus}   3
${overpaymentAmount}    10000





*** Test Cases ***
Upload payment proof with overpayment,Policy in payment billing workflow approved success
    [Tags]    uat   upload-payment-proof
    Given Setup Data Testing
    When I have an unpaid order and have logined to Boss
    Then Send Request To paymentBilling/list API to get paymentBillingNo    ${bossToken}    ${orderNo}
    Then Send Request To paymentBilling/list API to get paymentBillingNo    ${bossToken}    ${orderNo}
    Then Send Request To paymentBilling/list API to get paymentBillingNo    ${bossToken}    ${orderNo}
    Then Send Request To paymentBilling/list API to get paymentBillingNo    ${bossToken}    ${orderNo}
    Then The status code should be 200    ${jsonResult}[code]
    And the response should contain paymentBillingNo    ${jsonResult}

    Then Send Request To uploadProof API to upload payment proof with overpayment     ${AP_POSITIVE_DATA}     ${bossToken}    ${paymentBillNo}  ${overpaymentAmount}
    Then The status code should be 200    ${jsonResult}[code]



    Then Send Request To paymentBilling_list_manager API to get payment billing taskId in Payment Billing Mgt List    ${bossToken}    ${orderNo}    ${ORDER_MSG_AP_POSITIVE_DATA["paymentBilling_manager_existsAssignee"]}
    Then Send Request To paymentBilling_list_manager API to get payment billing taskId in Payment Billing Mgt List    ${bossToken}    ${orderNo}    ${ORDER_MSG_AP_POSITIVE_DATA["paymentBilling_manager_existsAssignee"]}
    Then Send Request To paymentBilling_list_manager API to get payment billing taskId in Payment Billing Mgt List    ${bossToken}    ${orderNo}    ${ORDER_MSG_AP_POSITIVE_DATA["paymentBilling_manager_existsAssignee"]}
    Then Send Request To paymentBilling_list_manager API to get payment billing taskId in Payment Billing Mgt List    ${bossToken}    ${orderNo}    ${ORDER_MSG_AP_POSITIVE_DATA["paymentBilling_manager_existsAssignee"]}
    Then The status code should be 200    ${jsonResult}[code]
    And uploadPaymentProof_workflow.the response should contain taskId    ${jsonResult}

    Then Assigne Task to me    ${bossToken}    ${taskId}
    And The status code should be 200    ${jsonResult}[code]

    Then Send Request To paymentBilling_list_todo API to get payment billing taskId in Payment Billing Flow List    ${bossToken}    ${orderNo}
    Then Send Request To paymentBilling_list_todo API to get payment billing taskId in Payment Billing Flow List    ${bossToken}    ${orderNo}
    Then Send Request To paymentBilling_list_todo API to get payment billing taskId in Payment Billing Flow List    ${bossToken}    ${orderNo}
    Then Send Request To paymentBilling_list_todo API to get payment billing taskId in Payment Billing Flow List    ${bossToken}    ${orderNo}
    Then The status code should be 200    ${jsonResult}[code]
    And uploadPaymentProof_workflow.the response should contain taskId    ${jsonResult}

    Then Approve Payment Billing Task     ${AP_POSITIVE_DATA}     ${bossToken}    ${paymentBillNo}    ${taskId}    ${actualPayableAmount}  ${actualPaymentAmount}   ${overpaymentAmount}
    Then The status code should be 200    ${jsonResult}[code]

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

    #2.加载上传支付凭证的json
    ${AP_POSITIVE_DATA}=    Load JSON From File    ${BODY_FILE_PATH}    encoding=UTF-8
    Set Test Variable    ${AP_POSITIVE_DATA}



I have an unpaid order and have logined to Boss
    # 调用登录接口
    ${token}=   login.Login to Application using mobile     ${env_vars}[FUSE_ACCOUNT]    ${env_vars}[FUSE_PASSWORD]
    ${bossToken}    login.Login to Boss     ${env_vars}[BOSS_ACCOUNT]    ${env_vars}[BOSS_PASSWORD]
    # 调用询价业务
    vehicle_order.I send the quotation request to savebinderrfq API    ${ORDER_MSG_AP_POSITIVE_DATA}    ${token}
    assertUtil.The response should contain the value quoteNo and rfqNo    ${jsonResult}
    # 调用下单业务
    vehicle_order.I send the place order request to createrfqorder API     ${ORDER_MSG_AP_POSITIVE_DATA}    ${token}    ${rfqNo}    ${quoteNo}    ${isAdvancePremium}
    assertUtil.The response should contain the value orderNo and orderId    ${jsonResult}

#    Set Test Variable    ${orderNo}    FUSE-20250204-055558600
    Log     ${orderNo}
#    Log     ${orderId}
    Set Test Variable    ${bossToken}

    Sleep    10s