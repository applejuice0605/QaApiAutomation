*** Settings ***
Library   requests
Library   BuiltIn
Library    DebugLibrary
*** Test Cases ***
Test Get
    ${response}=  Get    https://baidu.com
    ${respPost}=  Post    https://baidu.com/search    data={}
    # debug
    log ${response}

Test Post
    ${respPost}    Post    https://baidu.com/search    data={}