*** Settings ***
Library    requests
Library    BuiltIn
Library    DebugLibrary
*** Test Cases ***
Test Get
    ${response}=  Get    https://baidu.com
    ${respPost}=  Post   https://baidu.com/search    data={}
    debug

Test Post
    ${respPost}    Post    https://baidu.com/search    data={}


Test Login
    # 1.获取账号密码
    # 2.调用登录接口，获取 租户和openId
    # 3.