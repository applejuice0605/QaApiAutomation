*** Settings ***
Documentation
...    boss get policy list, when click in policy list v2.0 menu, this api will be called
...    BASE_URL: https://boss-uat.fuse.co.id
...    path: /api/oms/slip/v2/list
...    POST
...    headers: {'Content-Type': 'application/json','clientType': 'ANDROID','appCode': 'IDP_FUSE_PRO'}
...    payload: {"loginAccount": "628123268987", "password": "268987"}

Library    RequestsLibrary

Resource    ../../util/httpCommon.robot

Variables   ../../varfile_defvar.py


*** Keywords ***
# 发送请求
Send Request And Get Response Data
    #payload的existsAssignee参数需要根据实际boss的指派规则来设置
    [Arguments]    ${bossToken}     ${taskIds}
    # 1. 准备请求数据：请求路径、请求头、请求数据
    ${base_url}=   Set Variable     https://boss-uat.fuse.co.id
    ${path}=   Set Variable     /api/bpm/runtime/self/assign
    ${headers}=    Create Dictionary    Content-Type=application/json    clientType=application/json;charset=UTF-8    appCode=IDP_BOSS  fusetoken=${bossToken}
    ${payload}=    Set Variable     {"assignee": "${BossAccount}","businessCode": [null],"taskIds": ${taskIds}}
    # 2. 发送请求
    ${response}=    httpCommon.Send Post Request And Get Response Data    ${base_url}    ${path}    ${headers}    ${payload}

    RETURN    ${response}