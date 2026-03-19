*** Settings ***
Library    RequestsLibrary
Library    Collections
Library    String
Library    XML
Library    SeleniumLibrary
Library    DateTime
Library    JSONLibrary
Library    json

Resource    ../../../../resources/biz/Login/login.robot
Resource    ../../../../resources/api/order/saveBinderRfqOrder.robot
Resource    ../../../../resources/api/order/createBinderOrder.robot
Resource    ../../../../resources/api/payment/createPaymentBilling.robot
Resource    ../../../../resources/api/payment/slip_process.robot
Resource    ../../../../resources/api/payment/getChannelFee.robot
Resource    ../../../../resources/api/order/getAvailableCoupon.robot



Resource    ../../../../resources/util/utilCommon.robot
Resource    ../../../../resources/util/assertUtil.robot
Resource    ../../../../resources/resource.robot

*** Keywords ***
I send the quotation request to savebinderrfq API
    [Arguments]     ${AP_POSITIVE_DATA}     ${token}
    #1. getJsonBody
    ${jsonBody}     Set Variable    ${AP_POSITIVE_DATA["quotationBody"]}
    Log     ${jsonBody}

    #2. updateJsonBody
    ${effectiveTime}=    utilCommon.Get Effective Time
    ${expireTime}=    utilCommon.Get Expire Time    365
    Set Test Variable    ${effectiveTime}
    Set Test Variable    ${expireTime}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.quotationDataJson.riskGroupInfo.travel.fromDate    ${effectiveTime}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.quotationDataJson.riskGroupInfo.travel.toDate    ${expireTime}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.quotationDataJson.insuranceInfo.effectiveDate    ${effectiveTime}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.quotationDataJson.insuranceInfo.expiredDate    ${expireTime}


    Log     ${jsonBody}

    #3. convert jsonBody to string
    ${strBody}  Convert Json To String    ${jsonBody}

    #4. send request and get response data
    ${response}    saveBinderRfqOrder.Send Request And Get Response Data    ${token}    ${strBody}

    Log    ${response}
    Set Test Variable    ${jsonResult}    ${response.json()}


I send the place order request to createrfqorder API
    [Arguments]     ${AP_POSITIVE_DATA}     ${token}    ${rfqNo}    ${quoteNo}  ${discountFormCommission}=0    ${discountFromPartnerSpecialBonusAmount}=0      ${identityNo}='0'    ${couponUseInfo}=[]
    #1. getJsonBody
    ${jsonBody}     Set Variable    ${AP_POSITIVE_DATA["placeOrderBody"]}

    #2. updateJsonBody
    ${newidentityNo}=     utilCommon.Generate Random identityNo
    # 注意：${identityNo} 可能以字符串形式包含前导 0（如 068...）。
    # 若不加引号，Robot 在解析条件表达式时会把它当“前导零整数”交给 Python eval，导致 SyntaxError。
    IF    '${identityNo}' == '0'
        ${identityNo}=    Set Variable    ${newidentityNo}
    END

    Log     ${identityNo}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.rfqNo    ${rfqNo}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.quoteNo    ${quoteNo}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.dataFormJson.riskGroupInfo.travel.fromDate    ${effectiveTime}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.dataFormJson.riskGroupInfo.travel.toDate    ${expireTime}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.dataFormJson.insuranceInfo.effectiveDate    ${effectiveTime}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.dataFormJson.insuranceInfo.expiredDate    ${expireTime}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.dataFormJson.insuredInfo[0].identityNo    ${identityNo}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.partnerToCustomerDiscountAmountProducts[0].discountAmount    ${discountFormCommission}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.partnerToCustomerDiscountAmountProducts[0].discountFromPartnerSpecialBonusAmount    ${discountFromPartnerSpecialBonusAmount}

    Log    ${couponUseInfo}
    IF    ${couponUseInfo} != []
        ${jsonBody}=    Update Value To Json    ${jsonBody}    $.couponUseInfo    ${couponUseInfo}
    END
    Log     ${jsonBody}

    #3. convert jsonBody to string
    ${strBody}  Convert Json To String    ${jsonBody}

    #4. send request
    ${response}    createBinderOrder.Send Request And Get Response Data    ${token}    ${strBody}

    Log    ${response}

    Set Test Variable    ${jsonResult}    ${response.json()}



the status code should be 200107002
    Log    ${jsonResult}
    Log    ${jsonResult}[code]
    Should Be Equal As Numbers    ${jsonResult}[code]    200107002

the response should contain the msg "You have already input this order."
    Should Contain    ${jsonResult}[message]    You have already input this order.