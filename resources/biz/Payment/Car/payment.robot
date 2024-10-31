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

slipInfoCheck
    ${get_data}=  paymentBillingCreate
    ${orderId}=  Get From Dictionary    ${get_data}  orderID
    ${payBillNo}=  Get From Dictionary    ${get_data}  paymentBillNo
    ${securityCode}=  Get From Dictionary    ${get_data}  securityCode
    ${token}=  Get From Dictionary    ${get_data}  token
    ${tenantId}=  Get From Dictionary    ${get_data}  tenantId
    ${orderNo}=  Get From Dictionary    ${get_data}  orderNo
    
    ${headers}=  Create Dictionary    Content-Type=application/json  tenantId="${tenantId}"  fusetoken=${token}  language=en_US
    Create Session    orderInfoSession  ${slipInfo_url}  headers=${headers}  verify=False
    ${body}=  Set Variable    {"orderId": "${orderId}"}
    ${response}=  POST On Session    orderInfoSession  ${slipInfo_url}  ${body}
    Should Be Equal As Strings    ${response.status_code}  200
    ${get_json}=  Get From Dictionary    ${response.json()}  data
    ${get_dict}=  Get From List      ${get_json}   0
    ${slipNo}=  Get From Dictionary    ${get_dict}  uid
    Log  slipNo:${slipNo}
    ${get_dirct}=  Create Dictionary   orderNo=${orderNo}   paymentBillNo=${payBillNo}  securityCode=${securityCode}  orderID=${orderId}  tenantId=${tenantId}  token=${token}  slipNo=${slipNo}
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
    ${body}=  Set Variable    {"payerType":1,"paymentScheme":1,"methodCode":"9203","bonusDeduction":0,"pointsDeduction":0,"orderId":"${orderId}","securityCode":"${securityCode}","selectType":2}
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
