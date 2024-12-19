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




*** Test Cases ***
Property EQVET PayLater With Discount Commission From Property
    [Tags]    uat   prod    order-property    discount
    Given Setup Data Testing
    When I have a whitelist account and have logined
    Then I send the quotation request to savebinderrfq API   ${AP_POSITIVE_DATA}     ${token}
    Then The status code should be 200    ${jsonResult}[code]
    And the response should contain the value quoteNo and rfqNo     ${jsonResult}
    Then I send the place order request to createrfqorder API    ${AP_POSITIVE_DATA}     ${token}    ${rfqNo}    ${quoteNo}  ${isAdvancePremium}    discountFormCommission_property=${discountFormCommission_property}
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
