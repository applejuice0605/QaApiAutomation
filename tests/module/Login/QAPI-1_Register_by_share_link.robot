*** Settings ***
Library    RequestsLibrary
Library    Collections
Library    String
Library    XML

Resource    ../../../resources/api/Login/api_bylogin.robot
Resource    ../../../resources/api/Login/api_login.robot
Resource    ../../../resources/api/Profile/updateProfile.robot
Resource    ../../../resources/biz/Login/agent.robot
Resource    ../../../resources/biz/Login/login.robot
Library     ../../../resources/lib/SignGenerator.py


Resource    ../../../resources/api/Profile/partner.robot




#Setup Test
#优化：Suite Setup    Suite启动应改为获取前置操作里面的数据
Suite Teardown    Delete All Sessions


*** Test Cases ***
Register by share link
    [Tags]    uatAndprod
    Given I have a valid login account and password
    When I send a request to register by share link
#    Then The response should contain the user's sign



*** Keywords ***
I have a valid login account and password
    Set Test Variable    ${loginAccount}    628123268987
    Set Test Variable    ${password}    268987
    ${random_5num}   Generate Random String    5    [Letters]
    ${OPTIONS}  Set Variable    {"name":"20241031 edit${random_5num}","mobile":"628188666666","occupationInfo":{"id":"12","other":""},"locationInfo":{"id":"1"},"city":"Kota Jakarta Selatan","postCode":"12345","province":"DKI Jakarta","address":"","addressId":"1464"}
    ${OPTIONS}   Convert String To Json    ${OPTIONS}
    ${sign}     Generate Sign    ${OPTIONS}
    Set Test Variable    ${sign}
    Log To Console    ${sign}

    ${token}    login.Login to Application using mobile
    Set Test Variable    ${token}
    Set Test Variable    ${inviteCode}  FBRCME7Z





I send a request to register by share link
    ${response}    partner.Send register_getShortLink Request And Get Response Data    ${token}    ${inviteCode}
    Should Contain    ${response.json()}[resultObj]    copyLink

    Set Test Variable    ${link}    ${response.json()}[resultObj][copyLink]














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
