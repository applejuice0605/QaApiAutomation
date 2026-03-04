*** Settings ***
Library    RequestsLibrary
Library    Collections
Library    String
Library    XML
Library    SeleniumLibrary
Library    DateTime
Library    JSONLibrary

Resource    ../../resources/api/WA/pchat_whatsapp_webhook.robot

Resource    ../../resources/util/assertUtil.robot
Resource    ../../resources/util/dbUtil.robot
Resource    ../../resources/util/utilCommon.robot
Resource    ../../resources/resource.robot



#Setup Test
#Test Setup    Setup Env Variable
#Test Teardown    Delete All Sessions

*** Variables ***
${BODY_FILE_PATH}    Car_PlaceOrderData.json
${isAdvancePremium}     1
${payerType}    2
${paymentScheme}    3
${paymentMethod}    VA
${whatsapp_id}  8619830441461
*** Test Cases ***
ask premium
    [Tags]
    Query by Trace_id    77510039cc71a260



*** Keywords ***
