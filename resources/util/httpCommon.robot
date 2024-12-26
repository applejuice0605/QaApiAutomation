*** Settings ***
Library    RequestsLibrary
Resource    assertUtil.robot

*** Keywords ***
Send Post Request And Get Response Data
    [Documentation]    发送请求，获取response 返回 Data数据
    [Arguments]    ${url}   ${path}     ${headers}     ${body}
    Create Session    session  ${url}  headers=&{headers}  verify=false
    ${response}=  POST On Session    session  ${path}   ${body}

    RETURN    ${response}

Get String PayerType
    [Documentation]     将payerType枚举值转换成字符串
#            payerType = 2 -> Partner Pay
#            payerType = 1 -> Customer Pay
    [Arguments]     ${payerType}
    IF    ${payerType} == 2
        RETURN  partner
#    ELSE IF    $payerType == partner
#        RETURN  partner
    ELSE IF    ${payerType} == 1
        RETURN  customer
#    ELSE IF    $payerType == customer
#        RETURN  customer
    END

Get appHeader By PayerType
    [Documentation]     通过客户端获取header
#            payerType = 1 -> Partner Pay
#            payerType = 2 -> Customer Pay
    [Arguments]     ${payerType}    ${token}
    IF    ${payerType} == 2
        ${headers}=    Create Dictionary    Content-Type=application/json    clientType=ANDROID    appCode=IDP_FUSE_PRO    fusetoken=${token}
#    ELSE IF    $payerType == partner
#        ${headers}=    Create Dictionary    Content-Type=application/json    appCode=IDP_FUSEPRO    token=${token}
    ELSE IF    ${payerType} == 1
        ${headers}=    Create Dictionary    Content-Type=application/json    appCode=IDP_BOSS    x-5a-temp-token=${token}
#    ELSE IF    $payerType == customer
#        ${headers}=    Create Dictionary    Content-Type=application/json    appCode=IDP_BOSS    x-5a-temp-token=${token}
    END
    RETURN    ${headers}

    
#Send Post Request And Get Response Data
#    [Documentation]    发送请求，获取response 返回 Data数据
#    [Arguments]    ${url}   ${path}     ${headers}     ${body}
#    Create Session    session  ${url}  headers=&{headers}  verify=False
#    ${response}=  POST On Session    session  ${path}   ${body}
#    ${response_data}=  Get From Dictionary    ${response}    data
#    RETURN    ${response_data}
#    Get Request    alias    uri
#





