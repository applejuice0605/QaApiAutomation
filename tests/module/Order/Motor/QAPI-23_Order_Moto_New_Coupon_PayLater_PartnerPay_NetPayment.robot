*** Settings ***
Library    RequestsLibrary
Library    Collections
Library    String
Library    XML
Library    SeleniumLibrary
Library    DateTime

Resource    ../../../../resources/biz/Login/login.robot
Resource    ../../../../resources/biz/order/vehicle_order.robot
Resource    ../../../../resources/biz/order/getCoupon.robot
Resource    ../../../../resources/biz/Payment/creatBilling_choosePayTypeAndPaymentScheme.robot

Resource    ../../../../resources/util/assertUtil.robot
Resource    ../../../../resources/resource.robot

#Setup Test
Test Setup    Setup Env Variable
Test Teardown    Delete All Sessions

*** Variables ***
${BODY_FILE_PATH}    Motor_PlaceOrderData.json
${isAdvancePremium}     0
${payerType}    2
${paymentScheme}    2
${CouponCode}   PR00000727
${paymentMethod}    GoPay


*** Test Cases ***
Motor using coupon PayLater PartnerPay NetPayment
    [Tags]    uat    order-motor
    Given Setup Data Testing
    When I have a whitelist account and have logined
    Then I send the quotation request to savebinderrfq API   ${AP_POSITIVE_DATA}     ${token}
    Then The status code should be 200    ${jsonResult}[code]
    And the response should contain the value quoteNo and rfqNo     ${jsonResult}

    Then I send request to getAvailableCoupon API   ${AP_POSITIVE_DATA}     ${token}
    Then The status code should be 200    ${jsonResult}[code]
    And the response should contain the available coupon list and get coupon info by couponCode   ${jsonResult}    ${CouponCode}

    Then I send the place order request to createrfqorder API    ${AP_POSITIVE_DATA}     ${token}    ${rfqNo}    ${quoteNo}  ${isAdvancePremium}    couponUseInfo=${couponUseInfo}
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