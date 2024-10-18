*** Settings ***
Library    RequestsLibrary
Library    Collections
Library    String
Library    XML

#Setup Test
Suite Setup    Create API Session
Suite Teardown    Delete All Sessions

*** Variables ***
${BASE_URL}    https://sso-uat.fuse.co.id
${header}   {"Content-Type": "application/json","clientType": "ANDROID","appCode": "IDP_FUSE_PRO"}
${loginAccount}     628123268987
${password}     268987
${body}


*** Test Cases ***
LoginSuccess
    [Tags]    login
    Given I have a valid login account and password
    When I send a POST request to the byLogin API
    Then the status code should be 200
    And the response should contain the user's openid and tenantId
    Then I send a POST request to the Login API
    And the status code should be 200
    And the response should contain the user's token


*** Keywords ***
Create API Session
    Create Session    login    ${BASE_URL}    ${header}

I have a valid login account and password
    Set Test Variable    ${loginAccount}    628123268987
    Set Test Variable    ${password}    268987

I send a POST request to the byLogin API
    Set Test Variable    ${body}    {"loginAccount":"${loginAccount}","password":"${password}"}
    Log    ${body}
    ${response}    POST On Session    login    /api/sso/h5/user/tenants/byLogin  ${body}
    Set Test Variable    ${jsonResult}    ${response.json()}
    Log    ${jsonResult}

#    Run Keyword If    ${jsonResult[code]} == 200
#        I send a POST request to the Login API    ${jsonResult}[data][0][openId]    ${jsonResult}[data][0][tenantId]

the status code should be 200
    Log    ${jsonResult}
    Log    ${jsonResult}[code]
    Should Be Equal As Numbers    ${jsonResult}[code]    200


the response should contain the user's openid and tenantId
    Log    ${jsonResult}
    Log    ${jsonResult}[data][0][openId]
    Log    ${jsonResult}[data][0][tenantId]
#    ${testType}  Get From Dictionary   ${jsonResult}[data][0][openId]   code#    Log    ${testType}
    Should Be Equal As Strings    ${jsonResult}[data][0][tenantId]    1000662
    Should Not Be Equal As Strings    ${jsonResult}[data][0][openId]    null
    Set Test Variable    ${openId}  ${jsonResult}[data][0][openId]
    Set Test Variable    ${tenantId}  ${jsonResult}[data][0][tenantId]

I send a POST request to the Login API
    Set Test Variable    ${body}    {"password": "${password}","loginAccount": "${loginAccount}","tenantId": "${tenantId}","openId": "${openId}","deviceInfo": {"customPhone": "${loginAccount}","loginWay": "0","loginPassWord": "${password}","countryCode": "02130000000000","vision": "5.16.0.5-sit","appVersion": "5.16.0.5-sit","loginErrorTimes": "0","osVision": "9","systemVersion": "9","deviceId": "PQ3B.190801.07101020","udid": "PQ3B.190801.07101020","phoneModel": "TAS-AN00","phoneType": "HUAWEI","deviceType": "Android","latitude": "39.915000915","longitude": "116.403999328","language": "en_US"}}
    ${response}    POST On Session    login    /api/sso/app/user/login  ${body}
    Set Test Variable    ${jsonResult}    ${response.json()}

the response should contain the user's token
    Log    ${jsonResult}[data][token]
#    ${testType}  Get From Dictionary   ${jsonResult}[data][token]   code
    Should Not Be Equal As Strings    ${jsonResult}[data][token]    null
    Set Global Variable    ${token}     ${jsonResult}[data][token]
