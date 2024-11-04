*** Settings ***
Resource    ../../../../resources/lib/Common.robot
Resource    ../../../../resources/biz/order/Car/SaveBinderRFQ.robot
Resource    ../../../../resources/biz/order/Car/CreateBinderOrder.robot
Resource    ../../../../resources/biz/order/Car/getCarCoupon.robot
Resource    ../../../../resources/biz/Payment/Car/payment.robot
Test Setup   Delete All Sessions

*** Variables ***
${loginAccount}=  628123268989
${password}=  268989

*** Test Cases ***
Order Car-Pay Later-Partner Pay(NetPayment) - Coupon
    Given By Phone Number Login FusePro Success  ${loginAccount}   ${password}
    Then Send SaveBinderOrder Post Request
    Then Send GetCarCoupon Post Request
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
    Log  token:${token}

Send SaveBinderOrder Post Request
    ${data}=  Send CarSaveBinderOrder Post Request  ${tenantId}  ${token}
    ${quoteNo}=  Get From Dictionary    ${data}   quoteNo
    ${rfqNo}=  Get From Dictionary    ${data}  rfqNo
    Set Test Variable     ${quoteNo}  ${quoteNo}
    Set Global Variable    ${rfqNo}  ${rfqNo}

Send GetCarCoupon Post Request
    ${data}=  Send CarGetCoupon Post Request  ${token}
    Set Test Variable    ${couponId}  ${data}

Send CreateBinderOrder Post Request
    ${discountCommission}=  Set Variable     0
    ${discountSpecialBonusAmount}=  Set Variable     0
    ${data}=  Send CarCreateBinderOrder Post Request - Coupon  ${tenantId}  ${token}  ${quoteNo}  ${rfqNo}  ${couponId}
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
    ${data}=  Partner NetPay  ${orderId}  ${paymentBillNo}  ${securityCode}  ${token}  ${tenantId}  ${orderNo}
    ${amount}=  Get From Dictionary   ${data}  amount
    Set Global Variable    ${amount}  ${amount}

