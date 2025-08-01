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

Resource    ../../../resources/util/utilCommon.robot
Resource    ../../../resources/util/assertUtil.robot
Resource    ../../../resources/resource.robot



#Setup Test
Test Setup    Setup Env Variable
Test Teardown    Delete All Sessions

*** Variables ***
${ORDER_MSG_BODY_FILE_PATH}     Car_PlaceOrderData.json
${BODY_FILE_PATH}    Car_PlaceOrderData.json
${isAdvancePremium}     1
${payerType}    2
${paymentScheme}    1
${paymentMethod}    VA

*** Test Cases ***
Non-API_policyUnderwritingWorkflow_Approved
    [Tags]  notUsed
    Given Setup Data Testing
    When I have a whitelist account and have logined
    Then I send the quotation request to savebinderrfq API   ${AP_POSITIVE_DATA}     ${token}
    Then The status code should be 200    ${jsonResult}[code]
    And the response should contain the value quoteNo and rfqNo     ${jsonResult}

    Then I send the place order request to createrfqorder API    ${AP_POSITIVE_DATA}     ${token}    ${rfqNo}    ${quoteNo}  ${isAdvancePremium}
    Then The status code should be 200    ${jsonResult}[code]
    And the response should contain the value orderNo and orderId    ${jsonResult}

    Then I continue to pay the order and send request the paymentBilling/create API     ${token}     ${orderNo}
    Then The status code should be 200    ${jsonResult}[code]
    And the response of paymentBilling/create API should contain securityCode    ${jsonResult}

    Then I choose PartnerPay & PaymentScheme & PaymentMethod and send request to /slip/process API     ${token}     ${orderId}     ${securityCode}    ${paymentScheme}
    Then The status code should be 200    ${jsonResult}[code]
    And the response should contain lessAmount      ${jsonResult}


    Then Partner Cashier use OVO to pay and Send request to getChannelFee API   ${token}    ${securityCode}
    Then The status code should be 200  ${jsonResult}[code]
    And the response should contain channelFee and got totalInstallmentAmount   ${jsonResult}

    Then Partner Cashier confirm complete to pay and Send request to slip/channel/process API    token=${token}  amount=${amount}    securityCode=${securityCode}
    Then The status code should be 200  ${jsonResult}[code]
    And the response should contain bizTransactionId    ${jsonResult}






    Then finally Log the OrderNo ${orderNo}

*** Keywords ***
Setup Data Testing
    Log    ${BODY_FILE_PATH}
    Log    ${env_vars}[DATA_BASEURL]
    ${BODY_FILE_PATH}    Set Variable    ${env_vars}[DATA_BASEURL]${BODY_FILE_PATH}
    Log    ${BODY_FILE_PATH}
    ${AP_POSITIVE_DATA}=    Load JSON From File    ${BODY_FILE_PATH}
    Set Test Variable    ${AP_POSITIVE_DATA}

I have a whitelist account and have logined
    ${token}=   login.Login to Application using mobile     ${env_vars}[FUSE_ACCOUNT]    ${env_vars}[FUSE_PASSWORD]
    Set Test Variable    ${token}

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



I have logined to FusePro and Boss
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
