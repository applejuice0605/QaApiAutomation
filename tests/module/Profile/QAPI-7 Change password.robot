*** Settings ***
Library    Collections
Library    BuiltIn
Library    OperatingSystem
Library    RequestsLibrary
Library     ../../../resources/api/Profile/ChangePassword.py

Resource    ../../../resources/biz/Login/login.robot
Resource    ../../../resources/resource.robot


#Setup Test
Test Setup    Setup Env Variable
Test Teardown    Delete All Sessions

*** Test Cases ***
Edit Profile Success
   [Tags]  uat
    Given Setup Data Testing
    When I have logined
    Then Change Password

*** Keywords ***
Setup Data Testing
    Log    ${env_vars}[DATA_BASEURL]

I have logined
    # 调用登录接口
    ${token}=   login.Login to Application using mobile     ${env_vars}[FUSE_ACCOUNT]    ${env_vars}[FUSE_PASSWORD]
    Set Test Variable    ${token}

Change Password
    ${new_passWord}=   Set Variable    000000
    # 628188666666 目前的密码为 000000
    ${oldPassword}=  Set Variable   666666
    updatePassword  ${env_vars}[FUSE_ACCOUNT]  ${token}   ${new_passWord}  ${oldPassword}


