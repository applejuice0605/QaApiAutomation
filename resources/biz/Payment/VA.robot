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
Customer Cashier use VA to pay using bank=${bank} and Send request to getChannelFee API
    [Documentation]     Business operation: choose bank in Customer Pay->Choose Bank Virtual Account Page
    [Arguments]    ${token}    ${securityCode}
    ${response}    getChannelFee.Send Request And Get Response Data    payerType=1    token=${token}    securityCode=${securityCode}    bank=${bank}    methodCode=9204
    Set Test Variable    ${jsonResult}    ${response.json()}
    Log    ${jsonResult}

Partner Cashier use VA to pay using bank=${bank} and Send request to getChannelFee API
    [Documentation]     Business operation: choose bank in Partner Pay->Choose Bank Virtual Account Page
    [Arguments]    ${token}    ${securityCode}
    ${response}    getChannelFee.Send Request And Get Response Data    payerType=2    token=${token}    securityCode=${securityCode}    bank=${bank}    methodCode=9204
    Set Test Variable    ${jsonResult}    ${response.json()}
    Log    ${jsonResult}


the response should contain channelFee and got totalInstallmentAmount
    [Arguments]    ${jsonResult}
    Should Contain    ${jsonResult}[data]   channelFee
    Set Test Variable    ${amount}    ${jsonResult}[data][amount]
    Set Test Variable    ${totalInstallmentAmount}    ${jsonResult}[data][totalInstallmentAmount]


Customer Cashier click Next and Send request to slip/channel/process API
    [Documentation]     Business operation: click Next in Customer Pay->Choose Bank Virtual Account Page after choosing bank
    [Arguments]     ${token}    ${amount}     ${securityCode}    ${bank}
    ${response}    slip_channel_process.Send Request And Get Response Data    payerType=1    token=${token}    securityCode=${securityCode}    methodCode=9204     amount=${amount}

    Set Test Variable    ${jsonResult}    ${response.json()}
    Log    ${jsonResult}

Partner Cashier click Next and Send request to slip/channel/process API
    [Documentation]     Business operation: click Next in Partner Pay->Choose Bank Virtual Account Page after choosing bank
    [Arguments]     ${token}    ${amount}     ${securityCode}    ${bank}
    ${response}    slip_channel_process.Send Request And Get Response Data    payerType=2    token=${token}    securityCode=${securityCode}    methodCode=9204     amount=${amount}

    Set Test Variable    ${jsonResult}    ${response.json()}
    Log    ${jsonResult}

the response should contain bizTransactionId
    [Arguments]     ${jsonResult}
    Should Contain    ${jsonResult}[data][paymentDTO]   bizTransactionId
    Set Test Variable    ${bizTransactionId}     ${jsonResult}[data][paymentDTO][bizTransactionId]
    Log     ${bizTransactionId}



Send request to boss/payment/slip/list API to get referenceNo
    [Arguments]    ${bossToken}    ${paymentBillNo}
    ${response}    boss_paymentSlipList.Send Request And Get Response Data    bossToken=${bossToken}    paymentBillNo=${paymentBillNo}
    Set Test Variable    ${jsonResult}    ${response.json()}
    Log    ${jsonResult}


the response should contain referenceNo
    [Arguments]    ${jsonResult}
    Log    ${jsonResult}
    Should Contain    ${jsonResult}[data][paymentSlipList][0]   referenceNo

#    循环检查${jsonResult}[data]，选择bizTransactionId=chananl/process返回的bizTransactionId的referenceNo
    ${len}  Get length    ${jsonResult}[data][paymentSlipList]
    Log     ${len}

    FOR    ${i}    IN RANGE    ${len}
        Log    ${i}
        ${element}    Get From List    ${jsonResult}[data][paymentSlipList]    ${i}
        Log    ${element}
        ${status}    Get From Dictionary    ${element}    status
        Log    ${status}
        IF    ${status} == 1
            ${referenceNo}    Get From Dictionary    ${element}    referenceNo
            Log    ${referenceNo}
            Set Test Variable    ${referenceNo}
            Exit For Loop
        END
    END

    Should Contain    ${jsonResult}[data][paymentSlipList][0]   referenceNo
    Log    ${referenceNo}


I call the Mock VA Payment API to change the payment status to paid
    [Arguments]    ${token}    ${amount}     ${referenceNo}
    ${response}    mockVA.Send Request And Get Response Data    token=${token}    amount=${amount}   referenceNo=${referenceNo}

    Set Test Variable    ${jsonResult}    ${response.json()}
    Log    ${jsonResult}

the response should contain msg "COMPLETED"
    [Arguments]     ${jsonResult}
    Should Be Equal As Strings    ${jsonResult}[status]    COMPLETED


