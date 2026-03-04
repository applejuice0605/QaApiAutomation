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
    Then Click button "Tambah Diskon"
    Then Return Msg "discountMessageResultMessage"
    Then Submit discount amount
    Then Return Msg "price_comparision_pdf" and "price_comparision_id_0508"
    Then Select Plan
    Then Return Msg "policy_type_option"
    Then Select car condition = "Old Car", click "Mobil Baru"
    Then Return msg "newOrderFlowMessage"
    Then Upload Document
    Then Return Msg "ocrLoadingMessage" and "quotation_form_new"



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
    Should Not Be Empty    ${resonse.text}
    Sleep    10s

Return Msg "comparisonStartMessage"
    ${response}=    dbUtil.Query    select * from message.whatsapp_chat_record where trace = '${whatsapp_id}' order by uid desc limit 1

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
    Should Not Be Empty    ${resonse.text}
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
    Should Not Be Empty    ${resonse.text}
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


Click button "Tambah Diskon"
    Set Test Variable    ${interactive_msg}    {"context":{"from":"6285283239812","id":"wamid.HBgNODYxOTgzMDQ0MTQ2MRUCABEYEkQyNEVGODA4RDAyNEI4QTk1RgA="},"from":"8619830441461","id":"wamid.HBgNODYxOTgzMDQ0MTQ2MRUCABIYIEI5NzZBRjk3MzgyNEUxNUI4NDJBMTg4RDNGNTlCRThDAA==","timestamp":"1751277600","type":"interactive","interactive":{"type":"button_reply","button_reply":{"id":"addDiscount","title":"Tambah Diskon"}}}

    ${resonse}=     pchat_whatsapp_webhook.Send Request And Get Response Data    ${interactive_msg}
    Log    ${resonse}
    Log    ${resonse.text}
    Should Not Be Empty    ${resonse.text}
    Sleep    10s


Return Msg "discountMessageResultMessage"
    ${response}=    dbUtil.Query    select * from message.whatsapp_chat_record where whatsapp_id = '${whatsapp_id}' order by uid desc limit 1
    Log    ${response}
    ${data}=    Set Variable    ${response.content}
    ${data}=    To Json    ${data}
    ${data}=    Set Variable    ${data}[data]
    Log    ${data}

    ${type}    Evaluate    type(${data})
    Log    ${type}
    ${result_dict}=     Convert to Json     ${data}

    ${acutal_reslut}=   Get From Dictionary    ${result_dict}    reply_id
    Should Be Equal As Strings    ${acutal_reslut}    discountMessageResultMessage


Submit discount amount
    Set Test Variable    ${interactive_msg}    {"context":{"from":"6285283239812","id":"wamid.HBgNODYxOTgzMDQ0MTQ2MRUCABEYEjBFM0JEM0E3NjZCNUE2NUJCRgA="},"from":"8619830441461","id":"wamid.HBgNODYxOTgzMDQ0MTQ2MRUCABIYIEU0MkQ4MzFDMjkwOEM3NEI2RTdENTlGOUU0RjcyRUU1AA==","timestamp":"1751277944","type":"interactive","interactive":{"type":"nfm_reply","nfm_reply":{"response_json":"{\\\"discountAmount\\\":\\\"360\\\",\\\"flow_token\\\":\\\"DISCOUNTNEW:8619830441461:274dedb1b522492f8260a54eae35c52c\\\"}","body":"Sent","name":"flow"}}}
    ${resonse}=     pchat_whatsapp_webhook.Send Request And Get Response Data    ${interactive_msg}
    Log    ${resonse}
    Log    ${resonse.text}
    Should Not Be Empty    ${resonse.text}
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


Select Plan
    Set Test Variable    ${interactive_msg}     {"context":{"from":"6285283239812","id":"wamid.HBgNODYxOTgzMDQ0MTQ2MRUCABEYEjJDQjQzNDg2RkFEMzRCNDNGMwA="},"from":"8619830441461","id":"wamid.HBgNODYxOTgzMDQ0MTQ2MRUCABIYIDhFRDU4MjIzQjkwRkM2NkRFMUU5NjdFRTk3NDExNDYzAA==","timestamp":"1751278203","type":"interactive","interactive":{"type":"button_reply","button_reply":{"id":"MP_00003","title":"Plan A"}}}
    ${resonse}=     pchat_whatsapp_webhook.Send Request And Get Response Data    ${interactive_msg}
    Log    ${resonse}
    Log    ${resonse.text}
    Should Not Be Empty    ${resonse.text}
    Sleep    10s


Return Msg "policy_type_option"
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
    Should Be Equal As Strings    ${acutal_reslut}    policy_type_option


Select policy type = "Renew Order", click "ya"
    ${interactive_msg}=    Set Variable    {"context":{"from":"6285283239812","id":"wamid.HBgNODYxOTgzMDQ0MTQ2MRUCABEYEjk2MzlENEZEQ0QxMjMzREZCQQA="},"from":"8619830441461","id":"wamid.HBgNODYxOTgzMDQ0MTQ2MRUCABIYIEQ2OUNBMzYxRDI2MDU3NzlDRTY1NDc1MUVEMTI4RTc3AA==","timestamp":"1751278780","type":"interactive","interactive":{"type":"button_reply","button_reply":{"id":"Renewal","title":"Ya"}}}

    ${resonse}=     pchat_whatsapp_webhook.Send Request And Get Response Data    ${interactive_msg}
    Log    ${resonse}
    Log    ${resonse.text}
    Should Not Be Empty    ${resonse.text}
    Sleep    10s

Select policy type = "New Order", click "Tidak"
    ${interactive_msg}=    Set Variable    {"context":{"from":"6285283239812","id":"wamid.HBgNODYxOTgzMDQ0MTQ2MRUCABEYEjk2MzlENEZEQ0QxMjMzREZCQQA="},"from":"8619830441461","id":"wamid.HBgNODYxOTgzMDQ0MTQ2MRUCABIYIEQ2OUNBMzYxRDI2MDU3NzlDRTY1NDc1MUVEMTI4RTc3AA==","timestamp":"1751278780","type":"interactive","interactive":{"type":"button_reply","button_reply":{"id":"New Order","title":"Tidak"}}}

    ${resonse}=     pchat_whatsapp_webhook.Send Request And Get Response Data    ${interactive_msg}
    Log    ${resonse}
    Log    ${resonse.text}
    Should Not Be Empty    ${resonse.text}
    Sleep    10s


Select car condition = "Old Car", click "Mobil Baru"
    ${interactive_msg}=    Set Variable    {"context":{"from":"6285283239812","id":"wamid.HBgNODYxOTgzMDQ0MTQ2MRUCABEYEjk2MzlENEZEQ0QxMjMzREZCQQA="},"from":"8619830441461","id":"wamid.HBgNODYxOTgzMDQ0MTQ2MRUCABIYIEQ2OUNBMzYxRDI2MDU3NzlDRTY1NDc1MUVEMTI4RTc3AA==","timestamp":"1751278780","type":"interactive","interactive":{"type":"button_reply","button_reply":{"id":"New Car","title":"Mobil Baru"}}}

    ${resonse}=     pchat_whatsapp_webhook.Send Request And Get Response Data    ${interactive_msg}
    Log    ${resonse}
    Log    ${resonse.text}
    Should Not Be Empty    ${resonse.text}
    Sleep    10s

Select car condition = "New Car", click "Mobil Bekas"
    ${interactive_msg}=    Set Variable    {"context":{"from":"6285283239812","id":"wamid.HBgNODYxOTgzMDQ0MTQ2MRUCABEYEjk2MzlENEZEQ0QxMjMzREZCQQA="},"from":"8619830441461","id":"wamid.HBgNODYxOTgzMDQ0MTQ2MRUCABIYIEQ2OUNBMzYxRDI2MDU3NzlDRTY1NDc1MUVEMTI4RTc3AA==","timestamp":"1751278780","type":"interactive","interactive":{"type":"button_reply","button_reply":{"id":"Old Car","title":"Mobil Bekas"}}}

    ${resonse}=     pchat_whatsapp_webhook.Send Request And Get Response Data    ${interactive_msg}
    Log    ${resonse}
    Log    ${resonse.text}
    Should Not Be Empty    ${resonse.text}
    Sleep    10s



Upload document
    # todo: 动态获取media id
    Set Test Variable   ${document_msg}    {"from":"8619830441461","id":"wamid.HBgNODYxOTgzMDQ0MTQ2MRUCABIYIDNEMTFFNUQzOTQyQTc2QzA2NEE1Rjc4RjFGQjA0NjJEAA==","timestamp":"1751279391","type":"image","image":{"mime_type":"image/jpeg","sha256":"xUwnlAo9RXb24KRrInXJQeHZg2gdGxNxqiokU4I8PRo=","id":"699509946392104"}}
    ${resonse}=     pchat_whatsapp_webhook.Send Request And Get Response Data    ${document_msg}
    Log    ${resonse}
    Log    ${resonse.text}
    Should Not Be Empty    ${resonse.text}
    Sleep    10s

Return Msg "ocrLoadingMessage" and "quotation_form_new"
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
    Should Be Equal As Strings    ${acutal_reslut}    ocrLoadingMessage
    Sleep    60s

    ${response}=    dbUtil.Query    select * from message.whatsapp_chat_record where whatsapp_id = '${whatsapp_id}' order by uid desc limit 1

    Log    ${response}
    ${data}=    Set Variable    ${response.content}
    ${data}=    To Json    ${data}
    ${data}=    Set Variable    ${data}[data]
    Log    ${data}

    ${type}    Evaluate    type(${data})
    Log    ${type}
    ${result_dict}=     Convert to Json     ${data}

    ${acutal_reslut}=   Get From Dictionary    ${result_dict}    reply_id
    Should Be Equal As Strings    ${acutal_reslut}    quotation_form_new



Submit discount amount
    Set Test Variable    ${interactive_msg}    {"context":{"from":"6285283239812","id":"wamid.HBgNODYxOTgzMDQ0MTQ2MRUCABEYEjBFM0JEM0E3NjZCNUE2NUJCRgA="},"from":"8619830441461","id":"wamid.HBgNODYxOTgzMDQ0MTQ2MRUCABIYIEU0MkQ4MzFDMjkwOEM3NEI2RTdENTlGOUU0RjcyRUU1AA==","timestamp":"1751277944","type":"interactive","interactive":{"type":"nfm_reply","nfm_reply":{"response_json":"{\\\"discountAmount\\\":\\\"360\\\",\\\"flow_token\\\":\\\"DISCOUNTNEW:8619830441461:274dedb1b522492f8260a54eae35c52c\\\"}","body":"Sent","name":"flow"}}}
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


Select Plan
    Set Test Variable    ${interactive_msg}     {"context":{"from":"6285283239812","id":"wamid.HBgNODYxOTgzMDQ0MTQ2MRUCABEYEjJDQjQzNDg2RkFEMzRCNDNGMwA="},"from":"8619830441461","id":"wamid.HBgNODYxOTgzMDQ0MTQ2MRUCABIYIDhFRDU4MjIzQjkwRkM2NkRFMUU5NjdFRTk3NDExNDYzAA==","timestamp":"1751278203","type":"interactive","interactive":{"type":"button_reply","button_reply":{"id":"MP_00003","title":"Plan A"}}}
    ${resonse}=     pchat_whatsapp_webhook.Send Request And Get Response Data    ${interactive_msg}
    Log    ${resonse}
    Log    ${resonse.text}
    Should Be Equal    ${resonse.text}    EVENT_RECEIVED
    Sleep    10s


Return Msg "policy_type_option"
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
    Should Be Equal As Strings    ${acutal_reslut}    policy_type_option


Select policy type = "Renew Order", click "ya"
    ${interactive_msg}=    Set Variable    {"context":{"from":"6285283239812","id":"wamid.HBgNODYxOTgzMDQ0MTQ2MRUCABEYEjk2MzlENEZEQ0QxMjMzREZCQQA="},"from":"8619830441461","id":"wamid.HBgNODYxOTgzMDQ0MTQ2MRUCABIYIEQ2OUNBMzYxRDI2MDU3NzlDRTY1NDc1MUVEMTI4RTc3AA==","timestamp":"1751278780","type":"interactive","interactive":{"type":"button_reply","button_reply":{"id":"Renewal","title":"Ya"}}}

    ${resonse}=     pchat_whatsapp_webhook.Send Request And Get Response Data    ${interactive_msg}
    Log    ${resonse}
    Log    ${resonse.text}
    Should Be Equal    ${resonse.text}    EVENT_RECEIVED
    Sleep    10s

Select policy type = "New Order", click "Tidak"
    ${interactive_msg}=    Set Variable    {"context":{"from":"6285283239812","id":"wamid.HBgNODYxOTgzMDQ0MTQ2MRUCABEYEjk2MzlENEZEQ0QxMjMzREZCQQA="},"from":"8619830441461","id":"wamid.HBgNODYxOTgzMDQ0MTQ2MRUCABIYIEQ2OUNBMzYxRDI2MDU3NzlDRTY1NDc1MUVEMTI4RTc3AA==","timestamp":"1751278780","type":"interactive","interactive":{"type":"button_reply","button_reply":{"id":"New Order","title":"Tidak"}}}

    ${resonse}=     pchat_whatsapp_webhook.Send Request And Get Response Data    ${interactive_msg}
    Log    ${resonse}
    Log    ${resonse.text}
    Should Be Equal    ${resonse.text}    EVENT_RECEIVED
    Sleep    10s


Select car condition = "Old Car", click "Mobil Baru"
    ${interactive_msg}=    Set Variable    {"context":{"from":"6285283239812","id":"wamid.HBgNODYxOTgzMDQ0MTQ2MRUCABEYEjk2MzlENEZEQ0QxMjMzREZCQQA="},"from":"8619830441461","id":"wamid.HBgNODYxOTgzMDQ0MTQ2MRUCABIYIEQ2OUNBMzYxRDI2MDU3NzlDRTY1NDc1MUVEMTI4RTc3AA==","timestamp":"1751278780","type":"interactive","interactive":{"type":"button_reply","button_reply":{"id":"New Car","title":"Mobil Baru"}}}

    ${resonse}=     pchat_whatsapp_webhook.Send Request And Get Response Data    ${interactive_msg}
    Log    ${resonse}
    Log    ${resonse.text}
    Should Be Equal    ${resonse.text}    EVENT_RECEIVED
    Sleep    10s

Select car condition = "New Car", click "Mobil Bekas"
    ${interactive_msg}=    Set Variable    {"context":{"from":"6285283239812","id":"wamid.HBgNODYxOTgzMDQ0MTQ2MRUCABEYEjk2MzlENEZEQ0QxMjMzREZCQQA="},"from":"8619830441461","id":"wamid.HBgNODYxOTgzMDQ0MTQ2MRUCABIYIEQ2OUNBMzYxRDI2MDU3NzlDRTY1NDc1MUVEMTI4RTc3AA==","timestamp":"1751278780","type":"interactive","interactive":{"type":"button_reply","button_reply":{"id":"Old Car","title":"Mobil Bekas"}}}

    ${resonse}=     pchat_whatsapp_webhook.Send Request And Get Response Data    ${interactive_msg}
    Log    ${resonse}
    Log    ${resonse.text}
    Should Be Equal    ${resonse.text}    EVENT_RECEIVED
    Sleep    10s

Return msg "newOrderFlowMessage"
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
    Should Be Equal As Strings    ${acutal_reslut}    ocrLoadingMessage
    Sleep    60s

    ${response}=    dbUtil.Query    select * from message.whatsapp_chat_record where whatsapp_id = '${whatsapp_id}' order by uid desc limit 1

    Log    ${response}
    ${data}=    Set Variable    ${response.content}
    ${data}=    To Json    ${data}
    ${data}=    Set Variable    ${data}[data]
    Log    ${data}

    ${type}    Evaluate    type(${data})
    Log    ${type}
    ${result_dict}=     Convert to Json     ${data}

    ${acutal_reslut}=   Get From Dictionary    ${result_dict}    reply_id
    Should Be Equal As Strings    ${acutal_reslut}    quotation_form_new



Upload document
    # todo: 动态获取media id
    Set Test Variable   ${document_msg}    {"from":"8619830441461","id":"wamid.HBgNODYxOTgzMDQ0MTQ2MRUCABIYIDNEMTFFNUQzOTQyQTc2QzA2NEE1Rjc4RjFGQjA0NjJEAA==","timestamp":"1751279391","type":"image","image":{"mime_type":"image/jpeg","sha256":"xUwnlAo9RXb24KRrInXJQeHZg2gdGxNxqiokU4I8PRo=","id":"699509946392104"}}
    ${resonse}=     pchat_whatsapp_webhook.Send Request And Get Response Data    ${document_msg}
    Log    ${resonse}
    Log    ${resonse.text}
    Should Be Equal    ${resonse.text}    EVENT_RECEIVED
    Sleep    10s

Return Msg "ocrLoadingMessage" and "quotation_form_new"
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
    Should Be Equal As Strings    ${acutal_reslut}    ocrLoadingMessage
    Sleep    60s

    ${response}=    dbUtil.Query    select * from message.whatsapp_chat_record where whatsapp_id = '${whatsapp_id}' order by uid desc limit 1

    Log    ${response}
    ${data}=    Set Variable    ${response.content}
    ${data}=    To Json    ${data}
    ${data}=    Set Variable    ${data}[data]
    Log    ${data}

    ${type}    Evaluate    type(${data})
    Log    ${type}
    ${result_dict}=     Convert to Json     ${data}

    ${acutal_reslut}=   Get From Dictionary    ${result_dict}    reply_id
    Should Be Equal As Strings    ${acutal_reslut}    quotation_form_new












Retrun Message
    [Arguments]   ${msg_id}
    ${response}=    dbUtil.Query    select * from message.whatsapp_chat_record where whatsapp_id = '${whatsapp_id}' and msg_id = '${msg_id}' order by uid desc limit 1
    Log    ${response}


    Log    ${response}
    ${data}=    Set Variable    ${response.content}
#    ${data}=    To Json    ${data}
    ${data}=    Set Variable    ${data}[data]
    Log    ${data}

    ${type}    Evaluate    type(${data})
    Log    ${type}
    ${result_dict}=     Convert to Json     ${data}

    ${acutal_reslut}=   Get From Dictionary    ${result_dict}    reply_id
    Should Be Equal As Strings    ${acutal_reslut}    ${msg_id}










Retrun Message
    [Arguments]    ${msg_id}
    ${response}=    dbUtil.Query    select * from message.whatsapp_chat_record where whatsapp_id = '${whatsapp_id}' and msg_id = '${msg_id}' order by uid desc limit 1
    Log    ${response}



#Check
#    通过conversation_meta检查回复的内容
#    conversation_meta -> whatsapp -> waUserRes ->
#    For遍历waUserRes
#        1. 标准化格式
#        1.1 去除waUserRes[0]的前后引号
#        1.2 去除waUserRes[0]的\
#        1.3 转换成json格式

