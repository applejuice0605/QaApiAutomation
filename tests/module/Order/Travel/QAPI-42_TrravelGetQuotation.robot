*** Settings ***
Library    RequestsLibrary
Library    Collections
Library    String
Library    XML
Library    SeleniumLibrary
Library    DateTime

Resource    ../../../../resources/biz/Login/login.robot
Resource    ../../../../resources/api/order/saveBinderRfqOrder.robot
Resource    ../../../../resources/api/order/createBinderOrder.robot
Resource    ../../../../resources/api/order/generateQuotePDF.robot

Resource    ../../../../resources/util/utilCommon.robot
#Setup Test
Suite Teardown    Delete All Sessions

*** Variables ***
#EXECDIR: 编译路径？类似的概念
${BODY_FILE_PATH}    resources/data/property/QAPI-39_PlaceOrderData.json


*** Test Cases ***
Travel Get Quotation
    [Tags]    uatAndprod
    Given Setup Data Testing
    When I have a whitelist account and have logined
    Then I send the quotation request to savebinderrfq API
    Then The status code should be 200
    And the response should contain the value quoteNo and rfqNo
    Then I send the go quotation pdf request to generateQuotePDF API
    Then The status code should be 200
    And the response should contain the value of pdfFileUrl



*** Keywords ***
Setup Data Testing
    ${AP_POSITIVE_DATA}=    Load JSON From File    ${BODY_FILE_PATH}
    Set Test Variable    ${AP_POSITIVE_DATA}


I have a whitelist account and have logined
    Set Test Variable    ${account}    628123268987
    Set Test Variable    ${password}    268987
    ${token}=   login.Login to Application using mobile
    Set Test Variable    ${token}    ${token}


I send the quotation request to savebinderrfq API
    Log     ${AP_POSITIVE_DATA}
    ${strBody}  Convert Json To String    ${AP_POSITIVE_DATA["quotationBody"]}
    ${response}    saveBinderRfqOrder.Send Request And Get Response Data    ${token}    ${strBody}

    Log    ${response}
    Set Test Variable    ${jsonResult}    ${response.json()}


The response should contain the value quoteNo and rfqNo
    Should Contain    ${jsonResult}[data]   rfqNo
    Should Contain    ${jsonResult}[data]   quoteNo
    Set Test Variable    ${rfqNo}    ${jsonResult}[data][rfqNo]
    Set Test Variable    ${quoteNo}    ${jsonResult}[data][quoteNo]


I send the go quotation pdf request to generateQuotePDF API
    Sleep    3s
    ${response}    generateQuotePDF.Send Request And Get Response Data    ${token}    ${rfqNo}    ${quoteNo}

    Set Test Variable    ${jsonResult}    ${response.json()}


the response should contain the value of pdfFileUrl
    Should Contain    ${jsonResult}[data]   pdfFileUrl
    Log     ${jsonResult}[data][pdfFileUrl]

The status code should be 200
    Log    ${jsonResult}
    Log    ${jsonResult}[code]
    Should Be Equal As Numbers    ${jsonResult}[code]    200

