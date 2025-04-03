*** Settings ***
Library    Collections
Library    BuiltIn
Library    OperatingSystem
Library     ../../../resources/api/Profile/EditProfile.py


Resource    ../../../resources/biz/Login/login.robot
Resource    ../../../resources/util/utilCommon.robot
Resource    ../../../resources/util/assertUtil.robot
Resource    ../../../resources/resource.robot


#Setup Test
Test Setup    Setup Env Variable
Test Teardown    Delete All Sessions


*** Test Cases ***
Edit Profile Success
    Given Setup Data Testing
    When I have logined
    Then Update Nickname And Address Fields In Edit Profile

*** Keywords ***
Setup Data Testing
    Log    ${env_vars}[DATA_BASEURL]


I have logined
    # 调用登录接口
    ${token}=   login.Login to Application using mobile     ${env_vars}[FUSE_ACCOUNT]    ${env_vars}[FUSE_PASSWORD]
    Set Test Variable    ${token}


Update Nickname And Address Fields In Edit Profile
    editProfie  ${loginAccount}  ${token}

