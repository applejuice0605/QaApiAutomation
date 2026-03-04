*** Settings ***
Documentation     这是一个公共方法封装文件，将所需的关键字全部封装到此文件下
Library    RequestsLibrary
Library     OperatingSystem
Library     Collections
Library     BuiltIn
Library     BuiltIn
Library     DateTime
Resource    ../api/Login/api_bylogin.robot
Resource    ../api/Login/api_login.robot

*** Variables ***
${FmsLogin_Url}=  https://app-uat.fuseinsurtech.com/insurance-finance-vs-api/api/fuse/user/login

*** Keywords ***

Send Post Request And Get Response Data
    [Documentation]    获取response 返回 Data数据
    [Arguments]    ${session}  ${url}  ${body}  &{headers}
    Create Session    ${session}  ${url}  headers=&{headers}  verify=False
    ${response}=  POST On Session    ${session}  ${url}   ${body}
    RETURN  ${response}

Create RandomString_5
    [Documentation]    生成一个5位数，包含数字+字符
    ${random_string}=    Evaluate    ''.join(random.choice(string.ascii_letters + string.digits) for _ in range(5))    random, string
    ${random_digit}=  Evaluate  random.randint(0,9)  random
    ${combination}=  Catenate  SEPARATOR=  ${random_digit}  ${random_string}
    Log  ${combination}
    RETURN  ${combination}

Get DateTamp
    [Documentation]    获取application from 表单中的 effective、expireTime  时间戳
    # 获取当前时间
    ${effective}   Get Current Date  result_format=%Y-%m-%d %H:%M:%S time_zone=GMT+7
    Log    ${effective}
    # 转换为原始时间戳
    ${effective_timestamp}    Convert Date    ${effective}    epoch
    Log    ${effective_timestamp}
    # 转换为毫秒级时间戳
    ${effective_timestamp_ms}    Evaluate    int(round(${effective_timestamp} * 1000))
    Log    ${effective_timestamp_ms}
    ${expireTime}    Add Time To Date    ${effective}    365 days
    Log    ${expireTime}
    # 转换为原始时间戳
    ${expireTime_timestamp}    Convert Date    ${expireTime}    epoch
    Log    ${expireTime_timestamp}
    # 转换为毫秒级时间戳
    ${expireTime_timestamp_ms}    Evaluate    int(round(${expireTime_timestamp} * 1000))
    Log    ${expireTime_timestamp_ms}
    ${tamp_data}=  Create Dictionary    effective=${effective_timestamp_ms}  expireTime=${expireTime_timestamp_ms}
    RETURN  ${tamp_data}

Create CurrentTime
    [Documentation]    生成当前时间
    ${CURRENT_TIME}=    Evaluate    datetime.datetime.now()    datetime
    Log    Current Time is: ${CURRENT_TIME}
    RETURN  ${CURRENT_TIME}

Get Token And TenantId And OpenId
    [Arguments]    ${loginAccount}  ${password}
    ${response}=  api_bylogin.Send Request And Get Response Data  ${loginAccount}  ${password}
    ${res_json}=  Set Variable    ${response.json()}
    ${get_dict}=  Get From Dictionary    ${res_json}  data
    ${get_data}=  Get From List    ${get_dict}  0
    ${tenantId}=  Get From Dictionary    ${get_data}  tenantId
    ${openId}=  Get From Dictionary    ${get_data}  openId
    ${res}=  api_login.Send Request And Get Response Data  ${loginAccount}    ${password}   ${openId}   ${tenantId}
    ${res_json}=  Set Variable    ${res.json()}
    ${get_data}=   Get From Dictionary    ${res_json}  data
    ${token}=   Get From Dictionary   ${get_data}  token
    ${data}=  Create Dictionary  tenantId=${tenantId}  openId=${openId}  token=${token}
    Log  ${data}
    RETURN  ${data}


Get Fms UserToken
    [Arguments]    ${loginAccount}  ${password}
    ${body}=  Set Variable    {"customPhone":"${loginAccount}","loginWay":"0","loginPassWord":"${password}","countryCode":"02130000000000","vision":"5.28.0.0-uat","appVersion":"5.28.0.0-uat","loginErrorTimes":"0","deviceId":"55d7da1cff5d1e5927d45d1bf0b622f4fbec117a5edb0d3944d437ab37211772","osVision":"12","systemVersion":"12","udid":"HUAWEIALN-AL00","phoneModel":"ALN-AL00","phoneType":"HUAWEI","deviceType":"Android"}
    ${headers}=  Create Dictionary    language=en_US   version=5.28.0.0-uat  clientType=ANDROID  timeZone=7  appCode=IDP_FUSE_PRO
    ${response}=  Send Post Request And Get Response Data  getFmsSession    ${FmsLogin_Url}  ${body}   &{headers}
    ${get_json}=  Get From Dictionary    ${response.json()}  resultObj
    ${userTokken}=  Get From Dictionary    ${get_json}  userTokken
    RETURN  ${userTokken}











