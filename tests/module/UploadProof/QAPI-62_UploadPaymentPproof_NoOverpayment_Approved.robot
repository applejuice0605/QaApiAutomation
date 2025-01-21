*** Settings ***
Library    Collections
Library    BuiltIn
Library    OperatingSystem

Resource    ../../../resources/biz/Login/login.robot
Resource    ../../../resources/biz/order/vehicle_order.robot

Resource    ../../../resources/biz/underwriting/underwriting.robot
Resource    ../../../resources/biz/orderInfo/getPolicyInfo.robot


Resource    ../../../resources/util/utilCommon.robot
Resource    ../../../resources/util/assertUtil.robot
Resource    ../../../resources/resource.robot

#Setup Test
Test Setup    Setup Env Variable
Test Teardown    Delete All Sessions



*** Variables ***
${ORDER_MSG_BODY_FILE_PATH}     Car_PlaceOrderData.json
${BODY_FILE_PATH}    UploadPaymentProof_ApprovalDTO_workflow
${isAdvancePremium}    0
${slipStatus}   3




*** Test Cases ***
Upload payment proof no overpayment,Policy in payment billing workflow approved success
    [Tags]    uat   Upload-payment-proof
    Given Setup Data Testing
    When I have an unpaid order and have logined to Boss






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

    Log     ${orderNo}
    Log     ${orderId}
    Set Test Variable    ${bossToken}

    Sleep    10s