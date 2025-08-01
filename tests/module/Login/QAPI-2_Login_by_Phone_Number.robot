*** Settings ***
Library    RequestsLibrary
Library    Collections
Library    String
Library    XML

Resource    ../../../resources/api/Login/api_bylogin.robot
Resource    ../../../resources/api/Login/api_login.robot

Resource    ../../../resources/resource.robot

#Setup Test
#优化：Suite Setup    Suite启动应改为获取前置操作里面的数据
Test Setup    Setup Env Variable
Test Teardown    Delete All Sessions



*** Variables ***
${loginMethod}    mobile

*** Test Cases ***
Login Success by Phone Number
    [Tags]    uatAndprod    prod
    Given I have a valid login account and password
    When I send a POST request to the byLogin API
    Then The response should contain the user's openid and tenantId
    Then I send a POST request to the Login API
    And The response should contain the user's token


*** Keywords ***
I have a valid login account and password
    Set Test Variable    ${loginAccount}    ${env_vars}[FUSE_ACCOUNT]
    Set Test Variable    ${password}    ${env_vars}[FUSE_PASSWORD]

I send a POST request to the byLogin API
    ${response}    api_bylogin.Send Request And Get Response Data    ${loginAccount}    ${password}     ${loginMethod}

    Set Test Variable    ${jsonResult}    ${response.json()}
    Log    ${jsonResult}

The response should contain the user's openId and tenantId
    Should Be Equal As Numbers    ${jsonResult}[data][0][tenantId]    ${env_vars}[TENANT_ID]
    Should Not Be Equal As Strings    ${jsonResult}[data][0][openId]    null
    Set Test Variable    ${openId}  ${jsonResult}[data][0][openId]
    Set Test Variable    ${tenantId}  ${jsonResult}[data][0][tenantId]


I send a POST request to the Login API
    ${response}    api_login.Send Request And Get Response Data    ${loginAccount}    ${password}    ${openId}    ${tenantId}   ${loginMethod}
    Set Test Variable    ${jsonResult}    ${response.json()}
    Log    ${jsonResult}


The response should contain the user's token
    Should Not Be Equal As Strings    ${jsonResult}[data][token]    null
    Set Global Variable    ${token}     ${jsonResult}[data][token]
