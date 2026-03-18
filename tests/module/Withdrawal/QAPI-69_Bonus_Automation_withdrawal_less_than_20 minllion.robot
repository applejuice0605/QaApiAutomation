*** Settings ***
Resource    ../../../resources/biz/Login/login.robot
Resource    ../../../resources/biz/Withdrawal/withdrawal.robot

Resource    ../../../resources/util/utilCommon.robot
Resource    ../../../resources/util/assertUtil.robot
Resource    ../../../resources/resource.robot


#Setup Test
Test Setup    Setup Env Variable
Test Teardown    Delete All Sessions


*** Variables ***
${withdrawalAmount}=  100000
${fuseproAccount}=     628123268987
${fuseproPwd}=    268987Aa!
# ${fuseproAccount}=     628527246077
# ${fuseproPwd}=    n5BGcO8

*** Test Cases ***
Withdrawal Amount Less Than 20000000 Success
    [Tags]    uat    withdrawal
    Given I have logined
    When I have verified band account and enough Balance
    Then Input Withdrawal Amount Less Than 20000000 And Send Withdrawal Application
    Then The response should contain the withdrawalId    ${jsonResult}
    Then After Withdrawal, check Bonus Decrease 10000000 Success

*** Keywords ***
I have logined
    ${fusetoken}=   login.Login to Application using mobile     ${fuseproAccount}    ${fuseproPwd}
    Set Test Variable    ${fusetoken}    ${fusetoken}

I have verified band account and enough Balance
    # 检查银行卡是否有效
    ${bankAccountNumber}    ${bankUid}    ${bankName}=    withdrawal.Get Valid Bank Card    ${fusetoken}
    Set Test Variable    ${bankAccountNumber}    ${bankAccountNumber}
    Set Test Variable    ${bankUid}    ${bankUid}
    Set Test Variable    ${bankName}    ${bankName}
    # 是否余额是否大于要提现的金额
    Check Balance Is Enough    ${fusetoken}    ${withdrawalAmount}


Input Withdrawal Amount Less Than 20000000 And Send Withdrawal Application
    ${jsonResult}=    Send Auto Withdrawal Post Request    ${fusetoken}    ${bankAccountNumber}    ${bankUid}    ${bankName}    ${withdrawalAmount}
    Set Test Variable    ${jsonResult}    ${jsonResult}
    
After Withdrawal, check Bonus Decrease 10000000 Success
    Check Bonus History List should contain Withdrawal Id And Correct Amount and status    ${fusetoken}    ${withdrawalId}    ${withdrawalAmount}    False

    