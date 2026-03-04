*** Settings ***
Library  AppiumLibrary
Library  BuiltIn
Variables    login.py
Library     DebugLibrary


*** Variables ***
${ANDROID_AUTOMATION_NAME}    UIAutomator2
${ANDROID_APP}                ${CURDIR}/../../App/app-uat-debug.apk
${ANDROID_PLATFORM_NAME}      Android
${ANDROID_PLATFORM_VERSION}   %{ANDROID_PLATFORM_VERSION=13}
${ANDROID_APP_PACKAGE}        com.tuopuyi.fusepro
${BROWSER_NAME}               Chrome

${IOS_AUTOMATION_NAME}        XCUITest
${IOS_APP}                    ${CURDIR}/../demoapp/TestApp.app.zip
${IOS_PLATFORM_NAME}          iOS
${IOS_PLATFORM_VERSION}       %{IOS_PLATFORM_VERSION=13.6}
${IOS_DEVICE_NAME}            iPhone 8

${TIMEOUT}                    60s

${USERNAME_FIELD}           ${EdtUsername}
${PASSWORD_FIELD}           ${EdtPassword}
${LOGIN_BUTTON}             ${BtnLogin}
${LEWATI_BUTTON}            ${BtnSkip}
${KTP_FIELD}                ${EdtKTP}
${LOGIN_BUTTON_KTP}         ${BtnLoginKTP}

# Login Email Yeng Yeng 11-07-2024 - Add variables - BEGIN
${EMAIL_FIELD}              ${EdtUsername}




*** Keywords ***
Open Android FUSE PRO App
  [Arguments]    ${appActivity}=${EMPTY}
  open application  http://127.0.0.1:4723  automationName=${ANDROID_AUTOMATION_NAME}
  ...  app=${ANDROID_APP}  platformName=${ANDROID_PLATFORM_NAME}    appWaitForLaunch=false    devicesName=emulator-5554    adbExecTimeout=600000
  ...  appPackage=${ANDROID_APP_PACKAGE}    autoGrantPermissions=true    newCommandTimeout=6000

Login To Application
    [Arguments]    ${username}    ${password}
    Wait For Element And Click    ${LEWATI_BUTTON}
    Sleep    1s
    Wait For Element And Click    ${USERNAME_FIELD}
    Wait For Element And Input    ${USERNAME_FIELD}    ${username}
    Sleep    2s
    Wait For Element And Click    ${PASSWORD_FIELD}
    Wait For Element And Input    ${PASSWORD_FIELD}    ${password}
    Sleep    1s
    Wait For Element And Click    ${LOGIN_BUTTON}
    Wait Until Page Contains Element    ${PopUpNewOpen}    ${TIMEOUT}

Wait For Element And Click
    [Arguments]    ${locator}
    Wait Until Page Contains Element    ${locator}    ${TIMEOUT}
    Element Should Be Enabled    ${locator}
    Click Element    ${locator}

Wait For Element And Input
    [Arguments]    ${locator}   ${text}
    Wait Until Page Contains Element    ${locator}    ${TIMEOUT}
    Input Text    ${locator}  ${text}



*** Test Cases ***
Open Application
    Open Android FUSE PRO App  com.example.idflutter.MainActivity
    Login To Application    85100000021    000021
#    Close Application