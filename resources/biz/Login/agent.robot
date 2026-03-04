*** Settings ***
Library    RequestsLibrary
Library    Collections
Library    String
Library    XML

Resource    ../../api/Login/fuse_user_login.robot
Resource    ../../api/Login/api_bylogin.robot
Resource    ../../api/Login/api_login.robot
Resource    ../../api/Login/boss/login.robot
Resource    ../../api/Login/boss/bylogin.robot
Resource    ../../api/Profile/updateProfile.robot
Resource    ../../biz/Login/login.robot

Variables   ../../varfile_defvar.py

*** Keywords ***
Get sign
    [Arguments]    ${account}    ${password}
    #1. get userToken
#    ${resonse}  fuse_user_login.Send Request And Get Response Data    password=${password}  loginWay=0      mobile= ${account}
#    Log    ${resonse.json()}
#    ${userToken}     Set Variable    ${resonse.json()}[resultObj][userTokken]
    ${userToken}    Set Variable    login.Login to Application using mobile
    Log    ${userToken}
    #2. get sign throught update profile
    ${resonse}  updateProfile.Send Request And Get Response Data    userToken=${userToken}  account=${account}