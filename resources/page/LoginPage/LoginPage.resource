*** Settings ***
Library  AppiumLibrary
Library  BuiltIn
#Variables    loginP.py
Library    Collections
Library    CSVLibrary
Library    DebugLibrary
Variables    LoginPage.py




*** Variables ***
${ANDROID_AUTOMATION_NAME}    UIAutomator2
${ANDROID_APP}                ${CURDIR}/../../../app/app-uat-debug.apk
${ANDROID_PLATFORM_NAME}      Android
${ANDROID_PLATFORM_VERSION}   %{ANDROID_PLTFORM_VERSION=13}
${ANDROID_APP_PACKAGE}        com.tuopuyi.fusepro
${BROWSER_NAME}               Chrome
${START_ACTIVITY}             com.example.idflutter.MainActivity

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
When Open Android FUSE PRO
  [Arguments]    ${appActivity}=${EMPTY}
  open application  http://127.0.0.1:4723  automationName=${ANDROID_AUTOMATION_NAME}
  ...  app=${ANDROID_APP}  platformName=${ANDROID_PLATFORM_NAME}    appWaitForLaunch=false    devicesName=emulator-5554    adbExecTimeout=600000
  ...  appPackage=${ANDROID_APP_PACKAGE}    autoGrantPermissions=true    newCommandTimeout=6000

When Login To Android FUSE PRO
   # [Arguments]    ${username}    ${password}
   
    ${data_file}=  Get Variable Value    ${DATA_FILE}
    ${data}=    Read User Data From CSV    ${data_file}
    
    Wait For Element And Click    ${LEWATI_BUTTON}
    Sleep    1s
    Wait For Element And Click    ${USERNAME_FIELD}
    Wait For Element And Input    ${USERNAME_FIELD}    ${data}[0]
    Sleep    2s
    Wait For Element And Click    ${PASSWORD_FIELD}
    Wait For Element And Input    ${PASSWORD_FIELD}    ${data}[1]
    Sleep    1s
    Wait For Element And Click    ${LOGIN_BUTTON}
    Wait Until Page Contains Element    ${PopUpNewOpen}    ${TIMEOUT}
    Sleep    5S

Wait For Element And Click
    [Arguments]    ${locator}
    Wait Until Page Contains Element    ${locator}    ${TIMEOUT}
    Element Should Be Enabled    ${locator}
    Click Element    ${locator}

Wait For Element And Input
    [Arguments]    ${locator}   ${text}
    Wait Until Page Contains Element    ${locator}    ${TIMEOUT}
    Input Text    ${locator}  ${text}

Read User Data From CSV
    [Arguments]    ${file_path}
    ${data}=    Read Csv File To List    ${file_path}
    # Skip the header row and get the second row
    ${second_row}=    Get From List    ${data}    2
    Return From Keyword    ${second_row}

Then Login Success
    # [Arguments]    ${login_button_locator}
    ${is_visible}=    Element Should Be Visible    ${LOGIN_BUTTON}
    ${Button_text} =   Get Text  ${LOGIN_BUTTON}
    debug
    Should Be True    ${is_visible}    message=${Button_text}



