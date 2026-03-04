*** Settings ***
Library    RequestsLibrary
Library    Collections
Library    String
Library    XML
Library    SeleniumLibrary
Library    DateTime
Library    JSONLibrary

Resource    ../../resources/api/WA/pchat_whatsapp_webhook.robot

Resource    ../../resources/util/assertUtil.robot
Resource    ../../resources/util/dbUtil.robot
Resource    ../../resources/util/utilCommon.robot
Resource    ../../resources/resource.robot



#Setup Test
#Test Setup    Setup Env Variable
#Test Teardown    Delete All Sessions

*** Variables ***
${BODY_FILE_PATH}    Car_PlaceOrderData.json
${isAdvancePremium}     1
${payerType}    2
${paymentScheme}    3
${paymentMethod}    VA
${whatsapp_id}  8619830441461
*** Test Cases ***
ask premium
    [Tags]
    Given Login in Fina
    When Send "Quote"
    Then Return Msg "comparisonStartMessage"
    Then Input car info
    Then Return Msg "quotationCollectedFormMessage"
    Then Sumbit QuickQuote Form
    Then Return Msg "newCommissionCompareMessage"
    Then Click button "Lihat Detail"
    Then Return Msg "price_comparision_pdf" and "price_comparision_id_0508"



*** Keywords ***
Login in Fina
    Set Test Variable    ${id}  wamid.HBgNODYxOTgzMDQ0MTQ2MRUCABIYIDU4QzU4NDNFMTJEMDEyNzI1MDFEMjY4RTFDRjFBODI4AA==
    Set Test Variable    ${request_body}    {"object":"whatsapp_business_account","entry":[{"id":"1851481102271082","changes":[{"value":{"messaging_product":"whatsapp","metadata":{"display_phone_number":"6285283239812","phone_number_id":"539655932572544"},"contacts":[{"profile":{"name":"nora 2号"},"wa_id":"8619830441461"}],"messages":[{"from":"8619830441461","id":"wamid.HBgNODYxOTgzMDQ0MTQ2MRUCABIYIDU4QzU4NDNFMTJEMDEyNzI1MDFEMjY4RTFDRjFBODI4AA==","timestamp":"1751010636","type":"image","image":{"mime_type":"image/jpeg","sha256":"kQF9PNOiC0ICgogC8MWy3pWoQ2hBROMijol1hmcg8b0=","id":"1219612649946680"}}]},"field":"messages"}]}]}
    Set Test Variable    ${text_content}     Quote

    Set Test Variable    ${text_msg}   {"from":"8619830441461","id":"wamid.HBgNODYxOTgzMDQ0MTQ2MRUCABIYIDdFM0M5QUM4NzAxQ0ZCM0I1QkZFRkYyODNGOEEwNkU5AA==","timestamp":"1751018237","text":{"body":"${text_content}"},"type":"text"}
    Set Test Variable    ${interactive_msg}    {"context":{"from":"6285283239812","id":"wamid.HBgNODYxOTgzMDQ0MTQ2MRUCABEYEjZDMEM2RDA1RTI2NUJGRDQ0NQA="},"from":"8619830441461","id":"wamid.HBgNODYxOTgzMDQ0MTQ2MRUCABIYIDQ5RjNDQkU5NDdCMUEyMjI3RDg1M0Y3ODE4RTNFNTkwAA==","timestamp":"1751265435","type":"interactive","interactive":{"type":"nfm_reply","nfm_reply":{"response_json":"{\\\"brandCode\\\":\\\"TOYOTA\\\",\\\"vehicleManufactureYear\\\":\\\"2022\\\",\\\"brandModelCode\\\":\\\"ALL NEW KIJANG INNOVA\\\",\\\"brandSeriesCode\\\":\\\"2.0 G A\\/T BENSIN\\\",\\\"vehicleType\\\":\\\"MINIBUS\\\",\\\"vehicleTypeCode\\\":\\\"MINIBUS\\\",\\\"carPriceShow\\\":\\\"376,200,000\\\",\\\"coveragePeriod\\\":\\\"1\\\",\\\"plateCode\\\":\\\"B\\\",\\\"vehicleUsage\\\":\\\"2\\\",\\\"flow_token\\\":\\\"QUICK_QUOTE:8619830441461:25550e154d404cae9da8ab1abbbf7e82\\\"}","body":"Sent","name":"flow"}}}

Send "Quote"
    ${request_body}=    Set Variable    ${text_msg}
    ${resonse}=     pchat_whatsapp_webhook.Send Request And Get Response Data    ${request_body}
    Log    ${resonse}
    Log    ${resonse.text}
    Should Be Equal    ${resonse.text}    EVENT_RECEIVED
    Sleep    10s

Return Msg "comparisonStartMessage"
    ${response}=    dbUtil.Query    select * from message.whatsapp_chat_record where whatsapp_id = '${whatsapp_id}' order by uid desc limit 1

    Log    ${response}
#    Register Keyword To Run On Failure    keyword
#    Run Keyword And Continue On Failure    Log    ${response.content}
    ${data}=    Set Variable    ${response.content}
    ${data}=    To Json    ${data}
    ${data}=    Set Variable    ${data}[data]
    Log    ${data}

    ${type}    Evaluate    type(${data})
    Log    ${type}
    ${result_dict}=     Convert to Json     ${data}

    ${acutal_reslut}=   Get From Dictionary    ${result_dict}    reply_id
    Should Be Equal As Strings    ${acutal_reslut}    comparisonStartMessage
#    Run Keyword And Continue On Failure    Log    ${data}[rows][0][10]


Input car info
    Set Test Variable    ${text_content}    Toyota Innova 2022 A
    Set Test Variable    ${text_msg}   {"from":"8619830441461","id":"wamid.HBgNODYxOTgzMDQ0MTQ2MRUCABIYIDdFM0M5QUM4NzAxQ0ZCM0I1QkZFRkYyODNGOEEwNkU5AA==","timestamp":"1751018237","text":{"body":"${text_content}"},"type":"text"}

    ${resonse}=     pchat_whatsapp_webhook.Send Request And Get Response Data    ${text_msg}
    Log    ${resonse}
    Log    ${resonse.text}
    Should Be Equal    ${resonse.text}    EVENT_RECEIVED
    Sleep    20s

Return Msg "quotationCollectedFormMessage"
    ${response}=    dbUtil.Query    select * from message.whatsapp_chat_record where whatsapp_id = '${whatsapp_id}' order by uid desc limit 1

    Log    ${response}
#    Register Keyword To Run On Failure    keyword
#    Run Keyword And Continue On Failure    Log    ${response.content}
    ${data}=    Set Variable    ${response.content}
    ${data}=    To Json    ${data}
    ${data}=    Set Variable    ${data}[data]
    Log    ${data}

    ${type}    Evaluate    type(${data})
    Log    ${type}
    ${result_dict}=     Convert to Json     ${data}

    ${acutal_reslut}=   Get From Dictionary    ${result_dict}    reply_id
    Should Be Equal As Strings    ${acutal_reslut}    quotationCollectedFormMessage
#    Run Keyword And Continue On Failure    Log    ${data}[rows][0][10]



Sumbit QuickQuote Form
    Log    ${interactive_msg}
    ${resonse}=     pchat_whatsapp_webhook.Send Request And Get Response Data    ${interactive_msg}
    Log    ${resonse}
    Log    ${resonse.text}
    Should Be Equal    ${resonse.text}    EVENT_RECEIVED
    Sleep    10s


Return Msg "newCommissionCompareMessage"
    ${response}=    dbUtil.Query    select * from message.whatsapp_chat_record where whatsapp_id = '${whatsapp_id}' order by uid desc limit 1

    Log    ${response}
#    Register Keyword To Run On Failure    keyword
#    Run Keyword And Continue On Failure    Log    ${response.content}
    ${data}=    Set Variable    ${response.content}
    ${data}=    To Json    ${data}
    ${data}=    Set Variable    ${data}[data]
    Log    ${data}

    ${type}    Evaluate    type(${data})
    Log    ${type}
    ${result_dict}=     Convert to Json     ${data}

    ${acutal_reslut}=   Get From Dictionary    ${result_dict}    reply_id
    Should Be Equal As Strings    ${acutal_reslut}    newCommissionCompareMessage
#    Run Keyword And Continue On Failure    Log    ${data}[rows][0][10]


Click button "Lihat Detail"
    Set Test Variable    ${interactive_msg}    {"context":{"from":"6285283239812","id":"wamid.HBgNODYxOTgzMDQ0MTQ2MRUCABEYEjE0ODQyM0Q0QjU4QTUzMEVFOAA="},"from":"8619830441461","id":"wamid.HBgNODYxOTgzMDQ0MTQ2MRUCABIYIDI5NUE2RUE4RDY4MkZFRjgzRDczREI2MjcwOTk2OThFAA==","timestamp":"1751270518","type":"interactive","interactive":{"type":"button_reply","button_reply":{"id":"getPriceDetail","title":"Lihat Detail"}}}

    ${resonse}=     pchat_whatsapp_webhook.Send Request And Get Response Data    ${interactive_msg}
    Log    ${resonse}
    Log    ${resonse.text}
    Should Be Equal    ${resonse.text}    EVENT_RECEIVED
    Sleep    10s


Return Msg "price_comparision_pdf" and "price_comparision_id_0508"
    ${response}=    dbUtil.Query    select * from message.whatsapp_chat_record where whatsapp_id = '${whatsapp_id}' order by uid desc limit 1

    Log    ${response}
#    Register Keyword To Run On Failure    keyword
#    Run Keyword And Continue On Failure    Log    ${response.content}
    ${data}=    Set Variable    ${response.content}
    ${data}=    To Json    ${data}
    ${data}=    Set Variable    ${data}[data]
    Log    ${data}

    ${type}    Evaluate    type(${data})
    Log    ${type}
    ${result_dict}=     Convert to Json     ${data}

    ${acutal_reslut}=   Get From Dictionary    ${result_dict}    reply_id
    Should Be Equal As Strings    ${acutal_reslut}    price_comparision_pdf
    ${acutal_reslut}=   Get From Dictionary    ${result_dict}    reply
    Should Be Equal As Strings    ${acutal_reslut}    price_comparision_id_0508
#    Run Keyword And Continue On Failure    Log    ${data}[rows][0][10]


#Check
#    通过conversation_meta检查回复的内容
#    conversation_meta -> whatsapp -> waUserRes ->
#    For遍历waUserRes
#        1. 标准化格式
#        1.1 去除waUserRes[0]的前后引号
#        1.2 去除waUserRes[0]的\
#        1.3 转换成json格式

