*** Settings ***
Resource    ../../../resources/lib/Common.robot
Resource    ../../../resources/api/Motor/CreateBinderMotor.robot
Resource    ../../../resources/api/Motor/SaveBinderRFQMotor.robot
Resource    ../../../resources/biz/Payment/Car/payment.robot

*** Variables ***
${loginAccount}=  628123268989
${password}=  268989
*** Test Cases ***
GoPay Partner Pay-Full Payment Bonus And Points-moto Success
    Given By Phone Number Login FusePro Success  ${loginAccount}   ${password}
    Then Fill Quotation Form And Selection Motor Product
    Then Fill Application Form
    Sleep    5
    Then Enter Cashier And Create PaymentBilling
    Then Selection FullPayment And GoPay
    Then Enter GoPay Payment Page
    Then Confirm GetChannelFee
#    Then Check ReferenceNo And TransactionNo
    Then GoPay Mock CallBack And Payment Success

*** Keywords ***
By Phone Number Login FusePro Success
    [Arguments]    ${loginAccount}   ${password}
    ${data}=  Get Token And TenantId And OpenId  ${loginAccount}  ${password}
    ${tenantId}=  Get From Dictionary    ${data}  tenantId
    ${token}=  Get From Dictionary    ${data}  token
    Set Test Variable    ${tenantId}   ${tenantId}
    Set Test Variable    ${token}   ${token}

Fill Quotation Form And Selection Motor Product
    ${data}=  Send MotorSaveBinderOrder Post Request  ${token}
    ${quoteNo}=  Get From Dictionary    ${data}   quoteNo
    ${rfqNo}=  Get From Dictionary    ${data}  rfqNo
    Set Test Variable     ${quoteNo}  ${quoteNo}
    Set Global Variable    ${rfqNo}  ${rfqNo}


Fill Application Form
    ${discountCommission}=  Set Variable     0
    ${discountSpecialBonusAmount}=  Set Variable     0
    ${data}=  Send MotorCreateBinderOrder Post Request PayLater  ${tenantId}  ${token}  ${quoteNo}  ${rfqNo}  ${discountCommission}  ${discountSpecialBonusAmount}
    ${orderNo}=  Get From Dictionary    ${data}  orderNo
    ${orderId}=  Get From Dictionary    ${data}  orderId
    Set Test Variable    ${orderNo}  ${orderNo}
    Set Test Variable    ${orderId}  ${orderId}
    Log  data:${data}

Enter Cashier And Create PaymentBilling
    ${data}=  payment.Send PaymentBillingCreate Post Request  ${orderNo}  ${orderId}  ${tenantId}  ${token}
    ${securityCode}=  Get From Dictionary    ${data}  securityCode
    ${paymentBillNo}=  Get From Dictionary    ${data}  paymentBillNo
    Set Test Variable    ${securityCode}   ${securityCode}
    Set Test Variable    ${paymentBillNo}   ${paymentBillNo}

Selection FullPayment And GoPay
    ${data}=  goPayPartnerPayment- Use Bonus And Point  ${orderId}  ${paymentBillNo}   ${securityCode}  ${token}  ${tenantId}  ${orderNo}
    ${amount}=  Get From Dictionary   ${data}  amount
#    ${totalInstallmentAmount}=  Get From Dictionary   ${data}  totalInstallmentAmount
    Set Global Variable    ${amount}  ${amount}
#    Set Test Variable      ${totalInstallmentAmount}  ${totalInstallmentAmount}

Confirm GetChannelFee
    ${data}=  goPayment_getChannelFee  ${securityCode}  ${token}
#    ${amount}=  Get From Dictionary   ${data}  amount
    ${totalInstallmentAmount}=  Get From Dictionary   ${data}  totalInstallmentAmount
    ${totalAmount}   Evaluate    int(${totalInstallmentAmount})
#    Set Global Variable    ${amount}  ${amount}
    Set Test Variable      ${totalAmount}  ${totalAmount}

Enter GoPay Payment Page
    ${data}=  goPayment_Confirm   ${orderId}  ${paymentBillNo}  ${securityCode}  ${token}  ${tenantId}  ${orderNo}  ${amount}
    ${paymentDTO}=  Get From Dictionary    ${data}  paymentDTO
    ${bizTransactionId}=  Get From Dictionary    ${paymentDTO}  bizTransactionId
    ${referenceNo}=  Get From Dictionary    ${paymentDTO}  referenceNo
    Set Test Variable    ${paymentSlipNo}  ${bizTransactionId}
    Set Test Variable    ${referenceNo}  ${referenceNo}

GoPay Mock CallBack
#    ${goPay_paymentGetWayFee}=   Set Variable      8803
#    ${gross_amount}=   Evaluate    ${amount}+${goPay_paymentGetWayFee}
    Send GoPay Mock CallBack Post Request  ${totalAmount}  ${paymentSlipNo}  ${referenceNo}



