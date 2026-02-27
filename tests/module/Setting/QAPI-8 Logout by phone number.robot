*** Settings ***
Library    RequestsLibrary
Library    Collections
Library    String
Library    XML

Resource    ../../../resources/biz/Login/login.robot
Resource    ../../../resources/resource.robot

Resource    ../../../resources/api/Setting/UserLogout.robot


#Setup Test
#优化：Suite Setup    Suite启动应改为获取前置操作里面的数据
Test Setup    Setup Env Variable
Test Teardown    Delete All Sessions



*** Test Cases ***
Logout by phone number
    [Tags]    uat
#    Given Login FusePro Success 
    Given I have a whitelist account and have logined
    When Logout FusePro By Phone Number

     
*** Keywords ***
I have a whitelist account and have logined
    ${token}=   login.Login to Application using mobile     ${env_vars}[FUSE_ACCOUNT]    ${env_vars}[FUSE_PASSWORD]
    Set Test Variable    ${token}


Logout FusePro By Phone Number
    Send UserLogout Post Request  1000662  ${token}
