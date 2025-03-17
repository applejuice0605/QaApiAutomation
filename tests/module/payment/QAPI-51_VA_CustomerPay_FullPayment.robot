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
Resource    ../../../resources/biz/orderInfo/getPolicyInfo.robot
Resource    ../../../resources/biz/Payment/creatBilling_choosePayTypeAndPaymentScheme.robot
Resource    ../../../resources/biz/Payment/VA.robot


Resource    ../../../resources/util/utilCommon.robot
Resource    ../../../resources/util/assertUtil.robot
Resource    ../../../resources/resource.robot

#Setup Test
Test Setup    Setup Env Variable
Test Teardown    Delete All Sessions


*** Variables ***
${BODY_FILE_PATH}    Property_PlaceOrderData.json
${isAdvancePremium}     0
${payerType}    1
${paymentScheme}    1
${methodCode}   9204
${bank}     BCA

*** Test Cases ***
VA CustomerPay FullPayment Property Order
    [Tags]    uat   VA
    Given Setup Data Testing
    When I have an unpaid order and have logined
    Then Run keyword And Continue on Failure    I continue to pay the order and send request the paymentBilling/create API     ${token}     ${orderNo}
    Then Run keyword And Continue on Failure    The status code should be 200    ${jsonResult}[code]

    Then Send request to paymentBillingList API     ${token}     ${orderId}
    Then The status code should be 200    ${jsonResult}[code]
    And the response of paymentBilling/List API should contain securityCode and paymentBillNo     ${jsonResult}

    Then I choose CutsomerPay and send request to generator/customer/payment/token API     ${token}     ${securityCode}
    Then The status code should be 200    ${jsonResult}[code]
    And the response should contain customerToken    ${jsonResult}

    Then I confirm to complete the payment using "CustomerPay FullPayment" and send the request to /slip/process API     ${token}     ${orderId}     ${securityCode}
    Then The status code should be 200    ${jsonResult}[code]
    And the response should contain lessAmount  ${jsonResult}


    Then Customer Cashier use VA to pay using bank and Send request to getChannelFee API    token=${token}    securityCode=${securityCode}    bank=${bank}
    Then The status code should be 200  ${jsonResult}[code]
    And the response should contain channelFee and got totalInstallmentAmount   ${jsonResult}

    Then Customer Cashier click Next and Send request to slip/channel/process API    token=${token}  amount=${amount}    securityCode=${securityCode}     bank=${bank}
    Then The status code should be 200  ${jsonResult}[code]
    And the response should contain bizTransactionId    ${jsonResult}

    Then Send request to boss/payment/slip/list API to get referenceNo  bossToken=${bossToken}  paymentBillNo=${paymentBillNo}
    Then The status code should be 200  ${jsonResult}[code]
    And the response should contain referenceNo    ${jsonResult}


    Then I call the Mock VA Payment API to change the payment status to paid    token=${token}  amount=${totalInstallmentAmount}    referenceNo=${referenceNo}
    And the response should contain msg "COMPLETED"    ${jsonResult}

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
    property_order.I send the quotation request to savebinderrfq API    ${AP_POSITIVE_DATA}    ${token}
    assertUtil.The response should contain the value quoteNo and rfqNo    ${jsonResult}
    # 调用下单业务
    property_order.I send the place order request to createrfqorder API     ${AP_POSITIVE_DATA}    ${token}    ${rfqNo}    ${quoteNo}    ${isAdvancePremium}
    assertUtil.The response should contain the value orderNo and orderId    ${jsonResult}
    # 获取policy包含的slipUids
    getPolicyInfo.Send request to order/v2/slip/slipLs API to get slipUids    ${token}    ${orderId}
    getPolicyInfo.The response should contain slipUids    ${jsonResult}
    Log     ${orderNo}
    Log     ${orderId}
    Log     ${slipUids}
    Set Test Variable    ${token}
