
*** Settings ***
Library    RequestsLibrary
Library    Collections
Library    String
Library    XML
Library    SeleniumLibrary
Library    DateTime
Library    JSONLibrary

Resource    ../../../resources/biz/Login/login.robot
Resource    ../../../resources/api/order/saveBinderRfqOrder.robot
Resource    ../../../resources/api/order/createBinderOrder.robot
Resource    ../../../resources/api/payment/createPaymentBilling.robot
Resource    ../../../resources/api/payment/slip_process.robot
Resource    ../../../resources/api/payment/getChannelFee.robot
Resource    ../../../resources/api/order/getAvailableCoupon.robot
Resource    ../../../resources/api/payment/paymentBillingList.robot
Resource    ../../../resources/api/payment/new_slip_channel_process.robot
Resource    ../../../resources/util/utilCommon.robot
Resource    ../../../resources/biz/order/property/property_order.robot
Resource    ../../../resources/api/payment/mock/mockVA.robot

#Setup Test
#Suite Setup     Setup Data Testing
#Suite Teardown    Delete All Sessions


*** Variables ***
${BODY_FILE_PATH}    resources/data/property/QAPI-39_PlaceOrderData.json


*** Test Cases ***
VA_PartnerPay_SupernetPayment
    [Tags]    uat
    Given Setup Data Testing
    When I have an unpaid order and have logined
    Then I send request to createPaymentBilling API
    Then the status code should be 200
    Then I send request to paymentBillingList API
    Then the status code should be 200
    And the response should contain securityCode
    Then I choose Partner Pay & Supernet payment & VA payment method and send request to /slip/process API
    Then the status code should be 200
    And the response should contain lessAmount
    Then I choose bank BCA and send request to getChannelFee API
    Then the status code should be 200
    And the response should contain channelFee
    Then I click Next send request to slip/channel/process API
    Then the status code should be 200
    And the response should contain referenceNo
    Then I call the Mock VA Payment API to change the payment status
    And the response should contain msg "COMPLETED"
    Then finally Log the OrderNo



*** Keywords ***
Setup Data Testing
    ${AP_POSITIVE_DATA}=    Load JSON From File    ${BODY_FILE_PATH}
    Set Test Variable    ${AP_POSITIVE_DATA}
    Set Test Variable    ${bank}    BCA

I have an unpaid order and have logined
    # 调用登录接口
    ${token}  login.Login to Application using mobile
    # 调用下单业务
    ${orderInfo}    property_order.Property Order Pay Now without discount    ${token}
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


I choose Partner Pay & Supernet payment & VA payment method and send request to /slip/process API
    ${response}    slip_process.Send Request And Get Response Data    token=${token}    orderId=${orderId}    securityCode=${securityCode}  paymentScheme=3    payerType=2
    Set Test Variable    ${jsonResult}    ${response.json()}
    Log    ${jsonResult}


the response should contain lessAmount
    Should Contain    ${jsonResult}[data]   lessAmount


I choose bank BCA and send request to getChannelFee API
    ${response}    getChannelFee.Send Request And Get Response Data    token=${token}    securityCode=${securityCode}
    Set Test Variable    ${jsonResult}    ${response.json()}
    Log    ${jsonResult}


the response should contain channelFee
    Should Contain    ${jsonResult}[data]   channelFee
    Set Test Variable    ${amount}    ${jsonResult}[data][amount]

I click Next send request to slip/channel/process API
    ${response}    new_slip_channel_process.Send Request And Get Response Data    token=${token}    securityCode=${securityCode}    methodCode=9204     amount=${amount}

    Set Test Variable    ${jsonResult}    ${response.json()}
    Log    ${jsonResult}


the response should contain referenceNo
    Should Contain    ${jsonResult}[data][paymentDTO]   referenceNo
    Set Test Variable    ${referenceNo}     ${jsonResult}[data][paymentDTO][referenceNo]
    Log     ${referenceNo}


I call the Mock VA Payment API to change the payment status
    ${response}     mockVA.Send Request And Get Response Data        amount=${amount}    referenceNo=${referenceNo}

    Set Test Variable    ${jsonResult}    ${response.json()}
    Log    ${jsonResult}

the response should contain msg "COMPLETED"
    Should Be Equal As Strings    ${jsonResult}[status]    COMPLETED


the status code should be 200
    Log    ${jsonResult}
    Log    ${jsonResult}[code]
    Should Be Equal As Numbers    ${jsonResult}[code]    200

finally Log the OrderNo
    Log    ${orderNo}


