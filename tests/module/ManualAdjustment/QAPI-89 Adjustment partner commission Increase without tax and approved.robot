*** Settings ***
Library    Collections
Library    BuiltIn
Library    OperatingSystem
Resource    ../../../resources/api/ManualAdjustment/BonusAdjustment.robot
Resource    ../../../resources/Boss/LoginBoss/LoginBoss.robot



*** Variables ***
${loginAccount}=  ceo001
${password}=  Fuse!001
${add_bonusAmount}=  100000

*** Test Cases ***
Adjustment Partner Commission Increase Without Tax and Approved Success
    Given Login Boss Success
    Then Add New Adjustment Partner Commission Without Tax
    Sleep    6
    Then Get Adjustment Task Id
    Sleep    6
    Then Assign Adjustment Task As To Ceo001
    Sleep    6
    Then Approval Adjustment Task

*** Keywords ***
Login Boss Success
    ${data}=  Send boss_userLogin Post Request
    ${fusetoken}=  Get From Dictionary    ${data}  fuseToken
    Set Test Variable    ${fusetoken}  ${fusetoken}
    
Add New Adjustment Partner Commission Without Tax
    ${body}=  Set Variable    {"totalAmount":${add_bonusAmount},"partnerCode":"99485f35","partnerName":"Partner 989","partnerMobile":"8123268989","reasonType":"other","transactionType":"policyBonus","walletAccount":"partnerCommission","flowType":"add","transactionAmount":${add_bonusAmount},"calculateTaxType":"0","distributorCompanyUid":6604000375,"distributorCompany":"PT Pialang Asuransi Indotekno","growthModelCode":"Ge8Ad4nyAQ","rmName":"RM-user1","rmCode":"L5MGKYZ6GGN8Q7","uplineRmCode":"L5MGKYZ6GGN8Q7","requestId":"e5caed2d-a099-4797-bf24-92c4bf232f48"}
    ${transactionId}=  Send Bonus Adjustment Post Request  ${body}  ${fusetoken}
    Set Test Variable  ${transactionId}  ${transactionId}

Get Adjustment Task Id
    ${TaskId}=  Send Check TaskId Post Request   ${fusetoken}  ${transactionId}
    Set Test Variable    ${TaskId}  ${TaskId}

Assign Adjustment Task As To Ceo001
    Send Adjustment Assign Task Post Request  ${fusetoken}  ${TaskId}

Approval Adjustment Task
    Send Approval Adjustment Post Request  ${fusetoken}  ${TaskId}
