*** Settings ***
Library    requests

*** Variables ***
${BASE_URL}    http://httpbin.org
${data}  '{}'

*** Test Cases ***
Test GET Request
    [Documentation]  Perform a simple GET request and verify the response.
    ${response}=  Get    ${BASE_URL}/get
    Should Be Equal As Strings  ${response.status_code}  200

Test POST Request
    [Documentation]  Perform a simple POST request with data and verify the response.
    ${response}=  Post    ${BASE_URL}/post
    Should Be Equal As Strings  ${response.status_code}  200
