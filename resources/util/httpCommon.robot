*** Settings ***
Library    RequestsLibrary
Resource    assertUtil.robot

*** Keywords ***
Send Post Request And Get Response Data
    [Documentation]    发送请求，获取response 返回 Data数据
    [Arguments]    ${url}   ${path}     ${headers}     ${body}
    Create Session    session  ${url}  headers=&{headers}  verify=True
    ${response}=  POST On Session    session  ${path}   ${body}

    RETURN    ${response}
    
#Send Post Request And Get Response Data
#    [Documentation]    发送请求，获取response 返回 Data数据
#    [Arguments]    ${url}   ${path}     ${headers}     ${body}
#    Create Session    session  ${url}  headers=&{headers}  verify=False
#    ${response}=  POST On Session    session  ${path}   ${body}
#    ${response_data}=  Get From Dictionary    ${response}    data
#    RETURN    ${response_data}
#    Get Request    alias    uri
#





