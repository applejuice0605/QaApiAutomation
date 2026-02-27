*** Settings ***
Resource    ../../../resources/api/Withdrawal/withdrawal.robot


Resource    ../../../resources/biz/Login/login.robot

Resource    ../../../resources/util/utilCommon.robot
Resource    ../../../resources/util/assertUtil.robot
Resource    ../../../resources/resource.robot


#Setup Test
Test Setup    Setup Env Variable
Test Teardown    Delete All Sessions


*** Test Cases ***
Withdrawal Amount Less Than 20000000 Success
    [Tags]    notUsed
    Given I have logined
    Input Withdrawal Amount Less Than 20000000 And Send Withdrawal Application

*** Keywords ***
I have logined
    ${token}=   login.Login to Application using mobile     ${env_vars}[FUSE_ACCOUNT]    ${env_vars}[FUSE_PASSWORD]
    Set Test Variable    ${token}    ${token}


Input Withdrawal Amount Less Than 20000000 And Send Withdrawal Application
    Send Withdrawal Post Request  ${fusetoken}   ${tenantId}  ${loginAccount}  ${withdrawalAmount}  ${password}
    