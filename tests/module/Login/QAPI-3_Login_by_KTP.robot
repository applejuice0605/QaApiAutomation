*** Settings ***
Library    RequestsLibrary
Library    Collections
Library    String
Library    XML

Resource    ../../../resources/api/Login/fuse_user_login.robot
Resource    ../../../resources/api/Login/api_bylogin.robot
Resource    ../../../resources/api/Login/api_login.robot
Resource    ../../../resources/resource.robot

#Setup Test
Test Setup    Setup Env Variable
Test Teardown    Delete All Sessions

*** Variables ***
${loginMethod}    nationId



*** Test Cases ***
Login Success by KTP
    [Tags]    uatAndprod    prod
    Given I have a valid KTP and password
#    When I send a POST request to the fuse_user_login API
#    Then the response should contain the user's loginAccount
    Then I send a POST request to the byLogin API
    And the status code should be 200
    And the response should contain the user's openid and tenantId
    Then I send a POST request to the Login API
    And the status code should be 200
    And the response should contain the user's token


*** Keywords ***
I have a valid KTP and password
    Set Test Variable    ${loginAccount}    ${env_vars}[KTP_NO]
    Set Test Variable    ${password}    ${env_vars}[FUSE_PASSWORD]


I send a POST request to the byLogin API
    ${response}    api_bylogin.Send Request And Get Response Data    ${loginAccount}    ${password}     ${loginMethod}

    Set Test Variable    ${jsonResult}    ${response.json()}
    Log    ${jsonResult}

The response should contain the user's openid and tenantId
    Log    ${jsonResult}
    Log    ${jsonResult}[data][0][openId]
    Log    ${jsonResult}[data][0][tenantId]
    Should Be Equal As Numbers    ${jsonResult}[data][0][tenantId]    ${env_vars}[TENANT_ID]
    Should Not Be Equal As Strings    ${jsonResult}[data][0][openId]    null
    Set Test Variable    ${openId}  ${jsonResult}[data][0][openId]
    Set Test Variable    ${tenantId}  ${jsonResult}[data][0][tenantId]


I send a POST request to the Login API
    ${response}    api_login.Send Request And Get Response Data    ${loginAccount}    ${password}    ${openId}    ${tenantId}   ${loginMethod}

    Set Test Variable    ${jsonResult}    ${response.json()}
    Log    ${jsonResult}


The response should contain the user's token
    Log    ${jsonResult}[data][token]
    Should Not Be Equal As Strings    ${jsonResult}[data][token]    null
    Set Global Variable    ${token}     ${jsonResult}[data][token]


The status code should be 200
    Log    ${jsonResult}
    Log    ${jsonResult}[code]
    Should Be Equal As Numbers    ${jsonResult}[code]    200


