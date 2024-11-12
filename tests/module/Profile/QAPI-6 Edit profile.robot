*** Settings ***
Library    Collections
Library    BuiltIn
Library    OperatingSystem
Library     ../../../resources/api/Profile/EditProfile.py

*** Variables ***
${loginAccount}=  628123268989
${password}=  268989

*** Test Cases ***
Edit Profile Success
    Given Login Fms And Get UserToken
    Then Update Post Request

*** Keywords ***
Login Fms And Get UserToken
    ${usertoken}=  fms_login_app  ${loginAccount}  ${password}
    Set Test Variable    ${usertoken}  ${usertoken}

Update Post Request
    editProfie  ${loginAccount}  ${usertoken}

