*** Settings ***
Resource    ../../../resources/api/order/generateQuotePDF.robot

*** Keywords ***
I send the go quotation pdf request to generateQuotePDF API
    [Arguments]     ${token}    ${rfqNo}    ${quoteNo}
    Sleep    3s
    ${response}    generateQuotePDF.Send Request And Get Response Data    ${token}    ${rfqNo}    ${quoteNo}

    Set Test Variable    ${jsonResult}    ${response.json()}


the response should contain the value of pdfFileUrl
    Should Contain    ${jsonResult}[data]   pdfFileUrl
    Log     ${jsonResult}[data][pdfFileUrl]