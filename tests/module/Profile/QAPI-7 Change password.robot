*** Settings ***
Library    Collections
Library    BuiltIn
Library    OperatingSystem
Library     ../../../resources/api/Profile/ChangePassword.py

*** Variables ***
${loginAccount}=  628188666666
${password}=  666666

*** Test Cases ***
Edit Profile Success
    Given Login Fms And Get UserToken
    Then Input Old Password And New Password

*** Keywords ***
Login Fms And Get UserToken
    ${usertoken}=  fms_login_app  ${loginAccount}  ${password}
    Set Test Variable    ${usertoken}  ${usertoken}

Input Old Password And New Password
    ${new_passWord}=   Set Variable    000000
    # 628188666666 目前的密码为 000000
    ${oldPassword}=  Set Variable   666666
    updatePassword  ${loginAccount}  ${usertoken}   ${new_passWord}  ${oldPassword}


