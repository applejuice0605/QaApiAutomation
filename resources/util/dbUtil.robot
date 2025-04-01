*** Settings ***
Library    Collections


*** Keywords ***
Login in Archery
    [Arguments]    ${username}    ${password}
    ${response}=    Login    ${username}    ${password}
    Should Be Equal As Numbers    ${response.status_code}    200
    ${json}=    To Json    ${response.content}
    ${token}=    Get From Dictionary    ${json}    token

Excute Query
    [Arguments]    ${token}=IjVu4e125wfekmpiTvW543IIBcjuwVzr8AOW8ADge1A29j0PADtpG2haaEF43sGH
    # 1. 准备请求数据：请求路径、请求头、请求数据
    ${base_url}=   Set Variable     https://rd-dms.fuseinsurtech.com/query/
    ${path}=   Set Variable     /insurance-finance-vs-api/api/fuse/user/login
    ${headers}=    Create Dictionary    Content-Type=application/json    clientType=application/json;charset=UTF-8    appCode=IDP_BOSS  fusetoken=${bossToken}
    ${payload}=    Set Variable     {"instance_name":"ID_UAT_CORE_MYSQL8.0","db_name":"__recycle_bin__","schema_name":"","tb_name":"","sql_content":"","limit_num":100}


    # 2. 发送请求
    ${response}=    httpCommon.Send Post Request And Get Response Data    ${base_url}    ${path}    ${headers}    ${payload}

    RETURN    ${response}


    Should Be Equal As Numbers   ${code}    200