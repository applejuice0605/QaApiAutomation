*** Settings ***
Library    RequestsLibrary
Library    Collections
Library    String
Library    XML
Library    SeleniumLibrary
Library    DateTime
Library    JSONLibrary

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


*** Test Cases ***
Travel Double Order
    [Tags]    uat   prod    order-travel
    Given Setup Data Testing
    When I have a whitelist account and have logined and have a useful identityNo

    Then I send the quotation request to savebinderrfq API   ${AP_POSITIVE_DATA}     ${token}
    Then The status code should be 200    ${jsonResult}[code]
    And the response should contain the value quoteNo and rfqNo     ${jsonResult}

    Then I send the place order request to createrfqorder API   ${AP_POSITIVE_DATA}     ${token}    ${rfqNo}    ${quoteNo}  identityNo=${identityNo}
    Then The status code should be 200    ${jsonResult}[code]
    And the response should contain the value orderNo and orderId    ${jsonResult}

    Then I send the same quotation msg to savebinderrfq API
    Then The status code should be 200    ${jsonResult}[code]
    And the response should contain the value quoteNo and rfqNo     ${jsonResult}

    Then I send the place order request to createrfqorder API using same identityNo=${identityNo}
    Then the status code should be 200107002
    And the response should contain the msg "You have already input this order."



*** Keywords ***
Setup Data Testing

    Log    ${BODY_FILE_PATH}
    Log    ${env_vars}[DATA_BASEURL]
    ${BODY_FILE_PATH}    Set Variable    ${env_vars}[DATA_BASEURL]${BODY_FILE_PATH}
    Log    ${BODY_FILE_PATH}
    ${AP_POSITIVE_DATA}=    Load JSON From File    ${BODY_FILE_PATH}
    Set Test Variable    ${AP_POSITIVE_DATA}

I have a whitelist account and have logined and have a useful identityNo
    ${token}=   login.Login to Application using mobile     ${env_vars}[FUSE_ACCOUNT]    ${env_vars}[FUSE_PASSWORD]
    Set Test Variable    ${token}
    ${identityNo}=    utilCommon.Generate Random identityNo
    Set Test Variable    ${identityNo}
    Log    ${identityNo}


I send the same quotation msg to savebinderrfq API
    travel_order.I send the quotation request to savebinderrfq API    ${AP_POSITIVE_DATA}    ${token}



I send the place order request to createrfqorder API using same identityNo=${identityNo}
    travel_order.I send the place order request to createrfqorder API    ${AP_POSITIVE_DATA}    ${token}    ${rfqNo}    ${quoteNo}  identityNo=${identityNo}
#    #1. getJsonBody
#    ${jsonBody}     Set Variable    ${AP_POSITIVE_DATA["placeOrderBody"]}
#    #2. updateJsonBody
#    ${identityNo}=    utilCommon.Generate Random identityNo
#    ${effectiveTime}=    utilCommon.Get Effective Time
#    ${expireTime}=    utilCommon.Get Expire Time    365
#
#    Log     ${identityNo}
#    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.rfqNo    ${rfqNo}
#    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.quoteNo    ${quoteNo}
##    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.quotationDataJson.riskGroupInfo.travel.fromDate    ${effectiveTime}
##    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.quotationDataJson.riskGroupInfo.travel.toDate    ${expireTime}
##    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.quotationDataJson.insuranceInfo.effectiveDate    ${effectiveTime}
##    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.quotationDataJson.insuranceInfo.expiredDate    ${expireTime}
##    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.dataFormJson.insuredInfo[0].identityNo    ${identityNo}
#
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




the status code should be 200107002
    Log    ${jsonResult}
    Log    ${jsonResult}[code]
    Should Be Equal As Numbers    ${jsonResult}[code]    200107002

the response should contain the msg "You have already input this order."
    Should Contain    ${jsonResult}[message]    You have already input this order.