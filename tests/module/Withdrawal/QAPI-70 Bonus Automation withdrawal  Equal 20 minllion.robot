*** Settings ***
Resource    ../../../resources/api/Withdrawal/withdrawal.robot


*** Variables ***
${loginAccount}=    628123268989
${password}=  268989
${withdrawalAmount}=  20000000

*** Test Cases ***
Withdrawal Amount Equal 20000000 Success
    By Phone Number Login FusePro Success
    Input Withdrawal Amount Equal 20000000 And Send Withdrawal Application

*** Keywords ***
By Phone Number Login FusePro Success
    ${data}=  Get Token And TenantId And OpenId  ${loginAccount}  ${password}
    ${tenantId}=  Get From Dictionary    ${data}  tenantId
    ${token}=  Get From Dictionary    ${data}  token
    Set Test Variable    ${tenantId}   ${tenantId}
    Set Test Variable    ${fusetoken}   ${token}

Input Withdrawal Amount Equal 20000000 And Send Withdrawal Application
    Send Withdrawal Post Request  ${fusetoken}   ${tenantId}  ${loginAccount}  ${withdrawalAmount}  ${password}

