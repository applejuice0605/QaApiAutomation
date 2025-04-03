*** Settings ***
Library    Collections
Library    BuiltIn
Library    OperatingSystem
Resource    ../../../resources/lib/Common.robot
Resource    ../../../resources/api/Setting/UserLogout.robot


*** Variables ***
${loginAccount}=  628123268989
${password}=  268989

*** Test Cases ***
Logout by phone number
#    Given Login FusePro Success
    Given By Phone Number Login FusePro Success  ${loginAccount}   ${password}
    When Logout FusePro By Phone Number

*** Keywords ***
By Phone Number Login FusePro Success
    [Arguments]    ${loginAccount}   ${password}
    ${data}=  Get Token And TenantId And OpenId  ${loginAccount}  ${password}
    ${tenantId}=  Get From Dictionary    ${data}  tenantId
    ${token}=  Get From Dictionary    ${data}  token
    Set Test Variable    ${tenantId}   ${tenantId}
    Set Test Variable    ${token}   ${token}

Logout FusePro By Phone Number
    Send UserLogout Post Request  ${tenantId}  ${token}
