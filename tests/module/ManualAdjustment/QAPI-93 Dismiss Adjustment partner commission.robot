*** Settings ***
Library    Collections
Library    BuiltIn
Library    OperatingSystem
Resource    ../../../resources/api/ManualAdjustment/BonusAdjustment.robot
Resource    ../../../resources/Boss/LoginBoss/LoginBoss.robot



*** Variables ***
${loginAccount}=  ceo001
${password}=  Fuse!001
${reduce_bonusAmount}=  100000

*** Test Cases ***
Dismiss Adjustment partner commission Success
    Given Login Boss Success
    Then Add New Adjustment Partner Commission With Tax
    Sleep    10
    Then Get Adjustment Task Id
    Sleep    10
    Then Assign Adjustment Task As To Ceo001
    Sleep    10
    Then Decline Adjustment Task

*** Keywords ***
Login Boss Success
    ${data}=  Send boss_userLogin Post Request
    ${fusetoken}=  Get From Dictionary    ${data}  fuseToken
    Set Test Variable    ${fusetoken}  ${fusetoken}

Add New Adjustment Partner Commission With Tax
    ${body}=  Set Variable    {"totalAmount":${reduce_bonusAmount},"partnerCode":"99485f35","partnerName":"Partner 989","partnerMobile":"8123268989","reasonType":"other","transactionType":"policyBonus","walletAccount":"partnerCommission","flowType":"reduce","transactionAmount":${reduce_bonusAmount},"calculateTaxType":"1","distributorCompanyUid":6604000375,"distributorCompany":"PT Pialang Asuransi Indotekno","growthModelCode":"Ge8Ad4nyAQ","rmName":"RM-user1","rmCode":"L5MGKYZ6GGN8Q7","uplineRmCode":"L5MGKYZ6GGN8Q7","requestId":"5a6f728d-6f20-410d-877d-7c4a709e33d0"}
    ${transactionId}=  Send Bonus Adjustment Post Request  ${body}  ${fusetoken}
    Set Test Variable  ${transactionId}  ${transactionId}

Get Adjustment Task Id
    ${TaskId}=  Send Check TaskId Post Request   ${fusetoken}  ${transactionId}
    Set Test Variable    ${TaskId}  ${TaskId}

Assign Adjustment Task As To Ceo001
    Send Adjustment Assign Task Post Request  ${fusetoken}  ${TaskId}

Decline Adjustment Task
    Send Decline Adjustment Post Request  ${fusetoken}  ${TaskId}




