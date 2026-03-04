*** Settings ***
Resource    ../../../resources/api/Withdrawal/withdrawal.robot
Resource    ../../../resources/biz/Login/login.robot
Resource    ../../../resources/resource.robot


#Setup Test
Test Setup    Setup Env Variable
Test Teardown    Delete All Sessions

*** Variables ***
${withdrawalAmount}=  10000000
${CheckAccamount}=  8123268988

*** Test Cases ***
Add Bank Account not meed the condition of API, status is failed
    [Tags]    uat
    Given Have logined fusepro and boss
    Then Add Bank Account
    Then Check Bank Account Is Failed



*** Keywords ***
Have logined fusepro and boss
    ${fuseToken}=   login.Login to Application using mobile     ${env_vars}[FUSE_ACCOUNT]    ${env_vars}[FUSE_PASSWORD]
    Set Test Variable    ${fuseToken}
    Set Test Variable    ${tenantId}   1000662
    ${bossToken}=   login.Login to Boss     ${env_vars}[BOSS_ACCOUNT]    ${env_vars}[BOSS_PASSWORD]
    Set Test Variable    ${bossToken}

Add Bank Account
    Add Bank Account Not Meed The Condition Of Api Failed  ${fuseToken}

Check Bank Account Is Failed
    Send Check Bank Account Status Post Request  ${fuseToken}  ${tenantId}  ${loginAccount}  ${withdrawalAmount}  ${password}





