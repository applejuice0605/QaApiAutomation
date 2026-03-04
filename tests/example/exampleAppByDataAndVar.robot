*** Settings ***
# 加载变量
#Variables    login.py
# 加载资源
Resource    ../../Resources/page/LoginPage/LoginPage.resource



*** Variables ***
${ANDROID_AUTOMATION_NAME}    UIAutomator2
${ANDROID_APP}                ${CURDIR}/../../App/app-uat-debug.apk
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




*** Test Cases ***
    # 通过传入不同的文件，实现不同的用例效果执行
Open Application
     ${data_file}=    Get Variable Value    ${DATA_FILE}
     ${data}=    Read User Data From CSV    ${data_file}
      Open Android FUSE PRO App  ${START_ACTIVITY}
      Login To Application    ${data}[0]    ${data}[1]
    #加上就可以debug了。
    #debug
    Sleep    5S
      Check Login Success  ${LOGIN_BUTTON}


Close Application
    Sleep    1S