*** Settings ***
Resource    ../../lib/Common.robot

*** Variables ***
${session}=  userLogoutSession
${url}=  https://app-uat.fuseinsurtech.com/insurance-finance-vs-api/api/fuse/user/logout


*** Keywords ***
Send UserLogout Post Request
    [Arguments]    ${tenantId}  ${token}
    ${body}=  Set Variable    {"model":"Android","deviceType":"Android","vision":"5.27.2.0-uat","osVision":"12","phoneModel":"","deviceId":"","appVersion":"5.27.2.0-uat","systemVersion":"12","phoneType":"","netType":""}
    &{headers}=  Create Dictionary   Content-Type=application/json  tenantId="${tenantId}"  fusetoken=${token}  language="en_US"
    ${response}=  Common.Send Post Request And Get Response Data  ${session}  ${url}  ${body}  &{headers}
