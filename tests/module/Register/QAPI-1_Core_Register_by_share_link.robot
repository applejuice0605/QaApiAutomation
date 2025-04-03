*** Settings ***
Library    RequestsLibrary
Library    Collections
Library    String
Library    XML
Library    os

Resource    ../../../resources/api/Login/api_bylogin.robot
Resource    ../../../resources/api/Login/api_login.robot
Resource    ../../../resources/api/Profile/updateProfile.robot
Resource    ../../../resources/biz/Login/agent.robot
Resource    ../../../resources/biz/Login/login.robot
Library     ../../../resources/lib/SignGenerator.py

Resource    ../../../resources/resource.robot

Resource    ../../../resources/api/Profile/partner.robot



Resource    ../../../resources/api/Registration/partner_invited_get_url.robot
Resource    ../../../resources/api/Registration/verificationCode_send.robot
Resource    ../../../resources/api/Registration/partner_register.robot

Resource    ../../../resources/util/assertUtil.robot
Resource    ../../../resources/util/dbUtil.robot




#Setup Test
#优化：Suite Setup    Suite启动应改为获取前置操作里面的数据
Test Setup    Setup Env Variable
Test Teardown    Delete All Sessions


*** Test Cases ***
Core - Register by share link
    [Tags]    uatAndprod
    Given I have a valid login account and password and a unregisted mobile number
    When I Click button Invite Friend
    Then The status code should be 200    ${jsonResult}[code]
    And The response should contain the invite link and inviteOpenId    ${jsonResult}
    Then I send get verification code request for the mobile number
    Then The status code should be 200    ${jsonResult}[code]
    And The DB should have a verification code for the mobile number
    Then Send register request
    Then The status code should be 200    ${jsonResult}[code]



*** Keywords ***
I have a valid login account and password and a unregisted mobile number
    # 调用登录接口
    ${token}=   login.Login to Application using mobile     ${env_vars}[FUSE_ACCOUNT]    ${env_vars}[FUSE_PASSWORD]
    Set Test Variable    ${token}
    # 随机生成mobile number
    ${mobile}=   Evaluate    ''.join([str(random.randint(0, 9)) for _ in range(10)])    modules=random
    Log    ${mobile}
    Set Test Variable    ${mobile}

I Click button Invite Friend
    ${response}  partner_invited_get_url.Send Request And Get Response Data    ${token}
    Set Test Variable    ${jsonResult}    ${response.json()}
    Log    ${jsonResult}

The response should contain the invite link and inviteOpenId
    [Arguments]     ${jsonResult}
    Should Contain    ${jsonResult}[data]   invitedUrl
    Set Test Variable    ${inviteOpenId}    ${jsonResult}[data][inviteOpenId]


I send get verification code request for the mobile number
    ${response}     verificationCode_send.Send Request And Get Response Data    ${mobile}
    Set Test Variable    ${jsonResult}    ${response.json()}
    Log    ${jsonResult}

The DB should have a verification code for the mobile number
    ${sms_code}=    dbUtil.Get Invite Link SMS Code     ${mobile}
    Log    ${sms_code}
    Set Test Variable   ${sms_code}

Send register request
    ${response}  partner_register.Send Request And Get Response Data    ${mobile}   ${sms_code}  ${inviteOpenId}

#Register by share link
#    [Arguments]    ${token}     ${mobile}
#    ${response}  partner_invited_get_url.Send Request And Get Response Data    ${token}
#    ${inviteOpenId}   Set Variable     ${resonse.json()}[data][inviteOpenId]
#
#    verificationCode_send.Send Request And Get Response Data    ${mobile}
#
#    ${response}  partner_register.Send Request And Get Response Data    ${token}     ${mobile}    ${inviteOpenId}
#    ${tenantId}   Set Variable     ${resonse.json()}[data][0][tenantId]
#
#
#
#












#I have a valid login account and password and a unregisted mobile number
#    Set Test Variable    ${loginAccount}    628123268987
#    Set Test Variable    ${password}    268987
#    ${random_5num}   Generate Random String    5    [Letters]
#    ${OPTIONS}  Set Variable    {"name":"20241031 edit${random_5num}","mobile":"628188666666","occupationInfo":{"id":"12","other":""},"locationInfo":{"id":"1"},"city":"Kota Jakarta Selatan","postCode":"12345","province":"DKI Jakarta","address":"","addressId":"1464"}
#    ${OPTIONS}   Convert String To Json    ${OPTIONS}
#    ${sign}     Generate Sign    ${OPTIONS}
#    Set Test Variable    ${sign}
#    Log To Console    ${sign}
#
#    ${token}    login.Login to Application using mobile
#    Set Test Variable    ${token}
#    Set Test Variable    ${inviteCode}  FBRCME7Z
#
#
#
#
#
#I send a request to register by share link
#    ${response}    partner.Send register_getShortLink Request And Get Response Data    ${token}    ${inviteCode}
#    Should Contain    ${response.json()}[resultObj]    copyLink
#
#    Set Test Variable    ${link}    ${response.json()}[resultObj][copyLink]














I send a request to register by share link2
    Should Be Equal As Strings    ${jsonResult}[data][0][tenantId]    1000662
    Should Not Be Equal As Strings    ${jsonResult}[data][0][openId]    null
    Set Test Variable    ${openId}  ${jsonResult}[data][0][openId]
    Set Test Variable    ${tenantId}  ${jsonResult}[data][0][tenantId]


I send a POST request to the Login API
    ${response}    api_login.Send Request And Get Response Data    ${loginAccount}    ${password}    ${openId}    ${tenantId}
    Set Test Variable    ${jsonResult}    ${response.json()}
    Log    ${jsonResult}

The response should contain the user's token
    Should Not Be Equal As Strings    ${jsonResult}[data][token]    null
    Set Global Variable    ${token}     ${jsonResult}[data][token]
