*** Settings ***
Resource    ../../../resources/lib/Common.robot
Resource    ../../../resources/api/Motor/CreateBinderMotor.robot
Resource    ../../../resources/api/Motor/SaveBinderRFQMotor.robot
Resource    ../../../resources/biz/Payment/Car/payment.robot
Resource    ../../../resources/api/PaymentBillingFlow/UploadPaymentProof.robot

*** Variables ***
${loginAccount}=  628123268989
${password}=  268989
*** Test Cases ***
GoPay Partner Pay-Net Payment-moto Success
    Given By Phone Number Login FusePro Success  ${loginAccount}   ${password}
    Then Send SaveBinderOrder Post Request
    Then Send CreateBinderOrder Post Request
    Sleep    5
    Then Send PaymentBillingCreate Post Request
    Then Send goPay_Send Post Request
    Then Send goPay_Confirm Post Request
    Then Check ReferenceNo And TransactionNo
    Then GoPay Mock CallBack

*** Keywords ***
By Phone Number Login FusePro Success
    [Arguments]    ${loginAccount}   ${password}
    ${data}=  Get Token And TenantId And OpenId  ${loginAccount}  ${password}
    ${tenantId}=  Get From Dictionary    ${data}  tenantId
    ${token}=  Get From Dictionary    ${data}  token
    Set Test Variable    ${tenantId}   ${tenantId}
    Set Test Variable    ${token}   ${token}

Send SaveBinderOrder Post Request
    ${data}=  Send MotorSaveBinderOrder Post Request  ${token}
    ${quoteNo}=  Get From Dictionary    ${data}   quoteNo
    ${rfqNo}=  Get From Dictionary    ${data}  rfqNo
    Set Test Variable     ${quoteNo}  ${quoteNo}
    Set Global Variable    ${rfqNo}  ${rfqNo}


Send CreateBinderOrder Post Request
    ${discountCommission}=  Set Variable     0
    ${discountSpecialBonusAmount}=  Set Variable     0
    ${data}=  Send MotorCreateBinderOrder Post Request PayLater  ${tenantId}  ${token}  ${quoteNo}  ${rfqNo}  ${discountCommission}  ${discountSpecialBonusAmount}
    ${orderNo}=  Get From Dictionary    ${data}  orderNo
    ${orderId}=  Get From Dictionary    ${data}  orderId
    Set Test Variable    ${orderNo}  ${orderNo}
    Set Test Variable    ${orderId}  ${orderId}
    Log  data:${data}

Send PaymentBillingCreate Post Request
    ${data}=  payment.Send PaymentBillingCreate Post Request  ${orderNo}  ${orderId}  ${tenantId}  ${token}
    ${securityCode}=  Get From Dictionary    ${data}  securityCode
    ${paymentBillNo}=  Get From Dictionary    ${data}  paymentBillNo
    Set Test Variable    ${securityCode}   ${securityCode}
    Set Test Variable    ${paymentBillNo}   ${paymentBillNo}

Send goPay_Send Post Request
    ${data}=  goPay_PartnerPayment NetPayment  ${orderId}  ${paymentBillNo}  ${securityCode}  ${token}  ${tenantId}  ${orderNo}
    ${amount}=  Get From Dictionary   ${data}  amount
    Set Global Variable    ${amount}  ${amount}



#Send goPay_Customer Process Request Cutomer
#    goPay_sendPayment_Customer  ${securityCode}  ${customer_token}  ${amount}

Send goPay_Confirm Post Request
    ${data}=  goPayment_Confirm  ${orderId}  ${paymentBillNo}  ${securityCode}  ${token}  ${tenantId}  ${orderNo}  ${amount}

Check ReferenceNo And TransactionNo
    ${data}=  Send Check PaymentBillingInfo Post Request  ${paymentBillNo}   ${token}
    ${referenceNo}=  Get From Dictionary    ${data}  referenceNo
    ${paymentSlipNo}=  Get From Dictionary    ${data}  paymentSlipNo
    Set Test Variable    ${referenceNo}  ${referenceNo}
    Set Test Variable    ${paymentSlipNo}  ${paymentSlipNo}

GoPay Mock CallBack
    ${goPay_paymentGetWayFee}=   Set Variable      8803
    ${gross_amount}=   Evaluate    ${amount}+${goPay_paymentGetWayFee}
    Send GoPay Mock CallBack Post Request  ${gross_amount}  ${paymentSlipNo}  ${referenceNo}

