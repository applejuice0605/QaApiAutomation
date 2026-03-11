*** Settings ***
Resource    ../../../resources/biz/Withdrawal/withdrawal.robot
Resource    ../../../resources/biz/Login/login.robot
Resource    ../../../resources/resource.robot
Resource    ../../../resources/api/Withdrawal/withdrawal.robot
Resource    ../KTP_Verfification/QAPI-5_Core_KTP_Verfication.robot



#Setup Test
Test Setup    Setup Env Variable
Test Teardown    Delete All Sessions

*** Variables ***
${withdrawalAmount}=  20000002
${CheckAccamount}=  8123268987

*** Test Cases ***
Withdrawal Amount More Than 20000000 And Approve Success
    [Tags]    uat    withdrawal
    Given Have logined fusepro and boss
    When I have verified band account and enough Balance
    Then Input Withdrawal Amount More Than 20000000 And Send Withdrawal Application
    # 响应应该包含超限提示，是否使用手动提现方式继续
    Then the response should exceeded-limit prompt and prompt use manual withdrawal    ${jsonResult}
    # 确认提交手动提现请求
    Then Confirm Send Manual Process
    Then The response should contain the withdrawalId    ${jsonResult}
    Sleep   10
    # 进入提现verification流程
    [Task Mgmt] Use withdrawalId Searching in Withdrawal Verification Task Mgmt List and Get taskId    ${bossToken}    ${withdrawalId}
    # 将任务指派给我
    Assign the Task To Me    ${bossToken}    ${taskId}
    # 在任务界面获取Task
    [Task] Use withdrawalId Searching in Withdrawal Verification Task List and Get taskId    ${bossToken}    ${withdrawalId}
    # 提交Approve
    [Withdrawal Verification] Approve Withdrawal Verification Task    ${bossToken}    ${withdrawalId}    ${taskId}
    Sleep   10
    # 进入提现打款流程
    [Task Mgmt] Use withdrawalId Searching in Withdrawal Payment Task Mgmt List and Get taskId    ${bossToken}    ${withdrawalId}
    # 将任务指派给我
    Assign the Task To Me    ${bossToken}    ${taskId}
    # 在任务界面获取Task
    [Task] Use withdrawalId Searching in Withdrawal Payment Task List and Get taskId    ${bossToken}    ${withdrawalId}
    # 提交Approve
    [Withdrawal Payment] Approve Withdrawal Payment Task    ${bossToken}    ${withdrawalId}    ${taskId}

    # 检查Fusepro流水记录，是否提现成功
    Check Bonus History List should contain Withdrawal Id And Correct Amount and status    ${fusetoken}    ${withdrawalId}    ${withdrawalAmount}    False
    

*** Keywords ***
Have logined fusepro and boss
    ${fuseToken}=   login.Login to Application using mobile     ${env_vars}[FUSE_ACCOUNT]    ${env_vars}[FUSE_PASSWORD]
    Set Test Variable    ${fuseToken}
    Set Test Variable    ${tenantId}   1000662
    ${bossToken}=   login.Login to Boss     ${env_vars}[BOSS_ACCOUNT]    ${env_vars}[BOSS_PASSWORD]
    Set Test Variable    ${bossToken}

I have verified band account and enough Balance
    # 检查银行卡是否有效
    ${bankAccountNumber}    ${bankUid}    ${bankName}=    withdrawal.Get Valid Bank Card    ${fusetoken}
    Set Test Variable    ${bankAccountNumber}    ${bankAccountNumber}
    Set Test Variable    ${bankUid}    ${bankUid}
    Set Test Variable    ${bankName}    ${bankName}
    # 是否余额是否大于要提现的金额
    Check Balance Is Enough    ${fusetoken}    ${withdrawalAmount}







Input Withdrawal Amount More Than 20000000 And Send Withdrawal Application
    ${jsonResult}=    Send Auto Withdrawal Post Request    ${fusetoken}    ${bankAccountNumber}    ${bankUid}    ${bankName}    ${withdrawalAmount}
    Set Test Variable    ${jsonResult}    ${jsonResult}
the response should exceeded-limit prompt and prompt use manual withdrawal
    [Arguments]    ${jsonResult}
    ${message}=    Set Variable    ${jsonResult}[data][message]
    Should Be Equal    ${message}    You have exceeded daily instant withdrawal limit, you can only proceed the withdrawal by using manual disbursement. This process will take two working days maximum.
    


Confirm Send Manual Process
    ${jsonResult}=    Send Manual Withdrawal Post Request    ${fusetoken}    ${bankAccountNumber}    ${bankUid}    ${bankName}    ${withdrawalAmount}
    Set Test Variable    ${jsonResult}    ${jsonResult}







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

    


