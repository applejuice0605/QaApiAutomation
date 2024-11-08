*** Settings ***
Resource    ../../../resources/api/Withdrawal/withdrawal.robot
Resource    ../../../resources/Boss/LoginBoss/LoginBoss.robot
Test Teardown    Delete All Sessions

*** Variables ***
${loginAccount}=    628123268987
${password}=  268987
${withdrawalAmount}=  20000002
${CheckAccamount}=  8123268987

*** Test Cases ***
Withdrawal Amount More Than 20000000 And Decline Success
    Given By Phone Number Login FusePro Success
    Then Input Withdrawal Amount More Than 20000000 And Send Withdrawal Application
    Then Confirm Manual Process And Get ManualId
    Sleep   10
    Then Login Boss And Get FuseToken
    Then Check Withdrawal Verification TaskId
    Then Enter Task Mgmt And Assign Withdrawal Verification To Ceo001
    Then Enter Task And Withdrawal Verification And Decline



*** Keywords ***
By Phone Number Login FusePro Success
    ${data}=  Get Token And TenantId And OpenId  ${loginAccount}  ${password}
    ${tenantId}=  Get From Dictionary    ${data}  tenantId
    ${token}=  Get From Dictionary    ${data}  token
    Set Test Variable    ${tenantId}   ${tenantId}
    Set Test Variable    ${token}   ${token}

Input Withdrawal Amount More Than 20000000 And Send Withdrawal Application
    Send Withdrawal Post Request  ${token}   ${tenantId}  ${loginAccount}  ${withdrawalAmount}  ${password}

Confirm Manual Process And Get ManualId
    ${data}=  Send Manual withdrawal Post Rquest  ${token}   ${tenantId}  ${loginAccount}  ${withdrawalAmount}  ${password}
    Set Test Variable    ${withdrawalId}  ${data}

Login Boss And Get FuseToken
    ${data}=  Send boss_userLogin Post Request
    ${fuseToken}=  Get From Dictionary    ${data}  fuseToken
    Set Test Variable    ${fuseToken}  ${fuseToken}

Check Withdrawal Verification TaskId
    ${data}=  Send Check Manual Withdrawal TaskId Post Request   ${fusetoken}  ${withdrawalId}
    Set Test Variable    ${taskId}  ${data}

Enter Task Mgmt And Assign Withdrawal Verification To Ceo001
    Send Withdrawal Verification Assign To Me Post Request   ${fusetoken}   ${taskId}

Enter Task And Withdrawal Verification And Decline
    Send Withdrawal Review Decline Post Request    ${fusetoken}   ${taskId}  ${withdrawalId}






