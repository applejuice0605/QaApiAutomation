*** Settings ***
Library    Collections
Library    BuiltIn
Library    OperatingSystem
Library     ../../../resources/api/Profile/ChangePassword.py

*** Variables ***
${loginAccount}=  628188666666
${password}=  000000

*** Test Cases ***
Edit Profile Success
    Given Login Fms And Get UserToken
    Then Update Password Post Request

*** Keywords ***
Login Fms And Get UserToken
    ${usertoken}=  fms_login_app  ${loginAccount}  ${password}
    Set Test Variable    ${usertoken}  ${usertoken}

Update Password Post Request
    ${new_passWord}=   Set Variable    666666
    # 628188666666 目前的密码为 000000
    ${oldPassword}=  Set Variable   000000
    updatePassword  ${loginAccount}  ${usertoken}   ${new_passWord}  ${oldPassword}


