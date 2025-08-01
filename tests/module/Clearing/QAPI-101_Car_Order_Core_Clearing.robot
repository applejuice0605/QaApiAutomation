*** Settings ***
Library    RequestsLibrary
Library    Collections
Library    String
Library    XML
Library    SeleniumLibrary
Library    DateTime
Library    JSONLibrary

Resource    ../../../resources/biz/Login/login.robot
Resource    ../../../resources/biz/order/vehicle_order.robot

Resource    ../../../resources/biz/Payment/creatBilling_choosePayTypeAndPaymentScheme.robot
Resource    ../../../resources/biz/Payment/OVO.robot

Resource    ../../../resources/biz/underwriting/underwriting.robot
Resource    ../../../resources/biz/orderInfo/getPolicyInfo.robot


Resource    ../../../resources/biz/BonusAccount/bonusAccount.robot

Resource    ../../../resources/util/utilCommon.robot
Resource    ../../../resources/util/assertUtil.robot
Resource    ../../../resources/resource.robot

#Setup Test
Test Setup    Setup Env Variable
Test Teardown    Delete All Sessions



*** Variables ***
${ORDER_MSG_BODY_FILE_PATH}     Car_PlaceOrderData.json
${BODY_FILE_PATH}    resources/data/Underwriting_ApprovalDTO_workflow.json
${isAdvancePremium}    1

${payerType}    2
${paymentScheme}    1
${methodCode}   9203
${paymentMethod}    OVO
${slipStatus}   3
${expected_data_count}  4


*** Test Cases ***
Car Order Core Clearing
    [Tags]    uat   car    clearing
    Given Setup Data Testing
    When I have logined to FusePro and Boss
    Then Create Pay Now Order     ${ORDER_MSG_DATA}    ${token}
    Then Use Partner Pay and Full Payment to complete the payment
#    Then Done the underwriting workflow
    Then Check Commission Disbursed    ${token}     ${slipUids}   ${expected_data_count}
    Then finally Log the OrderNo ${orderNo}



*** Keywords ***
Setup Data Testing
    #1.加载下单的产品数据
    #1.1 下单产品数据路径
    Log    ${ORDER_MSG_BODY_FILE_PATH}
    Log    ${env_vars}[DATA_BASEURL]
    ${ORDER_MSG_BODY_FILE_PATH}    Set Variable    ${env_vars}[DATA_BASEURL]${ORDER_MSG_BODY_FILE_PATH}
    Log    ${ORDER_MSG_BODY_FILE_PATH}
    #1.2 下单产品数据
    ${ORDER_MSG_DATA}=    Load JSON From File    ${ORDER_MSG_BODY_FILE_PATH}
    Set Test Variable    ${ORDER_MSG_DATA}

    #2.加载核保的json
    ${Underwriting_DATA}=    Load JSON From File    ${BODY_FILE_PATH}    encoding=UTF-8
    Set Test Variable    ${Underwriting_DATA}



I have logined to FusePro and Boss
    # 调用登录接口
    ${token}=   login.Login to Application using mobile     ${env_vars}[FUSE_ACCOUNT]    ${env_vars}[FUSE_PASSWORD]
    ${bossToken}    login.Login to Boss     ${env_vars}[BOSS_ACCOUNT]    ${env_vars}[BOSS_PASSWORD]
    Set Test Variable    ${token}
    Set Test Variable    ${bossToken}


Create Pay Now Order
    [Arguments]     ${ORDER_MSG_DATA}    ${token}
    # 调用询价业务
    vehicle_order.I send the quotation request to savebinderrfq API    ${ORDER_MSG_DATA}    ${token}
    assertUtil.The response should contain the value quoteNo and rfqNo    ${jsonResult}
    # 调用下单业务
    vehicle_order.I send the place order request to createrfqorder API     ${ORDER_MSG_DATA}    ${token}    ${rfqNo}    ${quoteNo}    ${isAdvancePremium}
    assertUtil.The response should contain the value orderNo and orderId    ${jsonResult}
    # 获取policy包含的slipUids
    getPolicyInfo.Send request to order/v2/slip/slipLs API to get slipUids    ${token}    ${orderId}
    getPolicyInfo.The response should contain slipUids    ${jsonResult}
    Log     ${orderNo}
    Log     ${orderId}
    Log     ${slipUids}
    Sleep    10s

Use Partner Pay and Full Payment to complete the payment
    Run Keyword And Ignore Error    I continue to pay the order and send request the paymentBilling/create API     ${token}     ${orderNo}

    Send request to paymentBillingList API     ${token}     ${orderId}
    the response of paymentBilling/List API should contain securityCode and paymentBillNo     ${jsonResult}

    I choose PartnerPay & PaymentScheme & PaymentMethod and send request to /slip/process API   token=${token}     orderId=${orderId}     securityCode=${securityCode}    paymentScheme=${paymentScheme}
    the response should contain lessAmount      ${jsonResult}


    Partner Cashier use OVO to pay and Send request to getChannelFee API   ${token}    ${securityCode}
    the response should contain channelFee and got totalInstallmentAmount   ${jsonResult}


    Partner Cashier confirm complete to pay and Send request to slip/channel/process API    token=${token}  amount=${amount}    securityCode=${securityCode}
    And the response should contain bizTransactionId    ${jsonResult}


Done the underwriting workflow
    Sleep    10s
    [Order Review Task] I send request to underwritingV2/list/manager API  ${bossToken}    ${orderNo}   ${ORDER_MSG_DATA["UNDERWRITING_ORDER_REVIEW_EXISTSASSIGNEE"]}
    the response should contain taskId    ${jsonResult}
    I send request to assigneToMe API     ${jsonResult}   ${bossToken}
    I send request to underwritingV2/list/todo API    ${bossToken}    ${orderNo}
    the response should contain taskId    ${jsonResult}
    [Order Review Task] I send request to approve API      ${bossToken}    ${orderNo}   ${Underwriting_DATA}


    [toOffline Task] I send request to underwritingV2/list/manager API  ${bossToken}    ${orderNo}   ${ORDER_MSG_DATA["UNDERWRITING_OFFLINE_EXISTSASSIGNEE"]}
    the response should contain taskId    ${jsonResult}
    I send request to assigneToMe API     ${jsonResult}   ${bossToken}
    I send request to underwritingV2/list/todo API    ${bossToken}    ${orderNo}
    the response should contain taskId    ${jsonResult}
    [toOffline Task] I send request to approve API to approve toOffline task   ${bossToken}    ${orderNo}   ${Underwriting_DATA}

    Send request to Boss:/api/oms/slip/v2/list API to get slipStatus    ${bossToken}    ${orderNo}
    The response's=${jsonResult} slipStatus should be ${slipStatus}

#Check Commission Disbursed
