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

Resource    ../../../resources/api/payment/slip_channel_process.robot
Resource    ../../../resources/api/payment/getChannelFee.robot
Resource    ../../../resources/api/payment/boss_paymentSlipList.robot

Resource    ../../../resources/api/payment/mock/mockVA.robot

*** Keywords ***
Customer Cashier use OVO to pay and Send request to getChannelFee API
    [Documentation]     Business operation:
    [Arguments]    ${token}    ${securityCode}
    ${response}    getChannelFee.Send Request And Get Response Data    payerType=1    token=${token}    securityCode=${securityCode}    methodCode=9203
    Set Test Variable    ${jsonResult}    ${response.json()}
    Log    ${jsonResult}

Partner Cashier use OVO to pay and Send request to getChannelFee API
    [Documentation]     Business operation: choose OVO in cashier and click next
    [Arguments]    ${token}    ${securityCode}
    ${response}    getChannelFee.Send Request And Get Response Data    payerType=2    token=${token}    securityCode=${securityCode}    methodCode=9203
    Set Test Variable    ${jsonResult}    ${response.json()}
    Log    ${jsonResult}


the response should contain channelFee and got totalInstallmentAmount
    [Arguments]    ${jsonResult}
    Should Contain    ${jsonResult}[data]   channelFee
    Set Test Variable    ${amount}    ${jsonResult}[data][amount]
    Set Test Variable    ${totalInstallmentAmount}    ${jsonResult}[data][totalInstallmentAmount]


Customer Cashier confirm complete to pay and Send request to slip/channel/process API
    [Documentation]    Business operation: input mobile number and click next in Customer Pay->Choose Bank Virtual Account Page after choosing bank
    [Arguments]     ${token}    ${amount}    ${securityCode}
    ${response}    slip_channel_process.Send Request And Get Response Data    payerType=1    token=${token}    securityCode=${securityCode}    methodCode=9203     amount=${amount}

    Set Test Variable    ${jsonResult}    ${response.json()}
    Log    ${jsonResult}

Partner Cashier confirm complete to pay and Send request to slip/channel/process API
    [Documentation]     Business operation: click Next in Partner Pay->Choose Bank Virtual Account Page after choosing bank
    [Arguments]     ${token}    ${amount}    ${securityCode}
    ${response}    slip_channel_process.Send Request And Get Response Data    payerType=2    token=${token}    securityCode=${securityCode}    methodCode=9203     amount=${amount}

    Set Test Variable    ${jsonResult}    ${response.json()}
    Log    ${jsonResult}

the response should contain bizTransactionId
    [Arguments]     ${jsonResult}
    Should Contain    ${jsonResult}[data][paymentDTO]   bizTransactionId
    Set Test Variable    ${bizTransactionId}     ${jsonResult}[data][paymentDTO][bizTransactionId]
    Log     ${bizTransactionId}


