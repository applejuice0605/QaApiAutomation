*** Settings ***
Library    RequestsLibrary
Library    Collections
Library    String
Library    XML
Library    SeleniumLibrary
Library    DateTime
Library    JSONLibrary

Resource    ../../../resources/api/PaymentBillingFlow/boss_paymentBillling_list.robot
Resource    ../../../resources/api/PaymentBillingFlow/boss_paymentBillling_details.robot
Resource    ../../../resources/api/PaymentBillingFlow/boss_paymentBillling_info.robot
Resource    ../../../resources/api/PaymentBillingFlow/uploadPaymentProof.robot
Resource    ../../../resources/api/PaymentBillingFlow/paymentBilling_list_manager.robot
Resource    ../../../resources/api/PaymentBillingFlow/paymentBilling_list_todo.robot
Resource    ../../../resources/api/PaymentBillingFlow/paymentBilling_list_manager.robot

Resource    ../../../resources/api/underwriting/assignToMe.robot
Resource    ../../../resources/api/underwriting/approval.robot




*** Keywords ***
Send Request To paymentBilling/list API to get paymentBillingNo
    [Documentation]     Business operation: search orderNo in Billing List
    [Arguments]     ${bossToken}    ${multiFieldQuery}
    Sleep    3s
    ${response}    boss_paymentBillling_list.Send Request And Get Response Data    ${bossToken}    ${multiFieldQuery}
    Set Test Variable    ${jsonResult}    ${response.json()}
    Log    ${jsonResult}

the response should contain paymentBillingNo
    [Arguments]     ${jsonResult}
    Should Not Be Empty    ${jsonResult}[data][data][0][paymentBillNo]
    Set Test Variable    ${paymentBillNo}    ${jsonResult}[data][data][0][paymentBillNo]






Send Request To payment/billing/details API to get actualPayableAmount
    [Documentation]     Business operation: choose payment scheme and payer type when upload payment proof
    [Arguments]     ${bossToken}    ${paymentBillNo}    ${paymentScheme}=1    ${payerType}=2
    ${response}    boss_paymentBillling_details.Send Request And Get Response Data    ${bossToken}    ${paymentBillNo}

    #根据paymentScheme和payerType获取actualPaymentAmount
    IF  ${payerType} == 1
         ${bizSchemeAmount}   Set Variable    ${response.json()}[data][payerTypeSchemes][0][bizSchemeAmount]
    ELSE IF  ${payerType} == 2
         ${bizSchemeAmount}   Set Variable    ${response.json()}[data][payerTypeSchemes][1][bizSchemeAmount]
    END
    Log    ${bizSchemeAmount}

    FOR    ${item}    IN    @{bizSchemeAmount}
        Log    ${item}
        IF  ${item}[code] == ${paymentScheme}
            ${actualPayableAmount}   Set Variable    ${item}[amount]
            BREAK
        END
    END
    Log    ${actualPayableAmount}
    RETURN    ${actualPayableAmount}



Send Request To uploadProof API to upload payment proof
    [Documentation]     Business operation: upload payment proof from Boss
    [Arguments]     ${AP_POSITIVE_DATA}     ${bossToken}    ${paymentBillNo}    ${actualPayableAmount}  ${actualPaymentAmount}

    Log    ${actualPayableAmount}
    Log    ${actualPaymentAmount}
    # 1. 获取上传支付凭证的jsonBody
    ${jsonBody}     Set Variable    ${AP_POSITIVE_DATA["uploadPaymentProof"]}
    # 2. updateJsonBody
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.paymentBillNo    ${paymentBillNo}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.uploadProofLs[0].amount    ${actualPaymentAmount}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.transactionAmount    ${actualPaymentAmount}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.transferAmount    ${actualPayableAmount}
    Log     ${jsonBody}
    # 3. convert jsonBody to string
    ${strBody}  Convert Json To String    ${jsonBody}
    # 4. send request
    ${response}    uploadPaymentProof.Send Request And Get Response Data    ${bossToken}    ${strBody}
    ${jsonResult}    Set Variable    ${response.json()}
    Log    ${jsonResult}
    RETURN    ${jsonResult}


Send Request To uploadProof API to upload payment proof with no overpayment
    [Arguments]     ${AP_POSITIVE_DATA}     ${bossToken}    ${paymentBillNo}
    # 1. 获取actualPayableAmount
    ${actualPayableAmount}=     Send Request To payment/billing/details API to get actualPayableAmount     bossToken=${bossToken}    paymentBillNo=${paymentBillNo}
    Set Test Variable    ${actualPayableAmount}     ${actualPayableAmount}

    # 2. 准备请求数据
    ${actualPaymentAmount}  Set Variable    ${actualPayableAmount}
    Set Test Variable    ${actualPaymentAmount}   ${actualPaymentAmount}
    ${jsonResult}=  Send Request To uploadProof API to upload payment proof     AP_POSITIVE_DATA=${AP_POSITIVE_DATA}     bossToken=${bossToken}    paymentBillNo=${paymentBillNo}    actualPayableAmount=${actualPayableAmount}     actualPaymentAmount=${actualPaymentAmount}

    Set Test Variable    ${jsonResult}   ${jsonResult}


Send Request To uploadProof API to upload payment proof with overpayment
    [Arguments]     ${AP_POSITIVE_DATA}     ${bossToken}    ${paymentBillNo}      ${overpaymentAmount}
    # 1. 获取actualPayableAmount
    Set Test Variable    ${overpaymentAmount}   ${overpaymentAmount}
    ${actualPayableAmount}=     Send Request To payment/billing/details API to get actualPayableAmount     bossToken=${bossToken}    paymentBillNo=${paymentBillNo}
    ${actualPayableAmount}  Evaluate    int(${actualPayableAmount})
    Set Test Variable    ${actualPayableAmount}     ${actualPayableAmount}

    # 2. 准备请求数据
    ${actualPaymentAmount}=    Evaluate    ${actualPayableAmount}+${overpaymentAmount}
#    ${actualPaymentAmount}=    Evaluate    sum(${actualPayableAmount}, ${overpaymentAmount})
    Log    ${actualPaymentAmount}
    Set Test Variable    ${actualPaymentAmount}   ${actualPaymentAmount}

    ${jsonResult}=  Send Request To uploadProof API to upload payment proof     AP_POSITIVE_DATA=${AP_POSITIVE_DATA}     bossToken=${bossToken}    paymentBillNo=${paymentBillNo}    actualPayableAmount=${actualPayableAmount}     actualPaymentAmount=${actualPaymentAmount}
    Set Test Variable    ${jsonResult}   ${jsonResult}





Send Request To paymentBilling_list_manager API to get payment billing taskId in Payment Billing Mgt List
    [Documentation]     Business operation: search orderNo in TaskMgt>>Payment Billing Mgt List
    [Arguments]     ${bossToken}    ${multiFieldQuery}   ${existsAssignee}
    Sleep    10s
    ${response}    paymentBilling_list_manager.Send Request And Get Response Data    ${bossToken}    ${multiFieldQuery}     ${existsAssignee}
    Set Test Variable    ${jsonResult}    ${response.json()}
    Log    ${jsonResult}
    
the response should contain taskId
    [Arguments]     ${jsonResult}
    Should Not Be Empty    ${jsonResult}[data][data][0][id]
    Set Test Variable    ${taskId}    ${jsonResult}[data][data][0][id]
    Log    ${taskId}

Assigne Task to me
    [Documentation]     Business operation: assign task to me
    [Arguments]     ${bossToken}    ${taskId}
    ${taskIds}  Create List
    Append To List    ${taskIds}    ${taskId}
    Log     ${taskIds}

    ${response}    assignToMe.Send Request And Get Response Data    ${bossToken}    ${taskIds}
    Set Test Variable    ${jsonResult}    ${response.json()}
    Log    ${jsonResult}


Send Request To paymentBilling_list_todo API to get payment billing taskId in Payment Billing Flow List
    [Documentation]     Business operation: search orderNo in Task>>Payment Billing Flow List
    [Arguments]     ${bossToken}    ${multiFieldQuery}
    Sleep    10s
    ${response}    paymentBilling_list_todo.Send Request And Get Response Data    ${bossToken}    ${multiFieldQuery}
    Set Test Variable    ${jsonResult}    ${response.json()}
    Log    ${jsonResult}


Send Request To paymentBilling_info API to get PamentBilling id&No and slipNo and referNo
    [Arguments]     ${bossToken}    ${paymentBillNo}
    ${response}    boss_paymentBillling_info.Send Request And Get Response Data    ${bossToken}    ${paymentBillNo}
    Set Test Variable    ${paymentBillingId}    ${response.json()}[data][slipLs][0][paymentBillingId]
    Set Test Variable    ${paymentBillingNo}    ${response.json()}[data][slipLs][0][paymentBillingNo]
    Set Test Variable    ${paymentSlipNo}    ${response.json()}[data][slipLs][0][paymentSlipNo]
    Set Test Variable    ${referenceNo}    ${response.json()}[data][slipLs][0][referenceNo]



Approve Payment Billing Task
    [Documentation]     Business operation: approve payment billing task in Task>>Payment Billing Flow List
    [Arguments]     ${AP_POSITIVE_DATA}     ${bossToken}    ${paymentBillNo}    ${taskId}    ${actualPayableAmount}     ${actualPaymentAmount}  ${overpaymentAmount}=0

    Send Request To paymentBilling_info API to get PamentBilling id&No and slipNo and referNo     ${bossToken}    ${paymentBillNo}

    #1. 获取上传支付凭证的jsonBody
    ${jsonBody}     Set Variable    ${AP_POSITIVE_DATA["uploadPaymentProof_Approve"]}

    #2. updateJsonBody
    ${actualPaymentAmount}  Evaluate    int(${actualPaymentAmount})

    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.data.paymentBillingNo    ${paymentBillNo}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.data.confirmSlipLs[0].amount    ${actualPaymentAmount}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.data.confirmSlipLs[0].actualAmount    ${actualPaymentAmount}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.data.actualPaymentAmount    ${actualPaymentAmount}

    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.data.finalPayableAmount    ${actualPayableAmount}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.data.bizAmount    ${actualPayableAmount}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.data.overpaymentAmount    ${overpaymentAmount}


    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.data.confirmSlipLs[0].paymentBillingId    ${paymentBillingId}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.data.confirmSlipLs[0].paymentBillingNo    ${paymentBillingNo}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.data.confirmSlipLs[0].paymentSlipNo    ${paymentSlipNo}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.data.confirmSlipLs[0].referenceNo    ${referenceNo}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.taskId    ${taskId}
    Log     ${jsonBody}

    #3. convert jsonBody to string
    ${strBody}  Convert Json To String    ${jsonBody}

    #4. send request
    ${response}    approval.Send Request And Get Response Data    ${bossToken}    ${strBody}
    Set Test Variable    ${jsonResult}    ${response.json()}
    Log    ${jsonResult}

