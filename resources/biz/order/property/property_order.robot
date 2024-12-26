*** Settings ***
Library    RequestsLibrary

Resource    ../../../api/order/saveBinderRfqOrder.robot
Resource    ../../../api/order/createBinderOrder.robot
Resource    ../../../api/order/getAvailableCoupon.robot
Resource    ../../../../resources/util/utilCommon.robot

*** Keywords ***
I send the quotation request to savebinderrfq API
    [Arguments]     ${AP_POSITIVE_DATA}     ${token}
    #1. getJsonBody
    ${jsonBody}     Set Variable    ${AP_POSITIVE_DATA["quotationBody"]}
    Log     ${jsonBody}

    #2. updateJsonBody

    #3. convert jsonBody to string
    ${strBody}  Convert Json To String    ${jsonBody}

    #4. send request and get response data
    ${response}    saveBinderRfqOrder.Send Request And Get Response Data    ${token}    ${strBody}

    Log    ${response}
    Set Test Variable    ${jsonResult}    ${response.json()}


I send the place order request to createrfqorder API
    [Arguments]     ${AP_POSITIVE_DATA}     ${token}    ${rfqNo}    ${quoteNo}  ${isAdvancePremium}     ${discountFormCommission_property}=0     ${discountFromPartnerSpecialBonusAmount_property}=0    ${discountFormCommission_EQVET}=0     ${discountFromPartnerSpecialBonusAmount_EQVET}=0      ${couponUseInfo}=[]
    #1. getJsonBody
    ${jsonBody}     Set Variable    ${AP_POSITIVE_DATA["placeOrderBody"]}
    #2. updateJsonBody
    ${effectiveTime}=    utilCommon.Get Effective Time
    ${expireTime}=    utilCommon.Get Expire Time    365

    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.rfqNo    ${rfqNo}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.quoteNo    ${quoteNo}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.dataFormJson.insuranceInfo.effectiveDate    ${effectiveTime}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.dataFormJson.insuranceInfo.expiredDate    ${expireTime}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.isAdvancePremium    ${isAdvancePremium}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.partnerToCustomerDiscountAmountProducts[0].discountAmount    ${discountFormCommission_property}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.partnerToCustomerDiscountAmountProducts[0].discountFromPartnerSpecialBonusAmount    ${discountFromPartnerSpecialBonusAmount_property}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.partnerToCustomerDiscountAmountProducts[1].discountAmount    ${discountFormCommission_EQVET}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.partnerToCustomerDiscountAmountProducts[1].discountFromPartnerSpecialBonusAmount    ${discountFromPartnerSpecialBonusAmount_EQVET}

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



