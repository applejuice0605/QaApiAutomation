*** Settings ***
Documentation
...    boss get policy list, when click in policy list v2.0 menu, this api will be called
...    BASE_URL: https://boss-uat.fuse.co.id
...    path: /api/oms/slip/v2/list
...    POST
...    headers: {'Content-Type': 'application/json','clientType': 'ANDROID','appCode': 'IDP_FUSE_PRO'}
...    payload: {"loginAccount": "628123268987", "password": "268987"}

Library    RequestsLibrary
Library    JSONLibrary
Resource    ../../util/httpCommon.robot

Variables   ../../varfile_defvar.py


*** Keywords ***
# 发送请求
Send Request And Get Response Data With Messages
    #payload的existsAssignee参数需要根据实际boss的指派规则来设置
    [Arguments]    ${messages}
    # 1. 准备请求数据：请求路径、请求头、请求数据
    ${base_url}=   Set Variable     https://pchat-uat.fuse.co.id
    ${path}=   Set Variable     /api/ai/chatbot/whatsapp/webhook
    ${headers}=    Create Dictionary    Content-Type=application/json
    ${payload}=    Set Variable     {"object":"whatsapp_business_account","entry":[{"id":"1851481102271082","changes":[{"value":{"messaging_product":"whatsapp","metadata":{"display_phone_number":"6285283239812","phone_number_id":"539655932572544"},"contacts":[{"profile":{"name":"nora 2号"},"wa_id":"8619830441461"}],"messages":[${messages}]},"field":"messages"}]}]}

    # 2. 发送请求
    ${response}=    httpCommon.Send Post Request And Get Response Data    ${base_url}    ${path}    ${headers}    ${payload}

    RETURN    ${response}


Send Request And Get Response Data
    #payload的existsAssignee参数需要根据实际boss的指派规则来设置
    [Arguments]    ${fina_userInfo}    ${msgType}    ${msgContent}
    Log    ${fina_userInfo}
    Log    ${msgType}
    Log    ${msgContent}
    # 1. 准备请求数据：请求路径、请求头、请求数据
    ${base_url}=   Set Variable     https://pchat-uat.fuse.co.id
    ${path}=   Set Variable     /api/ai/chatbot/whatsapp/webhook
    ${headers}=    Create Dictionary    Content-Type=application/json
    
    # 根据不同{msgType}组装payload
    IF    '${msgType}' == 'text'
        ${payload}=    Update Text Msg Request Body    ${fina_user_info}    ${msgContent}
    ELSE IF    '${msgType}' == 'interactive#nfm_reply'
        ${payload}=    Update Interactive#nfm_reply Msg Request Body   ${fina_user_info}    ${msgContent}
    ELSE IF    '${msgType}' == 'button'
        ${payload}=    Update Button Msg Request Body   ${fina_user_info}    ${msgContent}
    ELSE IF    '${msgType}' == 'button_reply'
        ${payload}=    Update Button_Reply Msg Request Body   ${fina_user_info}    ${msgContent}
    ELSE IF    '${msgType}' == 'image'
        ${payload}=    Update Image Msg Request Body    ${fina_user_info}    ${msgContent}
    ELSE IF    '${msgType}' == 'list_reply'
        ${payload}=    Update List_Reply Msg Request Body   ${fina_user_info}    ${msgContent}
    ELSE
        Log    "msgType: ${msgType} not support"
        ${payload}=    Set Variable    {}
    END
    
    Log    ${payload}
    # 2. 发送请求
    ${response}=    httpCommon.Send Post Request And Get Response Data    ${base_url}    ${path}    ${headers}    ${payload}

    RETURN    ${response}


Update Text Msg Request Body
    [Arguments]    ${fina_user_info}    ${msgContent}
    Log    ${fina_user_info}
    Log    ${msgContent}
    ${textMsgReuestJsonBody} =    Set Variable    {"object":"whatsapp_business_account","entry":[{"id":"1851481102271082","changes":[{"value":{"messaging_product":"whatsapp","metadata":{"display_phone_number":"6285283239812","phone_number_id":"539655932572544"},"contacts":[{"profile":{"name":"nora 2号"},"wa_id":"8619830441461"}],"messages":[{"from":"8619830441461","id":"wamid.HBgNODYxOTgzMDQ0MTQ2MRUCABIYIEFDNzI1NTgzQ0YzOTAzMDkxODQwQkMyQ0M1MzBDMEI3AA==","timestamp":"1760413438","text":{"body":"HI"},"type":"text"}]},"field":"messages"}]}]}
    
    # 转换成字典
    ${textMsgReuestJsonBody}=     Convert String To Json    ${textMsgReuestJsonBody}

    ${type}    Evaluate     type(${textMsgReuestJsonBody})
    Log    ${type}
    Log    ${textMsgReuestJsonBody}
    
    Log    ${fina_user_info["channel_user_id"]}

    # 更新contacts中渠道用户的渠道电话
    ${textMsgReuestJsonBody}=    Update Value To Json    ${textMsgReuestJsonBody}    $.entry[0].changes[0].value.contacts[0].wa_id    ${fina_user_info["channel_user_id"]}
    # 更新messages中消息发送方的渠道电话
    ${textMsgReuestJsonBody}=    Update Value To Json    ${textMsgReuestJsonBody}    $.entry[0].changes[0].value.messages[0].from    ${fina_user_info["channel_user_id"]}
    # 更新messages中消息发送方的发送的id
    ${textMsgReuestJsonBody}=    Update Value To Json    ${textMsgReuestJsonBody}    $.entry[0].changes[0].value.messages[0].id    ${fina_user_info["id"]}

    # 更新messages中消息发送方的发送的时间timestamp，取现在时间
    # 生成现在时间的timestamp
    ${nowtimestamp}=    Get Time    epoch
    # timestamp转换成字符串
    ${nowtimestamp}=    Convert To String    ${nowtimestamp}
    Log    ${nowtimestamp}
    ${textMsgReuestJsonBody}=    Update Value To Json    ${textMsgReuestJsonBody}    $.entry[0].changes[0].value.messages[0].timestamp    ${nowtimestamp}
    # 更新文本消息的内容
    ${textMsgReuestJsonBody}=    Update Value To Json    ${textMsgReuestJsonBody}    $.entry[0].changes[0].value.messages[0].text.body    ${msgContent}
    
    ${textMsgReuestJsonBody}=    Convert Json To String    ${textMsgReuestJsonBody}


    RETURN    ${textMsgReuestJsonBody}

Update Interactive#nfm_reply Msg Request Body
    [Arguments]    ${fina_user_info}    ${msgContent}
    Log    ${fina_user_info}
    Log    ${msgContent}

    ${type}    Evaluate    type(${msgContent})
    Log    ${type}
    ${reuestJsonBody} =    Set Variable    {"object":"whatsapp_business_account","entry":[{"id":"1851481102271082","changes":[{"value":{"messaging_product":"whatsapp","metadata":{"display_phone_number":"6285283239812","phone_number_id":"539655932572544"},"contacts":[{"profile":{"name":"nora 2号"},"wa_id":"8619830441461"}],"messages":[{"context":{"from":"6285283239812","id":"wamid.HBgNODYxOTgzMDQ0MTQ2MRUCABEYEjZCODBFMTE5RkZGMzhBMUQ2QgA="},"from":"8619830441461","id":"wamid.HBgNODYxOTgzMDQ0MTQ2MRUCABIYIEFDMTcwMUU5RDUwM0E4RUVEOENGNjQ5Qzg2QTQyQkFGAA==","timestamp":"1760943793","type":"interactive","interactive":{"type":"nfm_reply","nfm_reply":{"response_json":"carInfo"}}}]},"field":"messages"}]}]}
    
    ${type}=    Evaluate    type(${reuestJsonBody}).__name__
    Log    ${type}

    # 1. 将原始 JSON 字符串转为字典
    ${reuestJsonBody}    Convert Json To String    json_object=${reuestJsonBody}
    ${body_dict}=    Evaluate    json.loads(${reuestJsonBody})    json
    # 2. 将 msgContent 转为 JSON 字符串，并做一层转义
    ${escaped_msg}=    Evaluate    json.dumps(${msgContent})    json

    # 3. 更新 response_json 字段
    Set To Dictionary    ${body_dict['entry'][0]['changes'][0]['value']['messages'][0]['interactive']['nfm_reply']}    response_json=${escaped_msg}
    Set To Dictionary    ${body_dict['entry'][0]['changes'][0]['value']['contacts'][0]}    wa_id=${fina_user_info["channel_user_id"]}
    Set To Dictionary    ${body_dict['entry'][0]['changes'][0]['value']['messages'][0]}    form=${fina_user_info["channel_user_id"]}    
    Set To Dictionary    ${body_dict['entry'][0]['changes'][0]['value']['contacts'][0]}    id=${fina_user_info["id"]}    
    ${nowtimestamp}=    Get Time    epoch
    ${nowtimestamp}=    Convert To String    ${nowtimestamp}
    Set To Dictionary    ${body_dict['entry'][0]['changes'][0]['value']['contacts'][0]}    timestamp=${nowtimestamp}

    # 4. 最终转回 JSON 字符串输出
    ${final_json}=    Evaluate    json.dumps(${body_dict})    json
    Log    ${final_json}



    RETURN    ${final_json}


Update Button Msg Request Body
    [Arguments]    ${fina_user_info}    ${msgContent}
    Log    ${fina_user_info}
    Log    ${msgContent}

    ${type}    Evaluate    type(${msgContent})
    Log    ${type}
    ${reuestJsonBody} =    Set Variable    {"object":"whatsapp_business_account","entry":[{"id":"1851481102271082","changes":[{"value":{"messaging_product":"whatsapp","metadata":{"display_phone_number":"6285283239812","phone_number_id":"539655932572544"},"contacts":[{"profile":{"name":"nora 2号"},"wa_id":"8619830441461"}],"messages":[{"context":{"from":"6285283239812","id":"wamid.HBgNODYxOTgzMDQ0MTQ2MRUCABEYEjVBQjNCNkI2N0FGREQyOEMyOAA="},"from":"8619830441461","id":"wamid.HBgNODYxOTgzMDQ0MTQ2MRUCABIYIEFDOUYwMjMyMDUyRkQ3QUQ5MUIyOEUyMkVGNkQ1Njc0AA==","timestamp":"1760958630","type":"button","button":{"payload":"Lihat Detail","text":"Lihat Detail"}}]},"field":"messages"}]}]}
    ${type}=    Evaluate    type(${reuestJsonBody}).__name__
    Log    ${type}

    # 1. 将原始 JSON 字符串转为字典
    ${reuestJsonBody}    Convert Json To String    json_object=${reuestJsonBody}
    ${body_dict}=    Evaluate    json.loads(${reuestJsonBody})    json
    # 2. 将 msgContent 转为 JSON 字符串，并做一层转义
    ${escaped_msg}=    Evaluate    json.dumps(${msgContent})    json

    # 3. 更新 response_json 字段
    Set To Dictionary    ${body_dict['entry'][0]['changes'][0]['value']['contacts'][0]}    wa_id=${fina_user_info["channel_user_id"]}
    Set To Dictionary    ${body_dict['entry'][0]['changes'][0]['value']['messages'][0]}    form=${fina_user_info["channel_user_id"]}    
    Set To Dictionary    ${body_dict['entry'][0]['changes'][0]['value']['messages'][0]}    id=${fina_user_info["id"]}    
    # Set To Dictionary    ${body_dict['entry'][0]['changes'][0]['value']['messages'][0]['button']}    payload=${msgContent}
    # Set To Dictionary    ${body_dict['entry'][0]['changes'][0]['value']['messages'][0]['button']}    text=${msgContent}
    Set To Dictionary    ${body_dict['entry'][0]['changes'][0]['value']['messages'][0]}    button=${msgContent}
    ${nowtimestamp}=    Get Time    epoch
    ${nowtimestamp}=    Convert To String    ${nowtimestamp}
    Set To Dictionary    ${body_dict['entry'][0]['changes'][0]['value']['contacts'][0]}    timestamp=${nowtimestamp}

    # 4. 最终转回 JSON 字符串输出
    ${final_json}=    Evaluate    json.dumps(${body_dict})    json
    Log    ${final_json}

    RETURN    ${final_json}



Update Button_Reply Msg Request Body
    [Arguments]    ${fina_user_info}    ${msgContent}
    Log    ${fina_user_info}
    Log    ${msgContent}

    ${type}    Evaluate    type(${msgContent})
    Log    ${type}
    ${reuestJsonBody} =    Set Variable    {"object":"whatsapp_business_account","entry":[{"id":"1851481102271082","changes":[{"value":{"messaging_product":"whatsapp","metadata":{"display_phone_number":"6285283239812","phone_number_id":"539655932572544"},"contacts":[{"profile":{"name":"nora 2号"},"wa_id":"8619830441461"}],"messages":[{"context":{"from":"6285283239812","id":"wamid.HBgNODYxOTgzMDQ0MTQ2MRUCABEYEjM2MThFOEZEREY4Q0NGOEFCMQA="},"from":"8619830441461","id":"wamid.HBgNODYxOTgzMDQ0MTQ2MRUCABIYFjNFQjBDMjBBNEZCMkJFODIxODEzRjIA","timestamp":"1760944097","type":"interactive","interactive":{"type":"button_reply","button_reply":{"id":"MP_1231717001","title":"Plan A"}}}]},"field":"messages"}]}]}
    ${type}=    Evaluate    type(${reuestJsonBody}).__name__
    Log    ${type}

    # 1. 将原始 JSON 字符串转为字典
    ${reuestJsonBody}    Convert Json To String    json_object=${reuestJsonBody}
    ${body_dict}=    Evaluate    json.loads(${reuestJsonBody})    json
    # 2. 将 msgContent 转为 JSON 字符串，并做一层转义
    ${escaped_msg}=    Evaluate    json.dumps(${msgContent})    json

    # 3. 更新 response_json 字段
    Set To Dictionary    ${body_dict['entry'][0]['changes'][0]['value']['contacts'][0]}    wa_id=${fina_user_info["channel_user_id"]}
    Set To Dictionary    ${body_dict['entry'][0]['changes'][0]['value']['messages'][0]}    form=${fina_user_info["channel_user_id"]}    
    Set To Dictionary    ${body_dict['entry'][0]['changes'][0]['value']['messages'][0]}    id=${fina_user_info["id"]}    
    # Set To Dictionary    ${body_dict['entry'][0]['changes'][0]['value']['messages'][0]['interactive']['button_reply']}    id=${msgContent}['id']
    # Set To Dictionary    ${body_dict['entry'][0]['changes'][0]['value']['messages'][0]['interactive']['button_reply']}    text=${msgContent}['title']
    Set To Dictionary    ${body_dict['entry'][0]['changes'][0]['value']['messages'][0]['interactive']}    button_reply=${msgContent}
    ${nowtimestamp}=    Get Time    epoch
    ${nowtimestamp}=    Convert To String    ${nowtimestamp}
    Set To Dictionary    ${body_dict['entry'][0]['changes'][0]['value']['contacts'][0]}    timestamp=${nowtimestamp}

    # 4. 最终转回 JSON 字符串输出
    ${final_json}=    Evaluate    json.dumps(${body_dict})    json
    Log    ${final_json}

    RETURN    ${final_json}


Update Image Msg Request Body
    [Arguments]    ${fina_user_info}    ${msgContent}
    Log    "Update Image Msg Request Body"
    Log    ${fina_user_info}
    Log    ${msgContent}

    ${type}    Evaluate    type(${msgContent})
    Log    ${type}
    ${reuestJsonBody} =    Set Variable    {"object":"whatsapp_business_account","entry":[{"id":"1851481102271082","changes":[{"value":{"messaging_product":"whatsapp","metadata":{"display_phone_number":"6285283239812","phone_number_id":"539655932572544"},"contacts":[{"profile":{"name":"nora 2号"},"wa_id":"8619830441461"}],"messages":[{"from":"8619830441461","id":"wamid.HBgNODYxOTgzMDQ0MTQ2MRUCABIYIEFDRjNGQUJEMEMzNkMzNDI3NDU5NzBDMTExRjRCQzQyAA==","timestamp":"1760944538","type":"image","image":{"mime_type":"image/jpeg","sha256":"xUwnlAo9RXb24KRrInXJQeHZg2gdGxNxqiokU4I8PRo=","id":"1492221052052195","url":"https://lookaside.fbsbx.com/whatsapp_business/attachments/?mid=1492221052052195&source=webhook&ext=1760944839&hash=ARliluK00EgsADNYUqi3FExcuu_isaxg-SlNeuNnhocigg"}}]},"field":"messages"}]}]}
    ${type}=    Evaluate    type(${reuestJsonBody}).__name__
    Log    ${type}

    # 1. 将原始 JSON 字符串转为字典
    ${reuestJsonBody}    Convert Json To String    json_object=${reuestJsonBody}
    ${body_dict}=    Evaluate    json.loads(${reuestJsonBody})    json
    # 2. 将 msgContent 转为 JSON 字符串，并做一层转义
    ${escaped_msg}=    Evaluate    json.dumps(${msgContent})    json

    # 3. 更新 response_json 字段
    Set To Dictionary    ${body_dict['entry'][0]['changes'][0]['value']['contacts'][0]}    wa_id=${fina_user_info["channel_user_id"]}
    Set To Dictionary    ${body_dict['entry'][0]['changes'][0]['value']['messages'][0]}    form=${fina_user_info["channel_user_id"]}    
    Set To Dictionary    ${body_dict['entry'][0]['changes'][0]['value']['messages'][0]}    id=${fina_user_info["id"]}    
    Set To Dictionary    ${body_dict['entry'][0]['changes'][0]['value']['messages'][0]['image']}    id=${msgContent}
    ${url}    Set Variable    ${body_dict['entry'][0]['changes'][0]['value']['messages'][0]['image']['url']}
    # 将${url}中的1492221052052195替换成${msgContent}
    ${url}=    Set Variable    ${url.replace("1492221052052195", '${msgContent}')}
    Set To Dictionary    ${body_dict['entry'][0]['changes'][0]['value']['messages'][0]['image']}    url=${url}
    
    ${nowtimestamp}=    Get Time    epoch
    ${nowtimestamp}=    Convert To String    ${nowtimestamp}
    Set To Dictionary    ${body_dict['entry'][0]['changes'][0]['value']['contacts'][0]}    timestamp=${nowtimestamp}

    # 4. 最终转回 JSON 字符串输出
    ${final_json}=    Evaluate    json.dumps(${body_dict})    json
    Log    ${final_json}

    RETURN    ${final_json}

Update List_Reply Msg Request Body
    [Arguments]    ${fina_user_info}    ${msgContent}
    Log    ${fina_user_info}
    Log    ${msgContent}

    ${type}    Evaluate    type(${msgContent})
    Log    ${type}
    ${reuestJsonBody} =    Set Variable    {"object":"whatsapp_business_account","entry":[{"id":"1851481102271082","changes":[{"value":{"messaging_product":"whatsapp","metadata":{"display_phone_number":"6285283239812","phone_number_id":"539655932572544"},"contacts":[{"profile":{"name":"nora 2号"},"wa_id":"8619830441461"}],"messages":[{"context":{"from":"6285283239812","id":"wamid.HBgNODYxOTgzMDQ0MTQ2MRUCABEYEjY3QTQzMkVBMDZDNkM5Q0ZCRQA="},"from":"8619830441461","id":"wamid.HBgNODYxOTgzMDQ0MTQ2MRUCABIYIEFDMzk5MDJDQzE5OTA5MUVDQTdGRkRBODEyNzUzOTk0AA==","timestamp":"1760944955","type":"interactive","interactive":{"type":"list_reply","list_reply":{"id":"INTENT_QUICK_ORDER_1980171728124555265#M_00002#MP_00003","title":"ETIQA CAR COMPREHENSIVE","description":"ETIQA CAR COMPREHENSIVE"}}}]},"field":"messages"}]}]}
    ${type}=    Evaluate    type(${reuestJsonBody}).__name__
    Log    ${type}

    # 1. 将原始 JSON 字符串转为字典
    ${reuestJsonBody}    Convert Json To String    json_object=${reuestJsonBody}
    ${body_dict}=    Evaluate    json.loads(${reuestJsonBody})    json
    # 2. 将 msgContent 转为 JSON 字符串，并做一层转义
    ${escaped_msg}=    Evaluate    json.dumps(${msgContent})    json

    # 3. 更新 response_json 字段
    Set To Dictionary    ${body_dict['entry'][0]['changes'][0]['value']['contacts'][0]}    wa_id=${fina_user_info["channel_user_id"]}
    Set To Dictionary    ${body_dict['entry'][0]['changes'][0]['value']['messages'][0]}    form=${fina_user_info["channel_user_id"]}    
    Set To Dictionary    ${body_dict['entry'][0]['changes'][0]['value']['messages'][0]}    id=${fina_user_info["id"]}    
    # Set To Dictionary    ${body_dict['entry'][0]['changes'][0]['value']['messages'][0]['interactive']['button_reply']}    id=${msgContent}['id']
    # Set To Dictionary    ${body_dict['entry'][0]['changes'][0]['value']['messages'][0]['interactive']['button_reply']}    text=${msgContent}['title']
    Set To Dictionary    ${body_dict['entry'][0]['changes'][0]['value']['messages'][0]['interactive']}    list_reply=${msgContent}
    ${nowtimestamp}=    Get Time    epoch
    ${nowtimestamp}=    Convert To String    ${nowtimestamp}
    Set To Dictionary    ${body_dict['entry'][0]['changes'][0]['value']['contacts'][0]}    timestamp=${nowtimestamp}

    # 4. 最终转回 JSON 字符串输出
    ${final_json}=    Evaluate    json.dumps(${body_dict})    json
    Log    ${final_json}

    RETURN    ${final_json}