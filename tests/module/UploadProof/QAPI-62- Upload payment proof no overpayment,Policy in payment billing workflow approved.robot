*** Settings ***
Library    Collections
Library    BuiltIn
Library    OperatingSystem
Resource    ../../../resources/lib/Common.robot
Resource    ../../../resources/api/PaymentBillingFlow/UploadPaymentProof.robot
Resource    ../../../resources/biz/order/Car/SaveBinderRFQ.robot
Resource    ../../../resources/biz/order/Car/CreateBinderOrder.robot
Resource    ../../../resources/biz/Payment/Car/payment.robot
Resource    ../../../resources/Boss/LoginBoss/LoginBoss.robot

*** Variables ***
${loginAccount}=  628123268989
${password}=  268989
${BossLoginAccount}=   ceo001
${BossPassword}=  Fuse!001
${amount}=   10973000
*** Test Cases ***
Upload payment proof no overpayment,Policy in payment billing workflow approved success
#    Given Login FusePro Success
    Given By Phone Number Login FusePro Success  ${loginAccount}   ${password}
    Then Send SaveBinderOrder Post Request
    Then Send CreateBinderOrder Post Request
    Sleep    5
    Then Send PaymentBillingCreate Post Request
    Then Send OVO_Send Post Request
    Then Get Boss Token Post Request
    Then Send upload Post Request
    Sleep    10
    Then Send CheckPaymentBillingTaskId Post Request
    Then Assign PaymentBillingTask Give To Me
    Then Check PaymentBillingInfo
    Then Go Task PaymentBillingFlow Approval



*** Keywords ***
By Phone Number Login FusePro Success
    [Arguments]    ${loginAccount}   ${password}
    ${data}=  Get Token And TenantId And OpenId  ${loginAccount}  ${password}
    ${tenantId}=  Get From Dictionary    ${data}  tenantId
    ${token}=  Get From Dictionary    ${data}  token
    Set Test Variable    ${tenantId}   ${tenantId}
    Set Test Variable    ${token}   ${token}



Send SaveBinderOrder Post Request
    ${data}=  Send CarSaveBinderOrder Post Request  ${tenantId}  ${token}
    ${quoteNo}=  Get From Dictionary    ${data}   quoteNo
    ${rfqNo}=  Get From Dictionary    ${data}  rfqNo
    Set Test Variable     ${quoteNo}  ${quoteNo}
    Set Global Variable    ${rfqNo}  ${rfqNo}


Send CreateBinderOrder Post Request
    ${discountCommission}=  Set Variable     0
    ${discountSpecialBonusAmount}=  Set Variable     0
    ${data}=  Send CarCreateBinderOrder Post Request  ${tenantId}  ${token}  ${quoteNo}  ${rfqNo}  ${discountCommission}  ${discountSpecialBonusAmount}
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
    Log  paymentBillNo：${paymentBillNo}

Send OVO_Send Post Request
    ${data}=  OVO_sendPayment  ${orderId}  ${paymentBillNo}  ${securityCode}  ${token}  ${tenantId}  ${orderNo}
    ${amount}=  Get From Dictionary   ${data}  amount
    Set Global Variable    ${amount}  ${amount}

Get Boss Token Post Request
    ${data}=  Send boss_userLogin Post Request
    ${fuseToken}=  Get From Dictionary    ${data}  fuseToken
    Set Test Variable    ${fuseToken}  ${fuseToken}

Send upload Post Request
    Send UploadProof Post Request  ${paymentBillNo}   ${fuseToken}  ${amount}


Send CheckPaymentBillingTaskId Post Request
    ${data}=  Send PaymentBillingListManager Post Request   ${paymentBillNo}    ${fuseToken}
    Set Test Variable    ${id}  ${data}
    
Assign PaymentBillingTask Give To Me
    Send Assign Post Request  ${id}  ${fuseToken}

Check PaymentBillingInfo
    ${data}=  Send Check PaymentBillingInfo Post Request  ${paymentBillNo}   ${fuseToken}
    ${paymentSlipNo}=  Get From Dictionary    ${data}  paymentSlipNo
    ${referenceNo}=  Get From Dictionary    ${data}  referenceNo
#    ${paymentSlipNo}=  Get From Dictionary    ${data}  paymentSlipNo
    Set Test Variable    ${paymentSlipNo}  ${paymentSlipNo}
    Set Test Variable    ${referenceNo}  ${referenceNo}
Go Task PaymentBillingFlow Approval
    Send PaymentBillingFlow Approval Request   ${paymentBillNo}   ${paymentSlipNo}  ${referenceNo}  ${id}  ${fuseToken}   ${amount}





