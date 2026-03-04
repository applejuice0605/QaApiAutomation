*** Settings ***
Documentation
...    Login by login account and password and Will get openId & tenantId
...    BASE_URL: https://sso-uat.fuse.co.id
...    path: /api/sso/h5/user/tenants/byLogin
...    POST
...    headers: {'Content-Type': 'application/json','clientType': 'ANDROID','appCode': 'IDP_FUSE_PRO'}
...    payload: {"loginAccount": "628123268987", "password": "268987"}

Library    RequestsLibrary

Resource    ../../util/httpCommon.robot

Variables   ../../varfile_defvar.py


*** Keywords ***

# 发送请求
Send Request And Get Response Data

    ${base_url}=   Set Variable     https://rd-dms.fuseinsurtech.com
    ${path}=   Set Variable     /authenticate/
    ${headers}=    Create Dictionary    Content-Type=application/x-www-form-urlencoded;charset=UTF-8    cookie=csrftoken=d1vaU13wGGPFwKyOGeIE1J5KkBml8TP6U5Fo7qgS4WtzQ7iNM7tToKAmferkDdwN  X-CSRFToken=d1vaU13wGGPFwKyOGeIE1J5KkBml8TP6U5Fo7qgS4WtzQ7iNM7tToKAmferkDdwN
    ${payload}=    Create Dictionary    username=caishubin  password=XV5s3h&NGquiG9dD

    # 2. 发送请求
    ${response}=    httpCommon.Send Post Request And Get Response Data    ${base_url}    ${path}    ${headers}    ${payload}

    RETURN    ${response}

Excute SQL
    ${base_url}=   Set Variable    https://rd-dms.fuseinsurtech.com
    ${path}=   Set Variable     /query/
    ${headers}=    Create Dictionary    Content-Type=application/x-www-form-urlencoded;charset=UTF-8    cookie=csrftoken=hZIUazTWWHXwNr7lUBWKwuE8U50G1BYC71By6id1rwjKqQFMD2Efvz4IbUdPsUtT  x-csrftoken=hZIUazTWWHXwNr7lUBWKwuE8U50G1BYC71By6id1rwjKqQFMD2Efvz4IbUdPsUtT
    ${payload}=    Create Dictionary    instance_name=ID_UAT_CORE_MYSQL8.0      db_name=message     schema_name=null   tb_name=sms_record  sql_content=select * from message.sms_record order by id desc   limit_num=100

    # 2. 发送请求
    ${response}=    httpCommon.Send Post Request And Get Response Data    ${base_url}    ${path}    ${headers}    ${payload}

    RETURN    ${response}







#
#POST /authenticate/ HTTP/1.1
#Accept: application/json, text/javascript, */*; q=0.01
#Accept-Encoding: gzip, deflate, br, zstd
#Accept-Language: zh-CN,zh;q=0.9,en;q=0.8
#Connection: keep-alive
#Content-Length: 46
#Content-Type: application/x-www-form-urlencoded; charset=UTF-8
#Cookie: csrftoken=5JNNMOsC6VE9qyl0DhgYhW2qNL3YyoVP9M22dLDX68T1xPjMCDQUhOEfLni9SdvU
#Host: rd-dms.fuseinsurtech.com
#Origin: https://rd-dms.fuseinsurtech.com
#Referer: https://rd-dms.fuseinsurtech.com/login/
#Sec-Fetch-Dest: empty
#Sec-Fetch-Mode: cors
#Sec-Fetch-Site: same-origin
#User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36
#X-CSRFToken: 5JNNMOsC6VE9qyl0DhgYhW2qNL3YyoVP9M22dLDX68T1xPjMCDQUhOEfLni9SdvU
#X-Requested-With: XMLHttpRequest
#sec-ch-ua: "Chromium";v="134", "Not:A-Brand";v="24", "Google Chrome";v="134"
#sec-ch-ua-mobile: ?0
#sec-ch-ua-platform: "Windows"
#
