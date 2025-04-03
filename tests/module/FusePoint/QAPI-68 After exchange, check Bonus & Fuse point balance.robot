*** Settings ***
Resource    ../../../resources/api/FusePoint/PointExchange.robot


*** Variables ***
${loginAccount}=    628123268989
${password}=  268989

*** Test Cases ***
Trigger Point Exchange
    [Tags]  notUsed
    By Phone Number Login FusePro Success
    Input Exchange Amount 10 And Click Submit Button

After exchange, check Bonus & Fuse point balance Success
    By Phone Number Login FusePro Success
    Check Bonus Fuse Point Balance


*** Keywords ***
By Phone Number Login FusePro Success
    ${data}=  Get Token And TenantId And OpenId  ${loginAccount}  ${password}
    ${tenantId}=  Get From Dictionary    ${data}  tenantId
    ${token}=  Get From Dictionary    ${data}  token
    Set Test Variable    ${tenantId}   ${tenantId}
    Set Test Variable    ${fusetoken}   ${token}

Input Exchange Amount 10 And Click Submit Button
    # Point Exchange Bonus Amount is 10
    ${body}=  Set Variable    {"amount":10,"managementCommission":0,"specialBonus":1,"rewardPoint":0,"currency":360}
    Send Point Exchange Post Request  ${fusetoken}  ${body}

Check Bonus Fuse Point Balance
    ${body}=  Set Variable    {"mobile":"${loginAccount}","pageSize":"10","pageNo":0,"queryCotFlag":"true","controlAccount":"5","language":"en_US","isUpper":"no"}
    ${response}=  Send Check Balance Post Request  ${fusetoken}   ${tenantId}  ${body}
    ${get_json}=  Get From Dictionary    ${response.json()}  data
    ${get_data}=  Get From Dictionary    ${get_json}  data
    ${get_dirt}=  Get From List        ${get_data}  0
    ${transactionName}=  Get From Dictionary          ${get_dirt}  transactionName
    ${tradeAmount}=  Get From Dictionary    ${get_dirt}  tradeAmount
    ${tradeAmount}=  Evaluate    int(${tradeAmount})
    # 断言 判断transactionName 是否为Points Exchange 和 tradeAmount 是否等于10
    Should Be Equal As Strings    ${transactionName}  Points Exchange
    Should Be Equal As Integers    ${tradeAmount}  10
    





