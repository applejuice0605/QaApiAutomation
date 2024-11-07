*** Settings ***
Library    RequestsLibrary
Library    Collections
Library    String
Library    XML
Library    SeleniumLibrary
Library    DateTime
Library    JSONLibrary

Resource    ../../../resources/biz/Login/login.robot
Resource    ../../../resources/biz/order/travel_order.robot

Resource    ../../../resources/api/order/saveBinderRfqOrder.robot
Resource    ../../../resources/api/order/createBinderOrder.robot
Resource    ../../../resources/api/payment/createPaymentBilling.robot
Resource    ../../../resources/api/payment/slip_process.robot
Resource    ../../../resources/api/payment/getChannelFee.robot
Resource    ../../../resources/api/payment/getInstallmentPlan.robot


Resource    ../../../resources/api/payment/paymentBillingList.robot
Resource    ../../../resources/api/order/getAvailableCoupon.robot
Resource    ../../../resources/api/payment/paymentBillingList.robot
Resource    ../../../resources/api/payment/new_slip_channel_process.robot
Resource    ../../../resources/util/utilCommon.robot

Resource    ../../../resources/api/payment/mock/mockCC.robot

Resource    ../../../resources/util/utilCommon.robot


#Setup Test
#Suite Setup     Setup Data Testing
#Suite Teardown    Finally Log the orderNo    ${orderNo}


*** Variables ***
${methodCode}   9202
${paymentScheme}    1
${payerType}    2
${bonusDeduction}   100
${pointsDeduction}  100000

*** Test Cases ***
CC UseBonusFusePoints_PartnerPay_FullPayment
    [Tags]    uat
    Given I have an unpaid order and have logined
    When I send request to createPaymentBilling API
    Then the status code should be 200
    Then I send request to paymentBillingList API
    Then the status code should be 200
    And the response should contain securityCode
    Then I choose Partner Pay & Net payment & CC payment method and send request to /slip/process API
    Then the status code should be 200
    And the response should contain lessAmount

    Then Send request to getInstallmentPlan API
    Then the status code should be 200
    And the response should contain installmentSchemaDTOList

    Then I click Next send request to slip/channel/process API
    Then the status code should be 200
    And the response should contain referenceNo

    Then I call the Mock CC Payment API to change the payment status
    And the status code should be 200
    Then finally Log the OrderNo



*** Keywords ***

I have an unpaid order and have logined
    # 调用登录接口
    ${token}  login.Login to Application using mobile
    # 调用下单业务
    ${orderInfo}    travel_order.Travel Order Pay Now without discount    ${token}
    Log     ${orderInfo}
    Set Test Variable    ${orderNo}    ${orderInfo[0]}
    Set Test Variable    ${orderId}    ${orderInfo[1]}
    Set Test Variable    ${token}

I send request to createPaymentBilling API
    Sleep    3s
    ${response}    createPaymentBilling.Send Request And Get Response Data     token=${token}   orderNo=${orderNo}

    Set Test Variable    ${jsonResult}    ${response.json()}
    Log    ${jsonResult}



I send request to paymentBillingList API
    ${response}    paymentBillingList.Send Request And Get Response Data    token=${token}    orderId=${orderId}
    Set Test Variable    ${jsonResult}    ${response.json()}
    Log    ${jsonResult}

the response should contain securityCode
    Should Contain    ${jsonResult}[data][paymentBillingLs][0]   securityCode
    Set Test Variable    ${securityCode}    ${jsonResult}[data][paymentBillingLs][0][securityCode]



I choose Partner Pay & Net payment & CC payment method and send request to /slip/process API
    ${response}    slip_process.Send Request And Get Response Data    token=${token}    orderId=${orderId}    securityCode=${securityCode}  paymentScheme=${paymentScheme}    payerType=${payerType}    bonusDeduction=${bonusDeduction}     pointsDeduction=${pointsDeduction}
    Set Test Variable    ${jsonResult}    ${response.json()}
    Log    ${jsonResult}


the response should contain lessAmount
    Should Contain    ${jsonResult}[data]   lessAmount


send request to getInstallmentPlan API
    ${response}    getInstallmentPlan.Send Request And Get Response Data    token=${token}    securityCode=${securityCode}
    Set Test Variable    ${jsonResult}    ${response.json()}
    Log    ${jsonResult}



the response should contain installmentSchemaDTOList
    Should Contain    ${jsonResult}[data]    installmentSchemaDTOList

    #1. 选择分期
    ${installmentSchemaDTOList}    Get From Dictionary    ${jsonResult}[data]    installmentSchemaDTOList
    #2. 选择分期: 索引0：不分期，1：分3期，2：分6期，3：分12期
    Set Test Variable    ${installmentNumber}   1
    ${amount}=   Get Installment Amount     ${installmentSchemaDTOList}    ${installmentNumber}
    Set Test Variable    ${amount}



I click Next send request to slip/channel/process API
    Log     ${amount}
    ${response}    new_slip_channel_process.Send Request And Get Response Data    token=${token}    securityCode=${securityCode}    methodCode=${methodCode}     amount=${amount}     installmentNumber=${installmentNumber}

    Set Test Variable    ${jsonResult}    ${response.json()}
    Log    ${jsonResult}


the response should contain referenceNo
    Should Contain    ${jsonResult}[data][paymentDTO]   referenceNo
    #获取referenceNo
    Set Test Variable    ${referenceNo}     ${jsonResult}[data][paymentDTO][referenceNo]
    #获取channelFee
    ${channelFee}  Set Variable    ${jsonResult}[data][gatewayDTO][paymentChannelFeeSchemaDTO][channelFee]
    #获取amount
    ${amount}   Set Variable    ${jsonResult}[data][gatewayDTO][paymentChannelFeeSchemaDTO][amount]
    #获取transactionAmount
    ${amount}   Evaluate    (${channelFee}+${amount})
    Set Test Variable    ${transactionAmount}       ${amount}
    Log     ${referenceNo}
    Log     ${transactionAmount}



I call the Mock CC Payment API to change the payment status
    Sleep    3s
    ${response}     mockCC.Send Request And Get Response Data        transactionAmount=${transactionAmount}    reference_no=${referenceNo}

    Set Test Variable    ${jsonResult}    ${response.json()}
    Log    ${jsonResult}


the status code should be 200
    Log    ${jsonResult}
    Log    ${jsonResult}[code]
    Should Be Equal As Numbers    ${jsonResult}[code]    200

finally Log the OrderNo
    Log    ${orderNo}