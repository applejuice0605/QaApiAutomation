*** Settings ***
Library    RequestsLibrary

Resource    ../../api/order/saveBinderRfqOrder.robot
Resource    ../../api/order/createBinderOrder.robot
Resource    ../../api/order/getAvailableCoupon.robot
Resource    ../../../resources/util/utilCommon.robot

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
    [Arguments]     ${AP_POSITIVE_DATA}     ${token}    ${rfqNo}    ${quoteNo}  ${isAdvancePremium}    ${vehicleVinNo}=     ${platNo}=tba    ${discountFormCommission}=0     ${discountFromPartnerSpecialBonusAmount}=0    ${couponUseInfo}=[]
    #1. getJsonBody
    ${jsonBody}     Set Variable    ${AP_POSITIVE_DATA["placeOrderBody"]}
    #2. updateJsonBody
    ${effectiveTime}=    utilCommon.Get Effective Time
    ${expireTime}=    utilCommon.Get Expire Time    365

    Log     ${vehicleVinNo}
    IF  '${vehicleVinNo}' == ''
        ${vehicleVinNo}     utilCommon.Generate Random chars
    END
    ${vehicleEngineNo}     utilCommon.Generate Random chars
    Log     ${vehicleVinNo}
    Log     ${vehicleEngineNo}
#    ${vehicleVinNo}     Set Variable    io9fo
#    ${vehicleEngineNo}     Set Variable    io9fo

    ${type}    Evaluate    type(${jsonBody})
    Log    ${type}
    Log    ${jsonBody}

    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.rfqNo    ${rfqNo}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.quoteNo    ${quoteNo}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.dataFormJson.riskGroupInfo.vehicle.vehicleVinNo    ${vehicleVinNo}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.dataFormJson.riskGroupInfo.vehicle.vehicleEngineNo    ${vehicleEngineNo}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.dataFormJson.insuranceInfo.effectiveDate    ${effectiveTime}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.dataFormJson.insuranceInfo.expiredDate    ${expireTime}

    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.isAdvancePremium    ${isAdvancePremium}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.partnerToCustomerDiscountAmountProducts[0].discountAmount    ${discountFormCommission}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.partnerToCustomerDiscountAmountProducts[0].discountFromPartnerSpecialBonusAmount    ${discountFromPartnerSpecialBonusAmount}


    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.dataFormJson.riskGroupInfo.vehicle.plateNo    ${platNo}


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


I send the place order request to createrfqorder API using register classisNumber
    [Arguments]     ${AP_POSITIVE_DATA}     ${token}    ${rfqNo}    ${quoteNo}  ${isAdvancePremium}    ${vehicleVinNo}=     ${platNo}=tba    ${discountFormCommission}=0     ${discountFromPartnerSpecialBonusAmount}=0    ${couponUseInfo}=[]
    I send the place order request to createrfqorder API       ${AP_POSITIVE_DATA}     ${token}    ${rfqNo}    ${quoteNo}  ${isAdvancePremium}    vehicleVinNo=${vehicleVinNo}


I send the place order request to createrfqorder API using register plateNumber
    [Arguments]     ${AP_POSITIVE_DATA}     ${token}    ${rfqNo}    ${quoteNo}  ${isAdvancePremium}    ${vehicleVinNo}=     ${platNo}=tba    ${discountFormCommission}=0     ${discountFromPartnerSpecialBonusAmount}=0    ${couponUseInfo}=[]
    I send the place order request to createrfqorder API       ${AP_POSITIVE_DATA}     ${token}    ${rfqNo}    ${quoteNo}  ${isAdvancePremium}    platNo=${platNo}


the status code should be 200107001
    [Arguments]    ${code}
    Log    ${jsonResult}
    Log    ${jsonResult}[code]
    Should Be Equal As Numbers    ${jsonResult}[code]    200107001

the response should contain the msg "You have already input this order."
    [Arguments]    ${jsonResult}
    Should Contain    ${jsonResult}[message]    The vehicle data you input is already registered in an active policy in our system.

