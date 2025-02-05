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
Resource    ../../../resources/biz/orderInfo/getPolicyInfo.robot
Resource    ../../../resources/biz/Payment/creatBilling_choosePayTypeAndPaymentScheme.robot
Resource    ../../../resources/biz/Payment/OVO.robot


Resource    ../../../resources/util/utilCommon.robot
Resource    ../../../resources/util/assertUtil.robot
Resource    ../../../resources/resource.robot

#Setup Test
Test Setup    Setup Env Variable
Test Teardown    Delete All Sessions


*** Variables ***
${BODY_FILE_PATH}    Car_PlaceOrderData.json
${isAdvancePremium}     0
${payerType}    2
${paymentScheme}    1
${methodCode}   9203
${paymentMethod}    OVO
${bonusDeduction}   100
${pointsDeduction}  100000

*** Test Cases ***
OVO PartnerPay NetPayment CarOrder
    [Tags]    uat   OVO
    Given Setup Data Testing
    When I have an unpaid order and have logined
    Then Run keyword And Continue on Failure    I continue to pay the order and send request the paymentBilling/create API     ${token}     ${orderNo}
    Then Run keyword And Continue on Failure    The status code should be 200    ${jsonResult}[code]

    Then Send request to paymentBillingList API     ${token}     ${orderId}
    Then The status code should be 200    ${jsonResult}[code]
    And the response of paymentBilling/List API should contain securityCode and paymentBillNo     ${jsonResult}



    Then I choose PartnerPay & PaymentScheme & PaymentMethod and send request to /slip/process API   token=${token}     orderId=${orderId}     securityCode=${securityCode}    paymentScheme=${paymentScheme}    bonusDeduction=${bonusDeduction}     pointsDeduction=${pointsDeduction}
    Then The status code should be 200    ${jsonResult}[code]
    And the response should contain lessAmount      ${jsonResult}


    Then Partner Cashier use OVO to pay and Send request to getChannelFee API  ${token}    ${securityCode}
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


I have an unpaid order and have logined
    # 调用登录接口
    ${token}=   login.Login to Application using mobile     ${env_vars}[FUSE_ACCOUNT]    ${env_vars}[FUSE_PASSWORD]
    ${bossToken}    login.Login to Boss     ${env_vars}[BOSS_ACCOUNT]    ${env_vars}[BOSS_PASSWORD]
    Set Test Variable    ${token}
    Set Test Variable    ${bossToken}
    # 调用询价业务
    vehicle_order.I send the quotation request to savebinderrfq API    ${AP_POSITIVE_DATA}    ${token}
    assertUtil.The response should contain the value quoteNo and rfqNo    ${jsonResult}
    # 调用下单业务
    vehicle_order.I send the place order request to createrfqorder API     ${AP_POSITIVE_DATA}    ${token}    ${rfqNo}    ${quoteNo}    ${isAdvancePremium}
    assertUtil.The response should contain the value orderNo and orderId    ${jsonResult}
    # 获取policy包含的slipUids
    getPolicyInfo.Send request to order/v2/slip/slipLs API to get slipUids    ${token}    ${orderId}
    getPolicyInfo.The response should contain slipUids    ${jsonResult}
    Log     ${orderNo}
    Log     ${orderId}
    Log     ${slipUids}
    Set Test Variable    ${token}
