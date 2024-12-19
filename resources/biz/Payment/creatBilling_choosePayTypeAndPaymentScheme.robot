*** Settings ***
Resource    ../../../resources/api/payment/createPaymentBilling.robot
Resource    ../../../resources/api/payment/slip_process.robot
Resource    ../../../resources/api/payment/getChannelFee.robot


*** Keywords ***
I continue to pay the order and send request the create paymentBilling API
    [Arguments]     ${token}     ${orderNo}
    Sleep    3s
    ${response}    createPaymentBilling.Send Request And Get Response Data     token=${token}   orderNo=${orderNo}
    Set Test Variable    ${jsonResult}    ${response.json()}
    Log    ${jsonResult}



I choose partner pay & Net payment & a payment method amd send request to /slip/process API
    [Arguments]     ${token}     ${orderId}     ${securityCode}    ${paymentScheme}    ${payerType}
    ${response}    slip_process.Send Request And Get Response Data    token=${token}    orderId=${orderId}    securityCode=${securityCode}  paymentScheme=${paymentScheme}    payerType=${payerType}
    Set Test Variable    ${jsonResult}    ${response.json()}
    Log    ${jsonResult}


I click continue and send request to getChannelFee API
    [Arguments]     ${token}     ${securityCode}
    ${response}    getChannelFee.Send Request And Get Response Data    token=${token}    securityCode=${securityCode}

