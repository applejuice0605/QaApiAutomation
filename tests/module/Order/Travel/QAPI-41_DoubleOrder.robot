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
    Then I send the same quotation msg to savebinderrfq API
    Then the status code should be 200
    And the response should contain the value quoteNo and rfqNo
    Then I send the place order request to createrfqorder API
    Then the status code should be 2001001
    And the response should contain the msg "quotation decline"



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

I send the same quotation msg to savebinderrfq API
    #1. getJsonBody
    ${jsonBody}     Set Variable    ${AP_POSITIVE_DATA["quotationBody"]}


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


I send the place order request to createrfqorder API
    #1. getJsonBody
    ${jsonBody}     Set Variable    ${AP_POSITIVE_DATA["placeOrderBody"]}
    #2. updateJsonBody
    ${identityNo}=    utilCommon.Generate Random identityNo
    ${effectiveTime}=    utilCommon.Get Effective Time
    ${expireTime}=    utilCommon.Get Expire Time    365

    Log     ${identityNo}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.rfqNo    ${rfqNo}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.quoteNo    ${quoteNo}
#    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.quotationDataJson.riskGroupInfo.travel.fromDate    ${effectiveTime}
#    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.quotationDataJson.riskGroupInfo.travel.toDate    ${expireTime}
#    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.quotationDataJson.insuranceInfo.effectiveDate    ${effectiveTime}
#    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.quotationDataJson.insuranceInfo.expiredDate    ${expireTime}
#    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.dataFormJson.insuredInfo[0].identityNo    ${identityNo}

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


the status code should be 200
    Log    ${jsonResult}
    Log    ${jsonResult}[code]
    Should Be Equal As Numbers    ${jsonResult}[code]    200

the status code should be 2001001
    Log    ${jsonResult}
    Log    ${jsonResult}[code]
    Should Be Equal As Numbers    ${jsonResult}[code]    2001001

the response should contain the msg "quotation decline"
    Should Contain    ${jsonResult}[message]    quotation decline