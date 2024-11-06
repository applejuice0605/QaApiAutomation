*** Settings ***
Library    RequestsLibrary

Resource    ../../api/order/saveBinderRfqOrder.robot
Resource    ../../api/order/createBinderOrder.robot
Resource    ../Login/login.robot
Resource    ../../util/utilCommon.robot

*** Variables ***
${BODY_FILE_PATH}    resources/data/property/Travel_PlaceOrderData.json



*** Keywords ***
Travel Order Pay Now without discount
    [Arguments]     ${token}
    #1. 加载数据
    ${AP_POSITIVE_DATA}=    Load JSON From File    ${BODY_FILE_PATH}

    #2. saveBinderRfqOrder
    #2.1 getJsonBody
    ${jsonBody}     Set Variable    ${AP_POSITIVE_DATA["quotationBody"]}

    #2.2 updateJsonBody
    ${effectiveTime}=    utilCommon.Get Effective Time
    ${expireTime}=    utilCommon.Get Expire Time    365
    Set Test Variable    ${effectiveTime}
    Set Test Variable    ${expireTime}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.quotationDataJson.riskGroupInfo.travel.fromDate    ${effectiveTime}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.quotationDataJson.riskGroupInfo.travel.toDate    ${expireTime}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.quotationDataJson.insuranceInfo.effectiveDate    ${effectiveTime}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.quotationDataJson.insuranceInfo.expiredDate    ${expireTime}

    #2.3 convert jsonBody to string
    ${strBody}  Convert Json To String    ${jsonBody}

    #2.4 send request and get response data
    ${response}    saveBinderRfqOrder.Send Request And Get Response Data    ${token}    ${strBody}

    ${response}    Set Variable    ${response.json()}
    ${rfqNo}    Set Variable    ${response}[data][rfqNo]
    ${quoteNo}    Set Variable    ${response}[data][quoteNo]

    #3. create order
    #3.1. getJsonBody
    ${jsonBody}     Set Variable    ${AP_POSITIVE_DATA["placeOrderBody"]}
    #3.2. updateJsonBody
    ${identityNo}=    utilCommon.Generate Random identityNo

    Log     ${identityNo}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.rfqNo    ${rfqNo}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.quoteNo    ${quoteNo}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.quotationDataJson.riskGroupInfo.travel.fromDate    ${effectiveTime}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.quotationDataJson.riskGroupInfo.travel.toDate    ${expireTime}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.quotationDataJson.insuranceInfo.effectiveDate    ${effectiveTime}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.quotationDataJson.insuranceInfo.expiredDate    ${expireTime}
    ${jsonBody}=    Update Value To Json    ${jsonBody}    $.dataFormJson.insuredInfo[0].identityNo    ${identityNo}

    Log     ${jsonBody}

    #3.3. convert jsonBody to string
    ${strBody}  Convert Json To String    ${jsonBody}

    #3.4. send request and get response data
    ${response}    createBinderOrder.Send Request And Get Response Data    ${token}    ${strBody}
    ${jsonResult}   Set Variable    ${response.json()}
    ${orderIds}  Create List    ${jsonResult}[data][orderIdLs]
    ${orderId}  Get From List    ${jsonResult}[data][orderIdLs]    0
    ${orderNo}    Set Variable     ${jsonResult}[data][orderNo]
    Sleep    3s
    ${orderInfo}    Create List     ${orderNo}    ${orderId}
    RETURN   ${orderInfo}




