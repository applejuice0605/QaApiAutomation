*** Settings ***
Resource    ../../../resources/api/Withdrawal/withdrawal.robot
#Resource    ../../../resources/Boss/LoginBoss/LoginBoss.robot
Test Teardown    Delete All Sessions

*** Variables ***
${loginAccount}=    628123261286
${password}=  268988
${withdrawalAmount}=  10000000
${CheckAccamount}=  8123268988

*** Test Cases ***
Add Bank Account not meed the condition of API, status is failed
    Given By Phone Number Login FusePro Success
    Then Add Bank Account
    Then Check Bank Account Is Failed



*** Keywords ***
By Phone Number Login FusePro Success
    ${data}=  Get Token And TenantId And OpenId  ${loginAccount}  ${password}
    ${tenantId}=  Get From Dictionary    ${data}  tenantId
    ${token}=  Get From Dictionary    ${data}  token
    Set Test Variable    ${tenantId}   ${tenantId}
    Set Test Variable    ${token}   ${token}

Add Bank Account
    Add Bank Account Not Meed The Condition Of Api Failed  ${token}

Check Bank Account Is Failed
    Send Check Bank Account Status Post Request  ${token}  ${tenantId}  ${loginAccount}  ${withdrawalAmount}  ${password}





