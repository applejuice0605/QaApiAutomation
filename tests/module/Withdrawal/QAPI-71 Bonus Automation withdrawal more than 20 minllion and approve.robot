*** Settings ***
Resource    ../../../resources/api/Withdrawal/withdrawal.robot

Resource    ../../../resources/biz/Login/login.robot
Resource    ../../../resources/resource.robot



#Setup Test
Test Setup    Setup Env Variable
Test Teardown    Delete All Sessions

*** Variables ***
${withdrawalAmount}=  20000002
${CheckAccamount}=  8123268987

*** Test Cases ***
Withdrawal Amount More Than 20000000 Success
    [Tags]    uat
    Given Have logined fusepro and boss
    Then Input Withdrawal Amount More Than 20000000 And Send Withdrawal Application
    Then Confirm Manual Process And Get ManualId
    Sleep   10
    Then Check Withdrawal Verification TaskId
    Then Enter Task Mgmt And Assign Withdrawal Verification To Ceo001
    Then Enter Task And Review Withdrawal Verification
    Sleep   10
    Then Check Withdrawal Payment TaskId
    Then Enter Task Mgmt And Assign Withdrawal Payment To Ceo001
    Then Enter Task And Confirm Withdrawal Payment


*** Keywords ***
Have logined fusepro and boss
    ${fuseToken}=   login.Login to Application using mobile     ${env_vars}[FUSE_ACCOUNT]    ${env_vars}[FUSE_PASSWORD]
    Set Test Variable    ${fuseToken}
    Set Test Variable    ${tenantId}   1000662
    ${bossToken}=   login.Login to Boss     ${env_vars}[BOSS_ACCOUNT]    ${env_vars}[BOSS_PASSWORD]
    Set Test Variable    ${bossToken}



Input Withdrawal Amount More Than 20000000 And Send Withdrawal Application
    Send Withdrawal Post Request  ${fuseToken}   ${tenantId}  ${loginAccount}  ${withdrawalAmount}  ${password}

Confirm Manual Process And Get ManualId
    ${data}=  Send Manual withdrawal Post Rquest  ${fuseToken}   ${tenantId}  ${loginAccount}  ${withdrawalAmount}  ${password}
    Set Test Variable    ${withdrawalId}  ${data}


Check Withdrawal Verification TaskId
    ${data}=  Send Check Manual Withdrawal TaskId Post Request   ${bossToken}  ${withdrawalId}
    Set Test Variable    ${taskId}  ${data}
    
Enter Task Mgmt And Assign Withdrawal Verification To Ceo001
    Send Withdrawal Verification Assign To Me Post Request   ${bossToken}   ${taskId}

Enter Task And Review Withdrawal Verification
    Send Withdrawal Review Post Request    ${bossToken}   ${taskId}  ${withdrawalId}

Check Withdrawal Payment TaskId
    ${data}=  Send Check Payment Withdrawal TaskId Post Request     ${bossToken}  ${withdrawalId}
    Set Test Variable    ${PaymentTaskId}  ${data}

Enter Task Mgmt And Assign Withdrawal Payment To Ceo001
    Send Withdrawal Payment Assign To Me Post Request  ${bossToken}   ${PaymentTaskId}
Enter Task And Confirm Withdrawal Payment
    Send Withdrawal Payment Confirm Post Request   ${bossToken}   ${PaymentTaskId}  ${withdrawalId}

    


