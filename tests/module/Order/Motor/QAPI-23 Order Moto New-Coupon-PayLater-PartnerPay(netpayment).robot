*** Settings ***
Resource    ../../../../resources/lib/Common.robot
Resource    ../../../../resources/api/Motor/CreateBinderMotor.robot
Resource    ../../../../resources/api/Motor/SaveBinderRFQMotor.robot
Resource    ../../../../resources/api/Motor/getCoupon.robot
Resource    ../../../../resources/biz/Payment/Car/payment.robot


*** Variables ***
${loginAccount}=  628123268989
${password}=  268989

*** Test Cases ***
Order Moto New - Coupon - Pay Later - Partner Pay (netpayment) Success
    Given By Phone Number Login FusePro Success  ${loginAccount}   ${password}
    Then Send SaveBinderOrder Post Request
    Then Send GetMotorCoupon Post Request
    Then Send CreateBinderOrder Post Request
    Then Send PaymentBillingCreate Post Request
    Then Send OVO_Send Post Request

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

Send GetMotorCoupon Post Request
    ${data}=  Send MotorGetCoupon Post Request  ${token}
    Set Test Variable    ${couponId}  ${data}

Send CreateBinderOrder Post Request
    ${discountCommission}=  Set Variable     0
    ${discountSpecialBonusAmount}=  Set Variable     0
    ${data}=  Send MotorCreateBinderOrder Post Request- PayLater And Coupon  ${tenantId}  ${token}  ${quoteNo}  ${rfqNo}  ${discountCommission}  ${discountSpecialBonusAmount}  ${couponId}
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

Send OVO_Send Post Request
    ${data}=  PartnerPayment NetPayment  ${orderId}  ${paymentBillNo}  ${securityCode}  ${token}  ${tenantId}  ${orderNo}
    ${amount}=  Get From Dictionary   ${data}  amount
    Set Global Variable    ${amount}  ${amount}
