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
${payerType}    2
${paymentScheme}    1
${discountFormCommission_property}      1000
${discountFormCommission_EQVET}     200200
${discountFromPartnerSpecialBonusAmount_EQVET}      1000
${paymentMethod}    VA


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


    Then I continue to pay the order and send request the paymentBilling/create API     ${token}     ${orderNo}
    Then The status code should be 200    ${jsonResult}[code]
    And the response of paymentBilling/create API should contain securityCode    ${jsonResult}

    Then I choose PartnerPay & PaymentScheme & PaymentMethod and send request to /slip/process API     ${token}     ${orderId}     ${securityCode}    ${paymentScheme}
    Then The status code should be 200    ${jsonResult}[code]
    And the response should contain lessAmount      ${jsonResult}

    Then finally Log the OrderNo ${orderNo}


*** Keywords ***
Setup Data Testing

    Log    ${BODY_FILE_PATH}
    Log    ${env_vars}[DATA_BASEURL]
    ${BODY_FILE_PATH}    Set Variable    ${env_vars}[DATA_BASEURL]${BODY_FILE_PATH}
    Log    ${BODY_FILE_PATH}
    ${AP_POSITIVE_DATA}=    Load JSON From File    ${BODY_FILE_PATH}
    Set Test Variable    ${AP_POSITIVE_DATA}

I have a whitelist account and have logined
    ${token}=   login.Login to Application using mobile     ${env_vars}[FUSE_ACCOUNT]    ${env_vars}[FUSE_PASSWORD]
    Set Test Variable    ${token}
