*** Settings ***
Library    RequestsLibrary
Library     OperatingSystem
Library     Collections
Library     BuiltIn
Library    OperatingSystem
Library     BuiltIn
Resource    ../../lib/Common.robot

*** Variables ***
${generateQuotePDF_url}=  https://ptr-uat.fuse.co.id/api/local/quote/generateQuotePDF
${session}=  generateQuotePDFSession


*** Keywords ***
Send CarGenerateQuotePDF Post Request
    [Arguments]    ${token}  ${rfq}  ${quoteNo}
    &{headers}=  Create Dictionary    Content-Type=application/json  fusetoken=${token}  language=en_US
    ${body}=  Set Variable    {"insuredName":"GetCarApi","rfqNo":"${rfq}","quoteNo":"${quoteNo}"}

    ${response}=  Common.Send Post Request And Get Response Data  ${session}  ${generateQuotePDF_url}  ${body}  &{headers}
    ${get_json}=  Set Variable    ${response.json()}
    ${get_data}=  Get From Dictionary    ${get_json}  data
    ${pdf_url}=  Get From Dictionary    ${get_data}  pdfFileUrl
    RETURN  ${pdf_url}

Send MotorGenerateQuotePDF Post Request
    [Arguments]    ${token}  ${rfq}  ${quoteNo}
    &{headers}=  Create Dictionary    Content-Type=application/json  fusetoken=${token}  language=en_US
    ${body}=  Set Variable    {"insuredName":"TestApi","rfqNo":"${rfq}","quoteNo":"${quoteNo}"}

    ${response}=  Common.Send Post Request And Get Response Data  ${session}  ${generateQuotePDF_url}  ${body}  &{headers}
    ${get_json}=  Set Variable    ${response.json()}
    ${get_data}=  Get From Dictionary    ${get_json}  data
    ${pdf_url}=  Get From Dictionary    ${get_data}  pdfFileUrl
    RETURN  ${pdf_url}