
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
${isAdvancePremium}     1
${payerType}    2
${paymentScheme}    1
${paymentMethod}    VA
${methodCode}   9204
${bank}     BCA
${bonusDeduction}   100
${pointsDeduction}  100000

*** Test Cases ***
VA PartnerPay SupernetPayment Property Order
    [Tags]    uat   VA
    Given Setup Data Testing
    When I have an unpaid order and have logined
    Then Run keyword And Continue on Failure    I continue to pay the order and send request the paymentBilling/create API     ${token}     ${orderNo}
    Then Run keyword And Continue on Failure    The status code should be 200    ${jsonResult}[code]

    Then Send request to paymentBillingList API     ${token}     ${orderId}
    Then The status code should be 200    ${jsonResult}[code]
    And the response of paymentBilling/List API should contain securityCode and paymentBillNo     ${jsonResult}

    Then I choose Partner Pay & Using Payment Scheme=${Payment Scheme} & paymentMethod=${paymentMethod} and send request to /slip/process API   token=${token}     paymentScheme=${paymentScheme}  orderId=${orderId}    securityCode=${securityCode}   bonusDeduction=${bonusDeduction}     pointsDeduction=${pointsDeduction}
    Then The status code should be 200    ${jsonResult}[code]
    And the response should contain lessAmount      ${jsonResult}

    Then Partner Cashier use VA to pay using bank=${bank} and Send request to getChannelFee API    ${token}    ${securityCode}
    Then The status code should be 200  ${jsonResult}[code]
    And the response should contain channelFee and got totalInstallmentAmount   ${jsonResult}

    Then Partner Cashier click Next and Send request to slip/channel/process API    token=${token}  amount=${amount}    securityCode=${securityCode}     bank=${bank}
    Then The status code should be 200  ${jsonResult}[code]
    And the response should contain bizTransactionId    ${jsonResult}

    Then Send request to boss/payment/slip/list API to get referenceNo  bossToken=${bossToken}  paymentBillNo=${paymentBillNo}
    Then The status code should be 200  ${jsonResult}[code]
    And the response should contain referenceNo    ${jsonResult}


    Then I call the Mock VA Payment API to change the payment status to paid    token=${token}  amount=${totalInstallmentAmount}    referenceNo=${referenceNo}
    And the response should contain msg "COMPLETED"    ${jsonResult}

    Then finally Log the OrderNo ${orderNo}



#
#
#*** Test Cases ***
#VA_UseBonusFusePoints_PartnerPay_FullPayment
#    [Tags]    uat
#    Given Setup Data Testing
#    When I have an unpaid order and have logined
#    Then I send request to createPaymentBilling API
#    Then the status code should be 200
#    Then Send request to paymentBillingList API
#    Then the status code should be 200
#    And the response of paymentBilling/create API should contain securityCode
#    Then I choose Partner Pay & Full payment & VA payment method and send request to /slip/process API
#    Then the status code should be 200
#    And the response should contain lessAmount
#    Then I choose bank BCA and send request to getChannelFee API
#    Then the status code should be 200
#    And the response should contain channelFee
#    Then Choose to pay in installment=${installmentNumber} and Click Next and send request to slip/channel/process API
#    Then the status code should be 200
#    And the response should contain referenceNo
#    Then I call the Mock VA Payment API to change the payment status
#    And the response should contain msg "COMPLETED"
#    Then finally Log the OrderNo



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
#
#I send request to createPaymentBilling API
#    Sleep    3s
#    ${response}    createPaymentBilling.Send Request And Get Response Data     token=${token}   orderNo=${orderNo}
#
#    Set Test Variable    ${jsonResult}    ${response.json()}
#    Log    ${jsonResult}
#
#
#
#Send request to paymentBillingList API
#    ${response}    paymentBillingList.Send Request And Get Response Data    token=${token}    orderId=${orderId}
#    Set Test Variable    ${jsonResult}    ${response.json()}
#    Log    ${jsonResult}
#
#the response of paymentBilling/create API should contain securityCode
#    Should Contain    ${jsonResult}[data][paymentBillingLs][0]   securityCode
#    Set Test Variable    ${securityCode}    ${jsonResult}[data][paymentBillingLs][0][securityCode]
#
#
#I choose Partner Pay & Full payment & VA payment method and send request to /slip/process API
#    ${response}    slip_process.Send Request And Get Response Data    token=${token}    orderId=${orderId}    securityCode=${securityCode}  paymentScheme=${paymentScheme}    payerType=${payerType}   bonusDeduction=${bonusDeduction}     pointsDeduction=${pointsDeduction}
#    Set Test Variable    ${jsonResult}    ${response.json()}
#    Log    ${jsonResult}
#
#
#
#
#
#
#the response should contain lessAmount
#    Should Contain    ${jsonResult}[data]   lessAmount
#
#
#I choose bank BCA and send request to getChannelFee API
#    ${response}    getChannelFee.Send Request And Get Response Data    token=${token}    securityCode=${securityCode}
#    Set Test Variable    ${jsonResult}    ${response.json()}
#    Log    ${jsonResult}
#
#
#the response should contain channelFee
#    Should Contain    ${jsonResult}[data]   channelFee
#    Set Test Variable    ${amount}    ${jsonResult}[data][amount]
#
#Choose to pay in installment=${installmentNumber} and Click Next and send request to slip/channel/process API
#    ${response}    new_slip_channel_process.Send Request And Get Response Data    token=${token}    securityCode=${securityCode}    methodCode=${methodCode}     amount=${amount}
#
#    Set Test Variable    ${jsonResult}    ${response.json()}
#    Log    ${jsonResult}
#
#
#the response should contain referenceNo
#    Should Contain    ${jsonResult}[data][paymentDTO]   referenceNo
#    Set Test Variable    ${referenceNo}     ${jsonResult}[data][paymentDTO][referenceNo]
#    Log     ${referenceNo}
#
#
#I call the Mock VA Payment API to change the payment status
#    ${response}     mockVA.Send Request And Get Response Data        amount=${amount}    referenceNo=${referenceNo}
#
#    Set Test Variable    ${jsonResult}    ${response.json()}
#    Log    ${jsonResult}
#
#the response should contain msg "COMPLETED"
#    Should Be Equal As Strings    ${jsonResult}[status]    COMPLETED
#
#
#the status code should be 200
#    Log    ${jsonResult}
#    Log    ${jsonResult}[code]
#    Should Be Equal As Numbers    ${jsonResult}[code]    200
#
#finally Log the OrderNo
#    Log    ${orderNo}
#
#
