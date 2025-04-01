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
Resource    ../../../../resources/biz/order/Travel/travel_order.robot
Resource    ../../../../resources/biz/Payment/creatBilling_choosePayTypeAndPaymentScheme.robot

Resource    ../../../../resources/util/utilCommon.robot
Resource    ../../../../resources/util/assertUtil.robot
Resource    ../../../../resources/resource.robot

#Setup Test
Test Setup    Setup Env Variable
Test Teardown    Delete All Sessions


*** Variables ***
${BODY_FILE_PATH}    Travel_PlaceOrderData.json
${payerType}    1
${paymentScheme}    1


*** Test Cases ***
Travel PayNow CustomerPay
    [Tags]    uat   prod    order-travel
    Given Setup Data Testing
    When I have a whitelist account and have logined
    Then I send the quotation request to savebinderrfq API   ${AP_POSITIVE_DATA}     ${token}
    Then The status code should be 200    ${jsonResult}[code]
    And the response should contain the value quoteNo and rfqNo     ${jsonResult}
    Then I send the place order request to createrfqorder API    ${AP_POSITIVE_DATA}     ${token}    ${rfqNo}    ${quoteNo}
    Then The status code should be 200    ${jsonResult}[code]
    And the response should contain the value orderNo and orderId    ${jsonResult}

    Then I continue to pay the order and send request the paymentBilling/create API     ${token}     ${orderNo}
    Then The status code should be 200    ${jsonResult}[code]
    And the response of paymentBilling/create API should contain securityCode    ${jsonResult}

    Then I choose CutsomerPay and send request to generator/customer/payment/token API     ${token}     ${securityCode}
    Then The status code should be 200    ${jsonResult}[code]
    And the response should contain customerToken    ${jsonResult}

    Then I confirm to complete the payment using "CustomerPay FullPayment" and send the request to /slip/process API    ${customerToken}   ${orderId}    ${securityCode}
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
    Set Test Variable    ${token}    ${token}


#
#
#
#I continue to pay the order and send request the paymentBilling/create API
#    Sleep    3s
#    ${response}    createPaymentBilling.Send Request And Get Response Data     token=${token}   orderNo=${orderNo}
#
#    Set Test Variable    ${jsonResult}    ${response.json()}
#    Log    ${jsonResult}
#
#
#the response of paymentBilling/create API should contain securityCode
#    Should Contain    ${jsonResult}[data]   securityCode
#    Set Test Variable    ${securityCode}    ${jsonResult}[data][securityCode]
#
#
#I choose partner pay & Net payment & a payment method amd send request to /slip/process API
#    ${response}    slip_process.Send Request And Get Response Data    token=${token}    orderId=${orderId}    securityCode=${securityCode}  paymentScheme=${paymentScheme}    payerType=${payerType}
#    Set Test Variable    ${jsonResult}    ${response.json()}
#    Log    ${jsonResult}
#
#
#the response should contain lessAmount
#    Should Contain    ${jsonResult}[data]   lessAmount
#
#
#I click continue and send request to getChannelFee API
#    ${response}    getChannelFee.Send Request And Get Response Data    token=${token}    securityCode=${securityCode}
#
#
#
