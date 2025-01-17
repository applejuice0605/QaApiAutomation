*** Settings ***
Library    RequestsLibrary
Library    Collections
Library    String
Library    XML
Library    SeleniumLibrary
Library    DateTime
Library    JSONLibrary

Resource    ../../../resources/api/payment/createPaymentBilling.robot
Resource    ../../../resources/api/payment/paymentBillingList.robot
Resource    ../../../resources/api/payment/paymentBilling_info.robot
Resource    ../../../resources/api/payment/slip_channel_process.robot
Resource    ../../../resources/api/payment/getChannelFee.robot
Resource    ../../../resources/api/payment/boss_paymentSlipList.robot

Resource    ../../../resources/api/payment/mock/mockGoPay.robot

*** Keywords ***
Customer Cashier confirm complete to pay using GoPay and Send request to slip/channel/process API
    [Documentation]    Business operation: input mobile number and click next in Customer Pay->Choose Bank Virtual Account Page after choosing bank
    [Arguments]     ${token}    ${amount}    ${securityCode}
    ${response}    slip_channel_process.Send Request And Get Response Data    payerType=1    token=${token}    securityCode=${securityCode}    methodCode=9201    amount=${amount}

    Set Test Variable    ${jsonResult}    ${response.json()}
    Log    ${jsonResult}

Partner Cashier confirm complete to pay using GoPay and Send request to slip/channel/process API
    [Documentation]     Business operation: click Next in Partner Pay->Choose Bank Virtual Account Page after choosing bank
    [Arguments]     ${token}    ${amount}    ${securityCode}
    ${response}    slip_channel_process.Send Request And Get Response Data    payerType=2    token=${token}    securityCode=${securityCode}    methodCode=9201     amount=${amount}

    Set Test Variable    ${jsonResult}    ${response.json()}
    Log    ${jsonResult}

the response should contain referenceNo
    [Documentation]     断言，并返回后续数据：amount, referenceNo
    [Arguments]     ${jsonResult}
    Should Contain    ${jsonResult}[data][paymentDTO]   bizTransactionId
    Set Test Variable    ${referenceNo}     ${jsonResult}[data][paymentDTO][referenceNo]
    Set Test Variable    ${amount}      ${jsonResult}[data][paymentDTO][amount]
    Set Test Variable    ${payment_slip_no}      ${jsonResult}[data][paymentDTO][bizTransactionId]
    Log     ${referenceNo}
    Log     ${amount}



Send request to paymentBilling/info API to get paymentSlipNo
    [Arguments]     ${bossToken}    ${paymentBillNo}
    ${response}    paymentBilling_info.Send Request And Get Response Data   bossToken=${bossToken}   paymentBillNo=${paymentBillNo}
    Set Test Variable    ${jsonResult}    ${response.json()}
    Log    ${jsonResult}



the response should contain paymentSlipNo
    [Documentation]     断言，并返回后续数据：paymentSlipNo
    [Arguments]     ${jsonResult}
    Log    ${jsonResult}[data][slipLs][0]
    Should Contain    ${jsonResult}[data][slipLs][0]   paymentSlipNo
    Set Test Variable    ${paymentSlipNo}     ${jsonResult}[data][slipLs][0][paymentSlipNo]



I call the Mock GoPay Payment API to change the payment status to paid
    [Arguments]    ${amount}     ${referenceNo}     ${payment_slip_no}
    Log    ${amount}
    # goPay_paymentGetWayFee根据不同的产品会不一样，优化：动态获取gatewayFee
    ${goPay_paymentGetWayFee}=   Set Variable      8885
    ${gross_amount}=   Evaluate    ${amount}+${goPay_paymentGetWayFee}
    ${response}    mockGoPay.Send Request And Get Response Data    gross_amount=${gross_amount}   reference_no=${referenceNo}    payment_slip_no=${payment_slip_no}

    Set Test Variable    ${jsonResult}    ${response.json()}
    Log    ${jsonResult}




