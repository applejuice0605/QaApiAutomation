*** Settings ***
Resource    ../../../resources/api/FusePoint/PointExchange.robot


*** Variables ***
${loginAccount}=    628123268989
${password}=  268989

*** Test Cases ***
Exchange All Fuse Point To Bonus Success
    By Phone Number Login FusePro Success
    Check All Point Amount
    Input Exchange All Point Amount And Click Submit Button


*** Keywords ***
By Phone Number Login FusePro Success
    ${data}=  Get Token And TenantId And OpenId  ${loginAccount}  ${password}
    ${tenantId}=  Get From Dictionary    ${data}  tenantId
    ${token}=  Get From Dictionary    ${data}  token
    Set Test Variable    ${tenantId}   ${tenantId}
    Set Test Variable    ${fusetoken}   ${token}
Check All Point Amount
    ${points}=  Send Check Balance Amount Post Request  ${fusetoken}   ${tenantId}
    Set Test Variable    ${points}  ${points}
    
Input Exchange All Point Amount And Click Submit Button
    # Point Exchange Bonus Amount is 10
    ${body}=  Set Variable    {"amount":${points},"managementCommission":0,"specialBonus":1,"rewardPoint":0,"currency":360}
    Send Point Exchange Post Request  ${fusetoken}  ${body}



