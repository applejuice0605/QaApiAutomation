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
    Given Login FusePro By Phone Number
    Then Change Password

*** Keywords ***
Login FusePro By Phone Number
    ${usertoken}=  fms_login_app  ${loginAccount}  ${password}
    Set Test Variable    ${usertoken}  ${usertoken}

Change Password
    ${new_passWord}=   Set Variable    000000
    # 628188666666 目前的密码为 000000
    ${oldPassword}=  Set Variable   666666
    updatePassword  ${loginAccount}  ${usertoken}   ${new_passWord}  ${oldPassword}


