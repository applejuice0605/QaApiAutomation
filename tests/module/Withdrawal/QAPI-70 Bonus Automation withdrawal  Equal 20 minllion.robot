*** Settings ***
Resource    ../../../resources/api/Withdrawal/withdrawal.robot
Resource    ../../../resources/biz/Login/login.robot
Resource    ../../../resources/resource.robot

#Setup Test
Test Setup    Setup Env Variable
Test Teardown    Delete All Sessions

*** Variables ***
${withdrawalAmount}=  20000000

*** Test Cases ***
Withdrawal Amount Equal 20000000 Success
    Have logined
    Input Withdrawal Amount Equal 20000000 And Send Withdrawal Application

*** Keywords ***
Have logined
    ${fuseToken}=   login.Login to Application using mobile     ${env_vars}[FUSE_ACCOUNT]    ${env_vars}[FUSE_PASSWORD]
    Set Test Variable    ${fuseToken}
    Set Test Variable    ${tenantId}   1000662


Input Withdrawal Amount Equal 20000000 And Send Withdrawal Application
    Send Withdrawal Post Request  ${fusetoken}   ${tenantId}  ${loginAccount}  ${withdrawalAmount}  ${password}

