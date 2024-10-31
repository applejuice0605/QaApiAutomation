*** Settings ***
Resource    ../../../resources/lib/Common.robot
Resource    ../../../resources/api/Motor/SaveBinderRFQMotor.robot
Resource    ../../../resources/api/GetQuotation/generateQuotePDF.robot



*** Variables ***
${loginAccount}=  628123268989
${password}=  268989

*** Test Cases ***
Generate Quotation PdfUrl Success
    Given By Phone Number Login FusePro Success  ${loginAccount}   ${password}
    Then Send SaveBinderOrder Post Request
    Then Send GenerateQuoteUrl Post Request

*** Keywords ***
By Phone Number Login FusePro Success
    [Arguments]    ${loginAccount}   ${password}
    ${data}=  Get Token And TenantId And OpenId  ${loginAccount}  ${password}
    ${tenantId}=  Get From Dictionary    ${data}  tenantId
    ${token}=  Get From Dictionary    ${data}  token
    Set Test Variable    ${token}   ${token}

Send SaveBinderOrder Post Request
    ${data}=  Send MotorSaveBinderOrder Post Request  ${token}
    ${quoteNo}=  Get From Dictionary    ${data}   quoteNo
    ${rfqNo}=  Get From Dictionary    ${data}  rfqNo
    Set Test Variable     ${quoteNo}  ${quoteNo}
    Set Global Variable    ${rfqNo}  ${rfqNo}

Send GenerateQuoteUrl Post Request
    ${PDF_url}=  Send MotorGenerateQuotePDF Post Request  ${token}  ${rfqNo}  ${quoteNo}


