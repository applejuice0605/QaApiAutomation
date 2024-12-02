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
Resource    ../../../../resources/biz/order/property/property_order.robot
Resource    ../../../../resources/util/utilCommon.robot
Resource    ../../../../resources/util/assertUtil.robot
Resource    ../../../../resources/resource.robot
#Setup Test
Test Setup    Setup Env Variable
Test Teardown    Delete All Sessions


*** Variables ***
${BODY_FILE_PATH}    resources/data/property/Travel_PlaceOrderData.json


*** Test Cases ***
Travel Double Order
    [Tags]    uat   prod    order-travel
    Given Setup Data Testing
    When I have a whitelist account and have logined and have order before
    Then I send the same quotation msg to savebinderrfq API
    Then The status code should be 200    ${jsonResult}[code]
    And the response should contain the value quoteNo and rfqNo
    Then I send the same application msg to createrfqorder API
    Then the status code should be 200107002
    And the response should contain the msg "You have already input this order."



*** Keywords ***
Setup Data Testing
    ${AP_POSITIVE_DATA}=    Load JSON From File    ${BODY_FILE_PATH}
    Set Test Variable    ${AP_POSITIVE_DATA}

I have a whitelist account and have logined and have order before
    ${token}=   login.Login to Application using mobile     ${env_vars}[FUSE_ACCOUNT]    ${env_vars}[FUSE_PASSWORD]
    Set Test Variable    ${token}
    ${orderInfo}      property_order.Property Order Pay Now without discount    ${token}
    Should Not Be Empty    ${orderInfo}

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


I send the same application msg to createrfqorder API
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

the status code should be 200107002
    Log    ${jsonResult}
    Log    ${jsonResult}[code]
    Should Be Equal As Numbers    ${jsonResult}[code]    200107002

the response should contain the msg "You have already input this order."
    Should Contain    ${jsonResult}[message]    You have already input this order.