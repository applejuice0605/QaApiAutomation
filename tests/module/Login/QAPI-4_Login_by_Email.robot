*** Settings ***
Library    RequestsLibrary
Library    Collections
Library    String
Library    XML

Resource    ../../../resources/api/Login/fuse_user_login.robot
Resource    ../../../resources/api/Login/api_bylogin.robot
Resource    ../../../resources/api/Login/api_login.robot

#Setup Test
Suite Teardown    Delete All Sessions

*** Variables ***
${loginWay}    3



*** Test Cases ***
Login Success by Email
    [Tags]    login
    Given I have a valid email and password
    When I send a POST request to the fuse_user_login API
    Then the response should contain the user's loginAccount
    Then I send a POST request to the byLogin API
    And the status code should be 200
    And the response should contain the user's openid and tenantId
    Then I send a POST request to the Login API
    And the status code should be 200
    And the response should contain the user's token


*** Keywords ***
I have a valid email and password
    # should get data from datajsonfile
    Set Test Variable    ${email}    Shirley@fuseinsurtech.com
    Set Test Variable    ${password}    268987

I send a POST request to the fuse_user_login API
    ${response}    fuse_user_login.Send Request And Get Response Data    ${password}    ${loginWay}    email=${email}
    Set Test Variable    ${jsonResult}    ${response.json()}
    Log    ${jsonResult}


the response should contain the user's loginAccount
    Log    ${jsonResult}
    Log    ${jsonResult}[resultObj][accountId]
    Dictionary Should Contain Key    ${jsonResult}[resultObj]   accountId
    Set Test Variable    ${loginAccount}    ${jsonResult}[resultObj][accountId]

I send a POST request to the byLogin API
    ${response}    api_bylogin.Send Request And Get Response Data    ${loginAccount}    ${password}

    Set Test Variable    ${jsonResult}    ${response.json()}
    Log    ${jsonResult}

The response should contain the user's openid and tenantId
    Log    ${jsonResult}
    Log    ${jsonResult}[data][0][openId]
    Log    ${jsonResult}[data][0][tenantId]
    #   改进，应该根据国家注入租户号码
    Should Be Equal As Strings    ${jsonResult}[data][0][tenantId]    1000662
    Should Not Be Equal As Strings    ${jsonResult}[data][0][openId]    null
    Set Test Variable    ${openId}  ${jsonResult}[data][0][openId]
    Set Test Variable    ${tenantId}  ${jsonResult}[data][0][tenantId]


I send a POST request to the Login API
    ${response}    api_login.Send Request And Get Response Data    ${loginAccount}    ${password}    ${openId}    ${tenantId}

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


