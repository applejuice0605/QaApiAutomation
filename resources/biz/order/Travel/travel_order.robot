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
    Run Keyword If    ${identityNo} == '0'   Set Test Variable    ${identityNo}     ${newidentityNo}

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

