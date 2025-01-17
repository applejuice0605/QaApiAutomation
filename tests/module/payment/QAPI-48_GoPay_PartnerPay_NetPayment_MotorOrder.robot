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
Resource    ../../../resources/biz/Payment/GoPay.robot


Resource    ../../../resources/util/utilCommon.robot
Resource    ../../../resources/util/assertUtil.robot
Resource    ../../../resources/resource.robot

#Setup Test
Test Setup    Setup Env Variable
Test Teardown    Delete All Sessions


*** Variables ***
${BODY_FILE_PATH}    Motor_PlaceOrderData.json
${isAdvancePremium}     0
${payerType}    2
${paymentScheme}    2
${methodCode}   9201
${paymentMethod}    GoPay

*** Test Cases ***
GoPay CustomerPay FullPayment Motor Order
    [Tags]    uat   GoPay
    Given Setup Data Testing
    When I have an unpaid order and have logined
    Then Run keyword And Continue on Failure    I continue to pay the order and send request the paymentBilling/create API     ${token}     ${orderNo}
    Then Run keyword And Continue on Failure    The status code should be 200    ${jsonResult}[code]

    Then Send request to paymentBillingList API     ${token}     ${orderId}
    Then The status code should be 200    ${jsonResult}[code]
    And the response of paymentBilling/List API should contain securityCode and paymentBillNo     ${jsonResult}

    Then I choose Partner Pay & Using Payment Scheme=${Payment Scheme} & paymentMethod=${paymentMethod} and send request to /slip/process API   token=${token}     paymentScheme=${paymentScheme}  orderId=${orderId}    securityCode=${securityCode}
    Then The status code should be 200    ${jsonResult}[code]
    And the response should contain lessAmount      ${jsonResult}

    Then Partner Cashier confirm complete to pay using GoPay and Send request to slip/channel/process API     token=${token}    amount=${amount}    securityCode=${securityCode}
    Then The status code should be 200  ${jsonResult}[code]
    Then the response should contain referenceNo    ${jsonResult}


    Then Send request to paymentBilling/info API to get paymentSlipNo   bossToken=${bossToken}    paymentBillNo=${paymentBillNo}
    Then the response should contain paymentSlipNo  ${jsonResult}


    Then I call the Mock GoPay Payment API to change the payment status to paid    amount=${amount}    referenceNo=${referenceNo}   payment_slip_no=${paymentSlipNo}
    Then The status code should be 200    ${jsonResult}[code]

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
