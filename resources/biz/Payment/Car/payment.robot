*** Settings ***
Library    Collections
Library    RequestsLibrary
Library     Collections


*** Variables ***
${uploadProof_url}=  https://cashier-uat.fuse.co.id/api/cashier/partner/payment/bs/uploadProof
${assign_mysql}=  https://boss-uat.fuse.co.id/api/bpm/runtime/self/assign
${orderInfo_url}=  https://ptr-uat.fuse.co.id/api/order/v2/orderInfo
${slipInfo_url}=   https://ptr-uat.fuse.co.id/api/order/v2/slip/slipLs
${paymentUrl}    https://ptr-uat.fuse.co.id/api/paymentBilling/create
${paymentBillingList}=  https://ptr-uat.fuse.co.id/api/paymentBilling/list
${ovo_sendPayment}=  https://cashier-uat.fuse.co.id/api/cashier/partner/payment/slip/process
${ovo_getChannelFee}=  https://cashier-uat.fuse.co.id/api/cashier/partner/payment/slip/getChannelFee
${ovo_confirm}=  https://cashier-uat.fuse.co.id/api/cashier/partner/payment/slip/channel/process
${generateShorLink_url}=  https://ptr-uat.fuse.co.id/api/payment/generateShortLink

${send_customer}=  https://cashier-uat.fuse.co.id/api/cashier/customer/payment/slip/process
${send_customer_confirm}=  https://cashier-uat.fuse.co.id/api/cashier/customer/payment/slip/channel/process
${customer_getToken_url}=  https://cashier-uat.fuse.co.id/api/cashier/partner/generator/customer/payment/token
*** Keywords ***
Send PaymentBillingCreate Post Request
    [Documentation]    api/paymentBilling/create
    [Arguments]    ${orderNo}  ${orderId}  ${tenantId}  ${token}

    ${headers}=  Create Dictionary   Content-Type=application/json  tenantId="${tenantId}"  fusetoken=${token}  version=3.93.0.30-uat  clientType=ANDROID  language=en_US
    Create Session    paymentSession  ${paymentUrl}  headers=${headers}  verify=False
    ${body}=  Set Variable    {"orderNo": "${orderNo}"}
    ${response}=  POST On Session    paymentSession  ${paymentUrl}  ${body}
    Should Be Equal As Strings    ${response.status_code}  200
    ${get_json}=  Get From Dictionary    ${response.json()}  data
    ${payBillNo}=  Get From Dictionary    ${get_json}   paymentBillNo
    ${get_securityCode}=  Get From Dictionary    ${get_json}   securityCode
    ${get_dirct}=  Create Dictionary   orderNo=${orderNo}   paymentBillNo=${payBillNo}  securityCode=${get_securityCode}  orderID=${orderId}  tenantId=${tenantId}  token=${token}
    RETURN  ${get_dirct}

paymentBillingList
    ${get_data}=  slipInfoCheck
    ${orderId}=  Get From Dictionary    ${get_data}  orderID
    ${payBillNo}=  Get From Dictionary    ${get_data}  paymentBillNo
    ${securityCode}=  Get From Dictionary    ${get_data}  securityCode
    ${token}=  Get From Dictionary    ${get_data}  token
    ${tenantId}=  Get From Dictionary    ${get_data}  tenantId
    ${orderNo}=  Get From Dictionary    ${get_data}  orderNo
    ${slipNo}=  Get From Dictionary    ${get_data}  slipNo

    ${headers}=  Create Dictionary    Content-Type=application/json  tenantId="${tenantId}"  fusetoken=${token}  language=en_US
    Create Session    paymentListSession  ${paymentBillingList}  headers=${headers}   verify=False
    ${body}=  Set Variable    {"orderUid":"${orderId}","slipUids":["${slipNo}"]}
    ${response}=  POST On Session    paymentListSession  ${paymentBillingList}  ${body}
    Should Be Equal As Strings    ${response.status_code}  200

OVO_sendPayment
    [Arguments]    ${orderId}  ${payBillNo}  ${securityCode}  ${token}  ${tenantId}  ${orderNo}
    ${headers}=  Create Dictionary    Content-Type=application/json  tenantId="${tenantId}"  fusetoken=${token}  language=en_US
    Create Session    sendPaySession  ${ovo_sendPayment}  headers=${headers}  verify=False
    ${body}=  Set Variable    {"payerType":2,"paymentScheme":1,"methodCode":"9203","bonusDeduction":0,"pointsDeduction":0,"orderId":"${orderId}","securityCode":"${securityCode}","selectType":2}
    ${response}=  POST On Session    sendPaySession  ${ovo_sendPayment}  ${body}
    Should Be Equal As Strings    ${response.status_code}  200
    ${get_json}=  Get From Dictionary    ${response.json()}  data
    ${get_amount}=  Get From Dictionary   ${get_json}   lessAmount
    Log  amount:${get_amount}
    ${get_dic}=  Create Dictionary   orderNo=${orderNo}   amount=${get_amount}   paymentBillNo=${payBillNo}  securityCode=${securityCode}  orderID=${orderId}  tenantId=${tenantId}  token=${token}
    RETURN  ${get_dic}

OVO_sendPayment_Customer
    [Arguments]    ${securityCode}  ${customer_token}  ${amount}
    ${headers}=  Create Dictionary    Content-Type=application/json   x-5a-temp-token=${customer_token}  language=en_US
    Create Session    customerSession  ${send_customer_confirm}  headers=${headers}  verify=False
    ${body}=  Set Variable    {"amount":"${amount}","methodCode":"9203","securityCode":"${securityCode}","extJson":{"mobileNumber":"+6246485"}}
    ${response}=  POST On Session    customerSession  ${send_customer_confirm}  ${body}
    Should Be Equal As Strings    ${response.status_code}  200
    ${get_json}=  Get From Dictionary    ${response.json()}  data
#    ${get_amount}=  Get From Dictionary    ${get_json}  bizAmount
#    RETURN  ${get_amount}

goPay_sendPayment_Customer
    [Arguments]    ${securityCode}  ${customer_token}  ${amount}
    ${headers}=  Create Dictionary    Content-Type=application/json   x-5a-temp-token=${customer_token}  language=en_US
    Create Session    customerSession  ${send_customer_confirm}  headers=${headers}  verify=False
    ${body}=  Set Variable    {"amount":"${amount}","methodCode":"9201","securityCode":"${securityCode}","extJson":{"mobileNumber":"+6246485"}}
    ${response}=  POST On Session    customerSession  ${send_customer_confirm}  ${body}
    Should Be Equal As Strings    ${response.status_code}  200
    ${get_json}=  Get From Dictionary    ${response.json()}  data
#    ${get_amount}=  Get From Dictionary    ${get_json}  bizAmount
#    RETURN  ${get_amount}

OVO_Confirm_Customer
    [Arguments]    ${securityCode}  ${token}  ${amount}
    ${headers}=  Create Dictionary    Content-Type=application/json  x-5a-temp-token=${token}    language=en_US
    Create Session    ovoConfirmSession  ${send_customer_confirm}  headers=${headers}  verify=False
    ${body}=  Set Variable    {"amount":"${amount}","methodCode":"9203","securityCode":"${securityCode}","extJson":{"mobileNumber":"+62467886"}}
    ${response}=  POST On Session    ovoConfirmSession  ${send_customer_confirm}  ${body}
    Should Be Equal As Strings    ${response.status_code}  200

goPay_Confirm_Customer
    [Arguments]    ${securityCode}  ${token}  ${amount}
    ${headers}=  Create Dictionary    Content-Type=application/json  x-5a-temp-token=${token}    language=en_US
    Create Session    ovoConfirmSession  ${send_customer_confirm}  headers=${headers}  verify=False
    ${body}=  Set Variable    {"amount":"${amount}","methodCode":"9201","securityCode":"${securityCode}","extJson":{"mobileNumber":"+62467886"}}
    ${response}=  POST On Session    ovoConfirmSession  ${send_customer_confirm}  ${body}
    Should Be Equal As Strings    ${response.status_code}  200

PartnerPay bonus fuse-point Full Payment
    [Arguments]    ${orderId}  ${payBillNo}  ${securityCode}  ${token}  ${tenantId}  ${orderNo}
    ${headers}=  Create Dictionary    Content-Type=application/json  tenantId="${tenantId}"  fusetoken=${token}  language=en_US
    Create Session    sendPaySession  ${ovo_sendPayment}  headers=${headers}  verify=False
    ${body}=  Set Variable    {"payerType":2,"paymentScheme":1,"methodCode":"9203","bonusDeduction":1000,"pointsDeduction":2000000,"orderId":"${orderId}","securityCode":"${securityCode}","selectType":2}
    ${response}=  POST On Session    sendPaySession  ${ovo_sendPayment}  ${body}
    Should Be Equal As Strings    ${response.status_code}  200
    ${get_json}=  Get From Dictionary    ${response.json()}  data
    ${get_amount}=  Get From Dictionary   ${get_json}   lessAmount
    Log  amount:${get_amount}
    ${get_dic}=  Create Dictionary   orderNo=${orderNo}   amount=${get_amount}   paymentBillNo=${payBillNo}  securityCode=${securityCode}  orderID=${orderId}  tenantId=${tenantId}  token=${token}
    RETURN  ${get_dic}

Partner NetPay
    [Arguments]    ${orderId}  ${payBillNo}  ${securityCode}  ${token}  ${tenantId}  ${orderNo}
    ${headers}=  Create Dictionary    Content-Type=application/json  tenantId="${tenantId}"  fusetoken=${token}  language=en_US
    Create Session    sendPaySession  ${ovo_sendPayment}  headers=${headers}  verify=False
    ${body}=  Set Variable    {"payerType":2,"paymentScheme":2,"methodCode":"9203","bonusDeduction":0,"pointsDeduction":0,"orderId":"${orderId}","securityCode":"${securityCode}","selectType":2}
    ${response}=  POST On Session    sendPaySession  ${ovo_sendPayment}  ${body}
    Should Be Equal As Strings    ${response.status_code}  200
    ${get_json}=  Get From Dictionary    ${response.json()}  data
    ${get_amount}=  Get From Dictionary   ${get_json}   lessAmount
    Log  amount:${get_amount}
    ${get_dic}=  Create Dictionary   orderNo=${orderNo}   amount=${get_amount}   paymentBillNo=${payBillNo}  securityCode=${securityCode}  orderID=${orderId}  tenantId=${tenantId}  token=${token}
    RETURN  ${get_dic}

Partner SuperNetPayment
    [Arguments]    ${orderId}  ${payBillNo}  ${securityCode}  ${token}  ${tenantId}  ${orderNo}
    ${headers}=  Create Dictionary    Content-Type=application/json  tenantId="${tenantId}"  fusetoken=${token}  language=en_US
    Create Session    sendPaySession  ${ovo_sendPayment}  headers=${headers}  verify=False
    ${body}=  Set Variable    {"payerType":2,"paymentScheme":3,"methodCode":"9203","bonusDeduction":0,"pointsDeduction":0,"orderId":"${orderId}","securityCode":"${securityCode}","selectType":2}
    ${response}=  POST On Session    sendPaySession  ${ovo_sendPayment}  ${body}
    Should Be Equal As Strings    ${response.status_code}  200
    ${get_json}=  Get From Dictionary    ${response.json()}  data
    ${get_amount}=  Get From Dictionary   ${get_json}   lessAmount
    Log  amount:${get_amount}
    ${get_dic}=  Create Dictionary   orderNo=${orderNo}   amount=${get_amount}   paymentBillNo=${payBillNo}  securityCode=${securityCode}  orderID=${orderId}  tenantId=${tenantId}  token=${token}
    RETURN  ${get_dic}

OVO_getChannelFee
    ${get_data}=  OVO_sendPayment
    ${orderId}=  Get From Dictionary    ${get_data}  orderID
    ${payBillNo}=  Get From Dictionary    ${get_data}  paymentBillNo
    ${securityCode}=  Get From Dictionary    ${get_data}  securityCode
    ${token}=  Get From Dictionary    ${get_data}  token
    ${tenantId}=  Get From Dictionary    ${get_data}  tenantId
    ${orderNo}=  Get From Dictionary    ${get_data}  orderNo
    ${amount}=  Get From Dictionary    ${get_data}  amount

    ${headers}=  Create Dictionary    Content-Type=application/json  fusetoken=${token}  language=en_US
    Create Session    channelFeeSession  ${ovo_getChannelFee}  headers=${headers}  verify=False
    ${body}=  Set Variable    {"channelCode":"xendit","securityCode":"${securityCode}“,"methodCode":"9203"}
    ${response}=  POST On Session    channelFeeSession  ${ovo_getChannelFee}  ${body}
    Should Be Equal As Strings    ${response.status_code}  200
    ${get_json}=  Get From Dictionary    ${response.json()}  data
    ${get_amount}=  Get From Dictionary   ${get_json}   lessAmount
    Log  amount:${get_amount}
    ${get_dic}=  Create Dictionary   amount=${get_amount}   paymentBillNo=${payBillNo}  securityCode=${securityCode}  orderID=${orderId}  tenantId=${tenantId}  token=${token}
    RETURN  ${get_dic}

OVO_Confirm
    [Arguments]    ${orderId}  ${payBillNo}  ${securityCode}  ${token}  ${tenantId}  ${orderNo}  ${amount}
    ${headers}=  Create Dictionary    Content-Type=application/json  tenantId="${tenantId}"  fusetoken=${token}  language=en_US
    Create Session    ovoConfirmSession  ${ovo_confirm}  headers=${headers}  verify=False
    ${body}=  Set Variable    {"amount":${amount},"methodCode":"9203","securityCode":"${securityCode}","extJson":{"mobileNumber":"+624534632"}}
    ${response}=  POST On Session    ovoConfirmSession  ${ovo_confirm}  ${body}
    Should Be Equal As Strings    ${response.status_code}  200
    ${get_json}=  Get From Dictionary    ${response.json()}  data

Partner SuperNetPayment - User All Bonus
    [Arguments]    ${orderId}  ${payBillNo}  ${securityCode}  ${token}  ${tenantId}  ${orderNo}
    ${headers}=  Create Dictionary    Content-Type=application/json  tenantId="${tenantId}"  fusetoken=${token}  language=en_US
    Create Session    sendPaySession  ${ovo_sendPayment}  headers=${headers}  verify=False
    ${body}=  Set Variable    {"payerType":2,"paymentScheme":"3","methodCode":"","bonusDeduction":7243820,"pointsDeduction":0,"orderId":"${orderId}","securityCode":"${securityCode}","selectType":2}
    ${response}=  POST On Session    sendPaySession  ${ovo_sendPayment}  ${body}
    Should Be Equal As Strings    ${response.status_code}  200
    ${get_json}=  Get From Dictionary    ${response.json()}  data
    ${get_amount}=  Get From Dictionary   ${get_json}   lessAmount
    Log  amount:${get_amount}
    ${get_dic}=  Create Dictionary   orderNo=${orderNo}   amount=${get_amount}   paymentBillNo=${payBillNo}  securityCode=${securityCode}  orderID=${orderId}  tenantId=${tenantId}  token=${token}
    RETURN  ${get_dic}

Partner SuperNetPayment - User All Fuse Points
    [Arguments]    ${orderId}  ${payBillNo}  ${securityCode}  ${token}  ${tenantId}  ${orderNo}
    ${headers}=  Create Dictionary    Content-Type=application/json  tenantId="${tenantId}"  fusetoken=${token}  language=en_US
    Create Session    sendPaySession  ${ovo_sendPayment}  headers=${headers}  verify=False
    ${body}=  Set Variable    {"payerType":2,"paymentScheme":"3","methodCode":"","bonusDeduction":0,"pointsDeduction":7243820,"orderId":"${orderId}","securityCode":"${securityCode}","selectType":2}
    ${response}=  POST On Session    sendPaySession  ${ovo_sendPayment}  ${body}
    Should Be Equal As Strings    ${response.status_code}  200
    ${get_json}=  Get From Dictionary    ${response.json()}  data
    ${get_amount}=  Get From Dictionary   ${get_json}   lessAmount
    Log  amount:${get_amount}
    ${get_dic}=  Create Dictionary   orderNo=${orderNo}   amount=${get_amount}   paymentBillNo=${payBillNo}  securityCode=${securityCode}  orderID=${orderId}  tenantId=${tenantId}  token=${token}
    RETURN  ${get_dic}

Partner SuperNetPayment - Bonus & Fuse Point
    [Arguments]    ${orderId}  ${payBillNo}  ${securityCode}  ${token}  ${tenantId}  ${orderNo}
    ${headers}=  Create Dictionary    Content-Type=application/json  tenantId="${tenantId}"  fusetoken=${token}  language=en_US
    Create Session    sendPaySession  ${ovo_sendPayment}  headers=${headers}  verify=False
    ${body}=  Set Variable    {"payerType":2,"paymentScheme":"3","methodCode":"","bonusDeduction":7233820,"pointsDeduction":10000,"orderId":"${orderId}","securityCode":"${securityCode}","selectType":2}
    ${response}=  POST On Session    sendPaySession  ${ovo_sendPayment}  ${body}
    Should Be Equal As Strings    ${response.status_code}  200
    ${get_json}=  Get From Dictionary    ${response.json()}  data
    ${get_amount}=  Get From Dictionary   ${get_json}   lessAmount
    Log  amount:${get_amount}
    ${get_dic}=  Create Dictionary   orderNo=${orderNo}   amount=${get_amount}   paymentBillNo=${payBillNo}  securityCode=${securityCode}  orderID=${orderId}  tenantId=${tenantId}  token=${token}
    RETURN  ${get_dic}

Order_Payment
    OVO_Confirm
    ${get_data}=  OVO_sendPayment
    ${orderId}=  Get From Dictionary    ${get_data}  orderID
    ${payBillNo}=  Get From Dictionary    ${get_data}  paymentBillNo
    ${securityCode}=  Get From Dictionary    ${get_data}  securityCode
    ${token}=  Get From Dictionary    ${get_data}  token
    ${tenantId}=  Get From Dictionary    ${get_data}  tenantId
    ${orderNo}=  Get From Dictionary    ${get_data}  orderNo
    ${amount}=  Get From Dictionary    ${get_data}  amount

    ${headers}=  Create Dictionary    Content-Type=application/json  tenantId="${tenantId}"  fusetoken=${token}  language=en_US
    Create Session    ovoConfirmSession  ${ovo_confirm}  headers=${headers}  verify=False
    ${body}=  Set Variable    {"amount":${amount},"methodCode":"9203","securityCode":"${securityCode}","extJson":{"mobileNumber":"+624534632"}}
    ${response}=  POST On Session    ovoConfirmSession  ${ovo_confirm}  ${body}
    Should Be Equal As Strings    ${response.status_code}  200
    ${get_json}=  Get From Dictionary    ${response.json()}  data

CustomerPayment
    [Arguments]    ${orderId}  ${payBillNo}  ${securityCode}  ${token}  ${tenantId}  ${orderNo}
    ${headers}=  Create Dictionary    Content-Type=application/json  tenantId="${tenantId}"  fusetoken=${token}  language=en_US
    Create Session    sendPaySession  ${ovo_sendPayment}  headers=${headers}  verify=False
    ${body}=  Set Variable    {"payerType":1,"paymentScheme":1,"methodCode":"","bonusDeduction":0,"pointsDeduction":0,"orderId":"${orderId}","securityCode":"${securityCode}","selectType":2}
    ${response}=  POST On Session    sendPaySession  ${ovo_sendPayment}  ${body}
    Should Be Equal As Strings    ${response.status_code}  200
    ${get_json}=  Get From Dictionary    ${response.json()}  data
    ${get_amount}=  Get From Dictionary   ${get_json}   lessAmount
    Log  amount:${get_amount}
    ${get_dic}=  Create Dictionary   orderNo=${orderNo}   amount=${get_amount}   paymentBillNo=${payBillNo}  securityCode=${securityCode}  orderID=${orderId}  tenantId=${tenantId}  token=${token}
    RETURN  ${get_dic}


PartnerPayment
    [Arguments]    ${orderId}  ${payBillNo}  ${securityCode}  ${token}  ${tenantId}  ${orderNo}
    ${headers}=  Create Dictionary    Content-Type=application/json  tenantId="${tenantId}"  fusetoken=${token}  language=en_US
    Create Session    sendPaySession  ${ovo_sendPayment}  headers=${headers}  verify=False
    ${body}=  Set Variable    {"payerType":2,"paymentScheme":1,"methodCode":"9203","bonusDeduction":0,"pointsDeduction":0,"orderId":"${orderId}","securityCode":"${securityCode}","selectType":2}
    ${response}=  POST On Session    sendPaySession  ${ovo_sendPayment}  ${body}
    Should Be Equal As Strings    ${response.status_code}  200
    ${get_json}=  Get From Dictionary    ${response.json()}  data
    ${get_amount}=  Get From Dictionary   ${get_json}   lessAmount
    Log  amount:${get_amount}
    ${get_dic}=  Create Dictionary   orderNo=${orderNo}   amount=${get_amount}   paymentBillNo=${payBillNo}  securityCode=${securityCode}  orderID=${orderId}  tenantId=${tenantId}  token=${token}
    RETURN  ${get_dic}

PartnerPayment SuperNetPayment
    [Arguments]    ${orderId}  ${payBillNo}  ${securityCode}  ${token}  ${tenantId}  ${orderNo}
    ${headers}=  Create Dictionary    Content-Type=application/json  tenantId="${tenantId}"  fusetoken=${token}  language=en_US
    Create Session    sendPaySession  ${ovo_sendPayment}  headers=${headers}  verify=False
    ${body}=  Set Variable    {"payerType":2,"paymentScheme":3,"methodCode":"9203","bonusDeduction":0,"pointsDeduction":0,"orderId":"${orderId}","securityCode":"${securityCode}","selectType":2}
    ${response}=  POST On Session    sendPaySession  ${ovo_sendPayment}  ${body}
    Should Be Equal As Strings    ${response.status_code}  200
    ${get_json}=  Get From Dictionary    ${response.json()}  data
    ${get_amount}=  Get From Dictionary   ${get_json}   lessAmount
    Log  amount:${get_amount}
    ${get_dic}=  Create Dictionary   orderNo=${orderNo}   amount=${get_amount}   paymentBillNo=${payBillNo}  securityCode=${securityCode}  orderID=${orderId}  tenantId=${tenantId}  token=${token}
    RETURN  ${get_dic}

PartnerPayment NetPayment
    [Arguments]    ${orderId}  ${payBillNo}  ${securityCode}  ${token}  ${tenantId}  ${orderNo}
    ${headers}=  Create Dictionary    Content-Type=application/json  tenantId="${tenantId}"  fusetoken=${token}  language=en_US
    Create Session    sendPaySession  ${ovo_sendPayment}  headers=${headers}  verify=False
    ${body}=  Set Variable    {"payerType":2,"paymentScheme":2,"methodCode":"9203","bonusDeduction":0,"pointsDeduction":0,"orderId":"${orderId}","securityCode":"${securityCode}","selectType":2}
    ${response}=  POST On Session    sendPaySession  ${ovo_sendPayment}  ${body}
    Should Be Equal As Strings    ${response.status_code}  200
    ${get_json}=  Get From Dictionary    ${response.json()}  data
    ${get_amount}=  Get From Dictionary   ${get_json}   lessAmount
    Log  amount:${get_amount}
    ${get_dic}=  Create Dictionary   orderNo=${orderNo}   amount=${get_amount}   paymentBillNo=${payBillNo}  securityCode=${securityCode}  orderID=${orderId}  tenantId=${tenantId}  token=${token}
    RETURN  ${get_dic}

GenerateShortLink Post Request
    [Arguments]    ${securityCode}  ${token}
    ${headers}=  Create Dictionary    Content-Type=application/json  fusetoken=${token}
    Create Session    generateShortLink  ${generateShorLink_url}  headers=${headers}  verify=False
    ${body}=  Set Variable    {"bizSource":"1","paymentLink":"https://cashier-uat.fuse.co.id/v2/#/customer?securityCode=${securityCode}&region=ID&language=en-US"}
    ${response}=  POST On Session    generateShortLink  ${generateShorLink_url}  ${body}
    Should Be Equal As Strings    ${response.status_code}  200
    ${get_json}=  Get From Dictionary    ${response.json()}  data
    ${shortLink}=  Get From Dictionary   ${get_json}   shortLink
    Log  shortLink:${shortLink}
    ${get_dic}=  Create Dictionary    shortLink=${shortLink}
    RETURN  ${get_dic}
    
GetCustomerToken
    [Arguments]    ${securityCode}  ${token}
    ${headers}=  Create Dictionary    Content-Type=application/json  fusetoken=${token}
    Create Session    getCustomerSession  ${customer_getToken_url}  headers=${headers}  verify=False
    ${body}=  Set Variable    {"securityCode": "${securityCode}"}
    ${response}=  POST On Session    getCustomerSession  ${customer_getToken_url}  ${body}
    Should Be Equal As Strings    ${response.status_code}  200
    ${get_json}=  Get From Dictionary    ${response.json()}  data
    ${get_customerToken}=  Get From Dictionary    ${get_json}  token

    RETURN  ${get_customerToken}












