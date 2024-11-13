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
    Given Login FusePro By Phone Number
    Then Update Nickname And Address Fields In Edit Profile

*** Keywords ***
Login FusePro By Phone Number
    ${usertoken}=  fms_login_app  ${loginAccount}  ${password}
    Set Test Variable    ${usertoken}  ${usertoken}

Update Nickname And Address Fields In Edit Profile
    editProfie  ${loginAccount}  ${usertoken}

