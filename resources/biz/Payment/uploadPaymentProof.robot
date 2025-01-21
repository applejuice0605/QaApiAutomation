*** Settings ***
Library    RequestsLibrary
Library    Collections
Library    String
Library    XML
Library    SeleniumLibrary
Library    DateTime
Library    JSONLibrary

Resource    ../../../resources/api/PaymentBillingFlow/boss_paymentBillling_list.robot



Resource    ../../../resources/api/PaymentBillingFlow/boss_partner_payment_uploadProof.robot


Resource    ../../../resources/api/payment/paymentBillingList.robot
Resource    ../../../resources/api/payment/generate_Customer_payment_token.robot

Resource    ../../../resources/api/payment/getInstallmentPlan.robot
Resource    ../../../resources/api/payment/slip_channel_process.robot
Resource    ../../../resources/api/payment/mock/mockCC.robot

*** Keywords ***
Send Request To paymentBilling/list API to get paymentBillingNo
    [Documentation]     Business operation: search orderNo in Billing List
    [Arguments]     ${token}    ${orderNo}
    ${response}    paymentBillingList.Send Request And Get Response Data    ${token}    ${orderNo}
    Set Test Variable    ${jsonResult}    ${response.json()}
    Log    ${jsonResult}

the response should contain paymentBillingNo
    [Arguments]     ${jsonResult}
    Should Not Be Empty    ${jsonResult}[data][data][0][paymentBillNo]
    Set Test Variable    name
    


#Send Request To underwritingV2/list/manager API to
















#Customer Cashier use CC to pay and Send request to getInstallmentPlan API
#    [Documentation]     Business operation: got the installment plan
#    [Arguments]     ${token}    ${securityCode}
#    ${response}    getInstallmentPlan.Send Request And Get Response Data    payerType=1     token=${token}    securityCode=${securityCode}
#    Set Test Variable    ${jsonResult}    ${response.json()}
#    Log    ${jsonResult}
#
#Partner Cashier use CC to pay and Send request to getInstallmentPlan API
#    [Documentation]     Business operation: got the installment plan
#    [Arguments]     ${token}    ${securityCode}
#    ${response}    getInstallmentPlan.Send Request And Get Response Data    payerType=2     token=${token}    securityCode=${securityCode}
#    Set Test Variable    ${jsonResult}    ${response.json()}
#    Log    ${jsonResult}
#
#
#the response should contain installmentSchemaDTOList
#    [Documentation]    choose installment plan and get amount and default set installmentNumber=0
#    [Arguments]     ${token}    ${installmentNumber}=0
#    Should Contain    ${jsonResult}[data]    installmentSchemaDTOList
#
#    #1. 选择分期
#    ${installmentSchemaDTOList}    Get From Dictionary    ${jsonResult}[data]    installmentSchemaDTOList
#    #2. 选择分期: 索引0：不分期，1：分3期，2：分6期，3：分12期
#    Set Test Variable    ${installmentNumber}   ${installmentNumber}
#    Log    ${installmentNumber}
#    ${amount}=   Get Installment Amount     ${installmentSchemaDTOList}    ${installmentNumber}
#    Set Test Variable    ${amount}
#
#
#
#Customer Cashier Choose to pay in installment=${installmentNumber} and Click Next and send request to slip/channel/process API
#    [Arguments]     ${token}    ${securityCode}    ${methodCode}    ${installmentNumber}
#    Log     ${amount}
#    ${response}    slip_channel_process.Send Request And Get Response Data    payerType=1     token=${token}    securityCode=${securityCode}    methodCode=${methodCode}     amount=${amount}     installmentNumber=${installmentNumber}
#
#    Set Test Variable    ${jsonResult}    ${response.json()}
#    Log    ${jsonResult}
#
#
#Partner Cashier Choose to pay in installment=${installmentNumber} and Click Next and send request to slip/channel/process API
#    [Arguments]     ${token}    ${securityCode}    ${methodCode}    ${installmentNumber}
#    Log     ${amount}
#    ${response}    slip_channel_process.Send Request And Get Response Data    payerType=2     token=${token}    securityCode=${securityCode}    methodCode=${methodCode}     amount=${amount}     installmentNumber=${installmentNumber}
#
#    Set Test Variable    ${jsonResult}    ${response.json()}
#    Log    ${jsonResult}
#
#
#the response should contain referenceNo
#    [Arguments]     ${jsonResult}
#    Should Contain    ${jsonResult}[data][paymentDTO]   referenceNo
#    #获取referenceNo
#    Set Test Variable    ${referenceNo}     ${jsonResult}[data][paymentDTO][referenceNo]
#    #获取channelFee
#    ${channelFee}  Set Variable    ${jsonResult}[data][gatewayDTO][paymentChannelFeeSchemaDTO][channelFee]
#    #获取amount
#    ${amount}   Set Variable    ${jsonResult}[data][gatewayDTO][paymentChannelFeeSchemaDTO][amount]
#    #获取transactionAmount
#    ${amount}   Evaluate    (${channelFee}+${amount})
#    Set Test Variable    ${transactionAmount}       ${amount}
#    Log     ${referenceNo}
#    Log     ${transactionAmount}
#
#
#
#I call the Mock CC Payment API to change the payment status
#    [Arguments]     ${transactionAmount}     ${referenceNo}
#    Sleep    3s
#    ${response}     mockCC.Send Request And Get Response Data        transactionAmount=${transactionAmount}    reference_no=${referenceNo}
#
#    Set Test Variable    ${jsonResult}    ${response.json()}
#    Log    ${jsonResult}


