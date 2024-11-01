*** Settings ***
Resource    ../../../resources/lib/Common.robot
Resource    ../../../resources/biz/order/Car/SaveBinderRFQ.robot
Resource    ../../../resources/biz/order/Car/CreateBinderOrder.robot
Resource    ../../../resources/biz/Payment/Car/payment.robot


*** Variables ***
${loginAccount}=  628123268989
${password}=  268989

*** Test Cases ***
Customer Pay - Full Payment - car order Success
    Given By Phone Number Login FusePro Success  ${loginAccount}   ${password}
    Then Send SaveBinderOrder Post Request
    Then Send CreateBinderOrder Post Request
    Then Send PaymentBillingCreate Post Request
    Then Send OVO_GetCustomerToken Post Request
    Then Send OVO Post Request Customer
    Then Send OVO_Customer Process Request Cutomer
    Then Send OVO_Confirm Post Request

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
    ${data}=  Send CarCreateBinderOrder Post Request - Discount From SpecialBonus And SpecialBonus  ${tenantId}  ${token}  ${quoteNo}  ${rfqNo}
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

Send OVO_GetCustomerToken Post Request
    ${get_customerToken}=  GetCustomerToken  ${securityCode}  ${token}
    Set Test Variable    ${customerToken}  ${get_customerToken}

Send OVO Post Request Customer
    ${data}=  CustomerPayment   ${orderId}   ${paymentBillNo}  ${securityCode}  ${token}  ${tenantId}  ${orderNo}
    ${amount}=  Get From Dictionary    ${data}  amount
    Set Global Variable    ${amount}  ${amount}

Send OVO_Customer Process Request Cutomer
    OVO_sendPayment_Customer  ${securityCode}  ${customer_token}  ${amount}

Send OVO_Confirm Post Request
    ${data}=  OVO_Confirm_Customer  ${securityCode}  ${customerToken}   ${amount}