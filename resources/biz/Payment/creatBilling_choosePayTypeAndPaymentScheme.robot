*** Settings ***
Resource    ../../../resources/api/payment/createPaymentBilling.robot
Resource    ../../../resources/api/payment/paymentBillingList.robot
Resource    ../../../resources/api/payment/slip_process.robot
Resource    ../../../resources/api/payment/generate_Customer_payment_token.robot



*** Keywords ***
I continue to pay the order and send request the paymentBilling/create API
    [Arguments]     ${token}     ${orderNo}
    Sleep    3s
    ${response}    createPaymentBilling.Send Request And Get Response Data     token=${token}   orderNo=${orderNo}
    Set Test Variable    ${jsonResult}    ${response.json()}
    Log    ${jsonResult}

the response of paymentBilling/create API should contain securityCode
    [Arguments]     ${jsonResult}
    Should Contain    ${jsonResult}[data]   securityCode
    Set Test Variable    ${securityCode}    ${jsonResult}[data][securityCode]

Send request to paymentBillingList API
    [Arguments]     ${token}     ${orderId}
    ${response}    paymentBillingList.Send Request And Get Response Data    token=${token}    orderId=${orderId}
    Set Test Variable    ${jsonResult}    ${response.json()}
    Log    ${jsonResult}


the response of paymentBilling/List API should contain securityCode and paymentBillNo
    [Arguments]     ${jsonResult}
    Should Contain    ${jsonResult}[data][paymentBillingLs][0]   securityCode
    Set Test Variable    ${securityCode}    ${jsonResult}[data][paymentBillingLs][0][securityCode]
    Set Test Variable    ${paymentBillNo}    ${jsonResult}[data][paymentBillingLs][0][paymentBillNo]


I choose CutsomerPay and send request to generator/customer/payment/token API
    [Documentation]     Business operation: change to customer pay in cashier page
    [Arguments]     ${token}     ${securityCode}
    Log    ${securityCode}
    ${response}    generate_Customer_payment_token.Send Request And Get Response Data    token=${token}    securityCode=${securityCode}
    Set Test Variable    ${jsonResult}    ${response.json()}
    Log    ${jsonResult}

the response should contain customerToken
    [Arguments]     ${jsonResult}
    Should Contain    ${jsonResult}[data]    token
    Set Test Variable    ${token}    ${jsonResult}[data][token]
    Log    ${token}



#I choose PartnerPay & PaymentScheme & PaymentMethod and send request to /slip/process API
I choose PartnerPay & PaymentScheme & PaymentMethod and send request to /slip/process API
    [Documentation]     Business operation: choose PartnerPay and Payment Scheme and one payment method and click continue in cashier page
    [Arguments]     ${token}     ${orderId}     ${securityCode}    ${paymentScheme}    ${bonusDeduction}=0     ${pointsDeduction}=0     ${selectType}=2
    ${response}    slip_process.Send Request And Get Response Data    payerType=2    token=${token}    selectType=${selectType}    paymentScheme=${paymentScheme}      orderId=${orderId}    securityCode=${securityCode}       bonusDeduction=${bonusDeduction}     pointsDeduction=${pointsDeduction}

    Set Test Variable    ${jsonResult}    ${response.json()}
    Log    ${jsonResult}


I confirm to complete the payment using "CustomerPay FullPayment" and send the request to /slip/process API
    [Documentation]     Business operation: choose Customer Pay and click continue in cashier page
    [Arguments]     ${token}     ${orderId}     ${securityCode}
    ${response}    slip_process.Send Request And Get Response Data    payerType=1    token=${token}    selectType=2     paymentScheme=1  orderId=${orderId}    securityCode=${securityCode}

    Set Test Variable    ${jsonResult}    ${response.json()}
    Log    ${jsonResult}

the response should contain lessAmount
    [Arguments]     ${jsonResult}
    Should Contain    ${jsonResult}[data]   lessAmount
    Set Test Variable    ${amount}    ${jsonResult}[data][lessAmount]
    Log    ${amount}


Use Full Bonus and send the request to /slip/process API
    [Arguments]     ${token}     ${orderId}     ${securityCode}     ${PaymentScheme}
    ${response}  I choose PartnerPay & PaymentScheme & PaymentMethod and send request to /slip/process API     token=${token}     orderId=${orderId}     securityCode=${securityCode}     paymentScheme=${PaymentScheme}    selectType=1
    the response should contain lessAmount  ${jsonResult}
    ${response}  I choose PartnerPay & PaymentScheme & PaymentMethod and send request to /slip/process API     token=${token}     orderId=${orderId}     securityCode=${securityCode}     paymentScheme=${PaymentScheme}    bonusDeduction=${amount}



Use Full FusePoints and send the request to /slip/process API
    [Arguments]     ${token}     ${orderId}     ${securityCode}     ${PaymentScheme}
    ${response}  I choose PartnerPay & PaymentScheme & PaymentMethod and send request to /slip/process API     token=${token}     orderId=${orderId}     securityCode=${securityCode}     paymentScheme=${PaymentScheme}    selectType=1
    the response should contain lessAmount  ${jsonResult}
    ${response}  I choose PartnerPay & PaymentScheme & PaymentMethod and send request to /slip/process API     token=${token}     orderId=${orderId}     securityCode=${securityCode}     paymentScheme=${PaymentScheme}    pointsDeduction=${amount}



Use Full Bonus And FusePoints and send the request to /slip/process API
    [Arguments]     ${token}     ${orderId}     ${securityCode}     ${PaymentScheme}
    ${response}  I choose PartnerPay & PaymentScheme & PaymentMethod and send request to /slip/process API     token=${token}     orderId=${orderId}     securityCode=${securityCode}     paymentScheme=${PaymentScheme}    selectType=1
    the response should contain lessAmount  ${jsonResult}
    ${bonusDeduction}   Set Variable    1000
    ${pointsDeduction}  Evaluate    ${amount}-${bonusDeduction}
    ${response}  I choose PartnerPay & PaymentScheme & PaymentMethod and send request to /slip/process API     token=${token}     orderId=${orderId}     securityCode=${securityCode}     paymentScheme=${PaymentScheme}    bonusDeduction=${bonusDeduction}    pointsDeduction=${pointsDeduction}




the response should contain lessAmount and lessAmount should be 0
    [Arguments]     ${jsonResult}
    ${amount}    Get From Dictionary    ${jsonResult}[data]    lessAmount
    Should Be Equal As Numbers    ${amount}    0.0
    Log    ${amount}