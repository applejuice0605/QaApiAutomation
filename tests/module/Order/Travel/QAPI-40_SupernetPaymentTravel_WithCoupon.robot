
*** Settings ***
Library    RequestsLibrary
Library    Collections
Library    String
Library    XML
Library    SeleniumLibrary
Library    DateTime
Library    JSONLibrary

Resource    ../../../../resources/biz/Login/login.robot
Resource    ../../../../resources/api/order/saveBinderRfqOrder.robot
Resource    ../../../../resources/api/order/createBinderOrder.robot
Resource    ../../../../resources/api/payment/createPaymentBilling.robot
Resource    ../../../../resources/api/payment/slip_process.robot
Resource    ../../../../resources/api/payment/getChannelFee.robot
Resource    ../../../../resources/api/order/getAvailableCoupon.robot

Resource    ../../../../resources/util/utilCommon.robot
#Setup Test
#Suite Setup     Setup Data Testing
Suite Teardown    Delete All Sessions


*** Variables ***
#EXECDIR: 编译路径？类似的概念
${BODY_FILE_PATH}    resources/data/property/QAPI-39_PlaceOrderData.json


*** Test Cases ***
Travel PayNow
    [Tags]    uatAndprod
    Given Setup Data Testing
    When I have a whitelist account and have logined
    Then I send the quotation request to savebinderrfq API
    Then the status code should be 200
    And the response should contain the value quoteNo and rfqNo
    Then I send request to getAvailableCoupon API
    Then the status code should be 200
    And the response should contain the available coupon list
    Then I send the place order request to createrfqorder API
    Then the status code should be 200
    And the response should contain the value orderNo and orderId
    Then finally Log the OrderNo
    Then I continue to pay the order and send request the create paymentBilling API
    Then the status code should be 200
    And the response should contain securityCode
    Then I choose partner pay & Supernet payment & a payment method amd send request to /slip/process API
    Then the status code should be 200
    And the response should contain lessAmount
    Then I click continue and send request to getChannelFee API
    Then the status code should be 200
    Then finally Log the OrderNo



*** Keywords ***
Setup Data Testing
    ${AP_POSITIVE_DATA}=    Load JSON From File    ${BODY_FILE_PATH}
    Set Test Variable    ${AP_POSITIVE_DATA}

I have a whitelist account and have logined
    Set Test Variable    ${account}    628123268987
    Set Test Variable    ${password}    268987
    ${token}=   login.Login to Application using mobile
    Set Test Variable    ${token}    ${token}
    Setup Data Testing

I send the quotation request to savebinderrfq API
    #1. getJsonBody
    ${jsonBody}     Set Variable    ${AP_POSITIVE_DATA["quotationBody"]}

    #2. updateJsonBody
    ${effectiveTime}=    utilCommon.Get Effective Time
    ${expireTime}=    utilCommon.Get Expire Time    365
    Set Test Variable    ${effectiveTime}
    Set Test Variable    ${expireTime}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.quotationDataJson.riskGroupInfo.travel.fromDate    ${effectiveTime}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.quotationDataJson.riskGroupInfo.travel.toDate    ${expireTime}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.quotationDataJson.insuranceInfo.effectiveDate    ${effectiveTime}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.quotationDataJson.insuranceInfo.expiredDate    ${expireTime}

    #3. convert jsonBody to string
    ${strBody}  Convert Json To String    ${jsonBody}

    #4. send request and get response data
    ${response}    saveBinderRfqOrder.Send Request And Get Response Data    ${token}    ${strBody}

    Log    ${response}
    Set Test Variable    ${jsonResult}    ${response.json()}

The response should contain the value quoteNo and rfqNo
    Should Contain    ${jsonResult}[data]   rfqNo
    Should Contain    ${jsonResult}[data]   quoteNo
    Set Test Variable    ${rfqNo}    ${jsonResult}[data][rfqNo]
    Set Test Variable    ${quoteNo}    ${jsonResult}[data][quoteNo]


I send request to getAvailableCoupon API
    #1. getJsonBody
    ${jsonBody}     Set Variable    ${AP_POSITIVE_DATA["couponBody"]}

    #2. convert jsonBody to string
    ${strBody}  Convert Json To String    ${jsonBody}

    #3. send request and get response data
    ${response} =    getAvailableCoupon.Send Request And Get Response Data    ${token}    ${strBody}
    Set Test Variable    ${jsonResult}    ${response.json()}
    Log    ${jsonResult}


the response should contain the available coupon list
    ${couponDTO}=    utilCommon.Get CouponId by ProductCode    ${jsonResult}[data]    R_00061
#    ${couponUseInfo}    Create List     ${couponDTO}
#    ${couponUseInfo}    Convert To String    ${couponUseInfo}
#    ${couponUseInfo}    Replace String    ${couponUseInfo}    [    ${EMPTY}
    Set Test Variable    ${couponUseInfo}   ${couponDTO}


I send the place order request to createrfqorder API
    #1. getJsonBody
    ${jsonBody}     Set Variable    ${AP_POSITIVE_DATA["placeOrderBody"]}
    #2. updateJsonBody
    ${identityNo}=    utilCommon.Generate Random identityNo
    Log     ${couponUseInfo}

    Log     ${identityNo}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.rfqNo    ${rfqNo}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.quoteNo    ${quoteNo}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.quotationDataJson.riskGroupInfo.travel.fromDate    ${effectiveTime}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.quotationDataJson.riskGroupInfo.travel.toDate    ${expireTime}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.quotationDataJson.insuranceInfo.effectiveDate    ${effectiveTime}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.quotationDataJson.insuranceInfo.expiredDate    ${expireTime}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.dataFormJson.insuredInfo[0].identityNo    ${identityNo}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.couponUseInfo    ${couponUseInfo}

    Log     ${jsonBody}

    #3. convert jsonBody to string
    ${strBody}  Convert Json To String    ${jsonBody}

    #4. send request
    ${response}    createBinderOrder.Send Request And Get Response Data    ${token}    ${strBody}

    Log    ${response}

    Set Test Variable    ${jsonResult}    ${response.json()}



The response should contain the value orderNo and orderId
    Should Contain    ${jsonResult}[data]   orderNo
    Should Contain    ${jsonResult}[data]   orderIdLs
    Set Test Variable    ${orderNo}    ${jsonResult}[data][orderNo]
    ${orderIds}  Create List    ${jsonResult}[data][orderIdLs]
    ${orderId}  Get From List    ${jsonResult}[data][orderIdLs]    0
    Set Test Variable    ${orderId}    ${orderIds[0]}



I continue to pay the order and send request the create paymentBilling API
    Sleep    3s
    ${response}    createPaymentBilling.Send Request And Get Response Data     token=${token}   orderNo=${orderNo}

    Set Test Variable    ${jsonResult}    ${response.json()}
    Log    ${jsonResult}


the response should contain securityCode
    Should Contain    ${jsonResult}[data]   securityCode
    Set Test Variable    ${securityCode}    ${jsonResult}[data][securityCode]


I choose partner pay & Supernet payment & a payment method amd send request to /slip/process API
    ${response}    slip_process.Send Request And Get Response Data    token=${token}    orderId=${orderId}    securityCode=${securityCode}  paymentScheme=3    payerType=2
    Set Test Variable    ${jsonResult}    ${response.json()}
    Log    ${jsonResult}


the response should contain lessAmount
    Should Contain    ${jsonResult}[data]   lessAmount


I click continue and send request to getChannelFee API
    ${response}    getChannelFee.Send Request And Get Response Data    token=${token}    securityCode=${securityCode}





the status code should be 200
    Log    ${jsonResult}
    Log    ${jsonResult}[code]
    Should Be Equal As Numbers    ${jsonResult}[code]    200

finally Log the OrderNo
    Log    ${orderNo}


