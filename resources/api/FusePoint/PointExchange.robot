*** Settings ***
Resource    ../../lib/Common.robot

*** Variables ***
${PointExchangeUrl}=  https://ptr-uat.fuse.co.id/api/account/points/exchange/v3
${checkBalanceAmountUrl}=  https://ptr-uat.fuse.co.id/api/account/queryBalance/v3
${queryBalanceUrl}=  https://ptr-uat.fuse.co.id/api/account/flow/list/v2
*** Keywords ***
Send Point Exchange Post Request
    [Arguments]  ${fusetoken}  ${body}
    ${headers}=  Create Dictionary     Content-Type=application/json   fusetoken=${fusetoken}  language=en_US
    ${response}=  Common.Send Post Request And Get Response Data  PointExchangeSession  ${PointExchangeUrl}  ${body}  &{headers}
    RETURN  ${response}
Send Check Balance Amount Post Request
    [Arguments]  ${fusetoken}   ${tenantId}
    ${headers}=  Create Dictionary     Content-Type=application/json   fusetoken=${fusetoken}  language=en_US  clientType=ANDROID  appCode=IDP_FUSE_PRO  tenantId="${tenantId}"
    ${body}=  Set Variable    {}
    ${response}=  Common.Send Post Request And Get Response Data  queryBalance  ${checkBalanceAmountUrl}  ${body}  &{headers}
    ${get_json}=  Get From Dictionary    ${response.json()}  data
    ${points}=  Get From Dictionary    ${get_json}  points
    RETURN  ${points}

Send Check Balance Post Request
    [Arguments]  ${fusetoken}   ${tenantId}  ${body}
    ${headers}=  Create Dictionary     Content-Type=application/json   fusetoken=${fusetoken}  language=en_US  clientType=ANDROID  appCode=IDP_FUSE_PRO  tenantId="${tenantId}"
    ${response}=  Common.Send Post Request And Get Response Data  checkBalance  ${queryBalanceUrl}  ${body}  &{headers}
    RETURN   ${response}
