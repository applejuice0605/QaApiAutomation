*** Settings ***
Resource    ../../../resources/api/payment/createPaymentBilling.robot
Resource    ../../../resources/api/payment/paymentBillingList.robot
Resource    ../../../resources/api/payment/slip_process.robot
Resource    ../../../resources/api/payment/generate_Customer_payment_token.robot




*** Keywords ***
I try to get paymentBilling Info and securityCode
    [Documentation]     尝试调用createPaymentBilling接口，接口失败则调用paymentBillingList接口获取paymentBillNo和securityCode
    [Arguments]     ${token}     ${orderNo}    ${orderId}
    # 1. 尝试调用createPaymentBilling接口，接口失败则调用paymentBillingList接口获取paymentBillNo和securityCode
    Sleep    5s
    ${response}    createPaymentBilling.Send Request And Get Response Data     token=${token}   orderNo=${orderNo}
    ${jsonResult}=    Set Variable    ${response.json()}
    
    # 1.1 获取接口响应中的message
    ${message}=    Get From Dictionary    ${jsonResult}   message    default=${None}
    Log    ${message}
    IF    '${message}' == 'There is payment in transit'
        ${securityCode}=    Set Variable    ${None}
    ELSE
        # 从createPaymentBilling接口响应中获取securityCod
        ${securityCode}=    Get From Dictionary    ${jsonResult}[data]   securityCode    default=${None}
        ${paymentBillNo}=    Get From Dictionary    ${jsonResult}[data]   paymentBillNo    default=${None}
    END
    
    # 3. 如果securityCode为空，则调用paymentBillingList接口获取securityCode
    IF    '${securityCode}' == '${None}'
        Log    securityCode is empty, try to get from paymentBillingList API
        ${response}    Send request to paymentBillingList API    token=${token}    orderId=${orderId}
        ${securityCode}=    Get From Dictionary    ${jsonResult}[data][paymentBillingLs][0]   securityCode
        ${paymentBillNo}=    Get From Dictionary    ${jsonResult}[data][paymentBillingLs][0]   paymentBillNo
        Log    ${securityCode}
        
    END
    Set Test Variable    ${securityCode}    ${securityCode}
    Set Test Variable    ${paymentBillNo}    ${paymentBillNo}
    RETURN    ${securityCode}



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
    Set Test Variable    ${customerToken}    ${jsonResult}[data][token]
    Log    ${customerToken}



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