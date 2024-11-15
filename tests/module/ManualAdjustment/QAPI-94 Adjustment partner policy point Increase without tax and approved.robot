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
Adjustment partner policy point Increase without tax and approved Success
    Given Login Boss Success
    Then Add New Adjustment Partner Special Bonus Without Tax
    Sleep    10
    Then Get Adjustment Task Id
    Sleep    10
    Then Assign Adjustment Task As To Ceo001
    Sleep    10
    Then Approval Adjustment Task

*** Keywords ***
Login Boss Success
    ${data}=  Send boss_userLogin Post Request
    ${fusetoken}=  Get From Dictionary    ${data}  fuseToken
    Set Test Variable    ${fusetoken}  ${fusetoken}

Add New Adjustment Partner Special Bonus Without Tax
    ${body}=  Set Variable    {"totalAmount":${add_bonusAmount},"partnerCode":"99485f35","partnerName":"20241113 qJEitr","partnerMobile":"8123268989","reasonType":"other","transactionType":"policyPoint","walletAccount":"partnerSpecialBonus","flowType":"add","transactionAmount":${add_bonusAmount},"calculateTaxType":"0","distributorCompanyUid":6604000375,"distributorCompany":"PT Pialang Asuransi Indotekno","growthModelCode":"Ge8Ad4nyAQ","rmName":"RM-user1","rmCode":"L5MGKYZ6GGN8Q7","uplineRmCode":"L5MGKYZ6GGN8Q7","requestId":"7b1b0267-555d-4946-a725-cc413044cf80"}
    ${transactionId}=  Send Bonus Adjustment Post Request  ${body}  ${fusetoken}
    Set Test Variable  ${transactionId}  ${transactionId}

Get Adjustment Task Id
    ${TaskId}=  Send Check TaskId Post Request   ${fusetoken}  ${transactionId}
    Set Test Variable    ${TaskId}  ${TaskId}

Assign Adjustment Task As To Ceo001
    Send Adjustment Assign Task Post Request  ${fusetoken}  ${TaskId}

Approval Adjustment Task
    Send Approval Adjustment Post Request  ${fusetoken}  ${TaskId}

