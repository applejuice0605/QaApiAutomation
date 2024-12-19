*** Settings ***
Library    RequestsLibrary
Library    Collections
Library    String
Library    XML
Library    SeleniumLibrary
Library    DateTime

Resource    ../../../../resources/biz/Login/login.robot
Resource    ../../../../resources/biz/order/property/property_order.robot
Resource    ../../../../resources/biz/Payment/creatBilling_choosePayTypeAndPaymentScheme.robot



Resource    ../../../../resources/util/utilCommon.robot
Resource    ../../../../resources/util/assertUtil.robot
Resource    ../../../../resources/resource.robot

#Setup Test
Test Setup    Setup Env Variable
Test Teardown    Delete All Sessions


*** Variables ***
${BODY_FILE_PATH}    EQVET_Property_PlaceOrderData.json
${isAdvancePremium}     0
${paymentScheme}    1
${payerType}    2
${discountFormCommission_property}      1000
${discountFormCommission_EQVET}     1740
${discountFromPartnerSpecialBonusAmount_EQVET}      1000


*** Test Cases ***
Property EQVET PayLater With Discount Commission And Special Bonus From EQVET Plus Discount Commission From Property
    [Tags]    uat   prod    order-property    discount
    Given Setup Data Testing
    When I have a whitelist account and have logined
    Then I send the quotation request to savebinderrfq API   ${AP_POSITIVE_DATA}     ${token}
    Then The status code should be 200    ${jsonResult}[code]
    And the response should contain the value quoteNo and rfqNo     ${jsonResult}
    Then I send the place order request to createrfqorder API    ${AP_POSITIVE_DATA}     ${token}    ${rfqNo}    ${quoteNo}  ${isAdvancePremium}    discountFormCommission_property=${discountFormCommission_property}    discountFormCommission_EQVET=${discountFormCommission_EQVET}   discountFromPartnerSpecialBonusAmount_EQVET=${discountFromPartnerSpecialBonusAmount_EQVET}
    Then The status code should be 200    ${jsonResult}[code]
    And the response should contain the value orderNo and orderId    ${jsonResult}


    Then I continue to pay the order and send request the create paymentBilling API     ${token}     ${orderNo}
    Then The status code should be 200    ${jsonResult}[code]
    And the response should contain securityCode    ${jsonResult}
    Then I choose partner pay & Net payment & a payment method amd send request to /slip/process API     ${token}     ${orderId}     ${securityCode}    ${paymentScheme}    ${payerType}
    Then The status code should be 200    ${jsonResult}[code]
    And the response should contain lessAmount      ${jsonResult}
    Then I click continue and send request to getChannelFee API     ${token}     ${securityCode}
    Then The status code should be 200    ${jsonResult}[code]
    Then finally Log the OrderNo ${orderNo}


*** Keywords ***
Setup Data Testing
    Log    ${env}
    Log    ${BODY_FILE_PATH}
    Log    ${env_vars}[DATA_BASEURL]
    ${BODY_FILE_PATH}    Set Variable    ${env_vars}[DATA_BASEURL]${BODY_FILE_PATH}
    Log    ${BODY_FILE_PATH}
    ${AP_POSITIVE_DATA}=    Load JSON From File    ${BODY_FILE_PATH}
    Set Test Variable    ${AP_POSITIVE_DATA}

I have a whitelist account and have logined
    ${token}=   login.Login to Application using mobile     ${env_vars}[FUSE_ACCOUNT]    ${env_vars}[FUSE_PASSWORD]
    Set Test Variable    ${token}


#I send the place order request to createrfqorder API
#    #1. getJsonBody
#    ${jsonBody}     Set Variable    ${AP_POSITIVE_DATA["placeOrderBody"]}
#    #2. updateJsonBody
#    ${effectiveTime}=    utilCommon.Get Effective Time
#    ${expireTime}=    utilCommon.Get Expire Time    365
#
#    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.rfqNo    ${rfqNo}
#    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.quoteNo    ${quoteNo}
#    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.quotationDataJson.riskGroupInfo.travel.fromDate    ${effectiveTime}
#    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.quotationDataJson.riskGroupInfo.travel.toDate    ${expireTime}
#    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.quotationDataJson.insuranceInfo.effectiveDate    ${effectiveTime}
#    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.quotationDataJson.insuranceInfo.expiredDate    ${expireTime}
#    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.quotationDataJson.isAdvancePremium    ${isAdvancePremium}
#    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.partnerToCustomerDiscountAmountProducts[1].discountAmount    ${discountAmountFromEQVET}
#    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.partnerToCustomerDiscountAmountProducts[0].discountAmount    ${discountAmountFromProperty}
#    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.partnerToCustomerDiscountAmountProducts[1].discountFromPartnerSpecialBonusAmount    ${discountFromPartnerSpecialBonusAmount}
#    Log     ${jsonBody}
#
#    #3. convert jsonBody to string
#    ${strBody}  Convert Json To String    ${jsonBody}
#
#    #4. send request
#    ${response}    createBinderOrder.Send Request And Get Response Data    ${token}    ${strBody}
#
#    Log    ${response}
#
#    Set Test Variable    ${jsonResult}    ${response.json()}


