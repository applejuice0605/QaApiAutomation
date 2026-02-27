*** Settings ***
Library    RequestsLibrary
Library    Collections
Library    String
Library    XML
Library    SeleniumLibrary
Library    DateTime
Library    JSONLibrary
Library    ../../resources/util/Message.py

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
    ${msg_type}  Set Variable    text
    ${content}  Set Variable    Quote
    ${msg_body}=    Get Msg Body   type=${msg_type}     content=${content}
    # -》发送请求
    ${resonse}=     pchat_whatsapp_webhook.Send Request And Get Response Data    ${msg_body}

    # 验证接口调用成功，并获得trace
    Log    ${resonse.text}
    Should Not Be Empty    ${resonse.text}
    Set Test Variable    ${trace_id}    ${resonse.text}




Return Msg "comparisonStartMessage"
    ${response_data}=    Get Response Data From DB    ${trace_id}
    Log    ${response_data}
    FOR    ${alertItem}    IN    ${response_data}
        Log    ${alertItem}
        ${acutal_reslut}=   Get From Dictionary    ${alertItem}    reply_id
        Should Be Equal As Strings    ${acutal_reslut}    comparisonStartMessage
    END


Input car info
    ${msg_type}  Set Variable    text
    ${content}  Set Variable    Toyota Innova 2022 A
    ${msg_body}=    Get Msg Body   type=${msg_type}     content=${content}
    # -》发送请求
    ${resonse}=     pchat_whatsapp_webhook.Send Request And Get Response Data    ${msg_body}

    # 验证接口调用成功，并获得trace
    Log    ${resonse.text}
    Should Not Be Empty    ${resonse.text}
    Set Test Variable    ${trace_id}    ${resonse.text}

    Sleep    20s

Return Msg "quotationCollectedFormMessage"
    ${response_data}=    Get Response Data From DB    ${trace_id}
    Log    ${response_data}
    FOR    ${alertItem}    IN    ${response_data}
        Log    ${alertItem}
        ${acutal_reslut}=   Get From Dictionary    ${alertItem}    reply_id
        Should Be Equal As Strings    ${acutal_reslut}    quotationCollectedFormMessage
    END


Sumbit QuickQuote Form
    ${msg_type}  Set Variable    flow
    ${content}  Set Variable    {\\\"brandCode\\\":\\\"TOYOTA\\\",\\\"vehicleManufactureYear\\\":\\\"2022\\\",\\\"brandModelCode\\\":\\\"ALL NEW KIJANG INNOVA\\\",\\\"brandSeriesCode\\\":\\\"2.0 G A\\/T BENSIN\\\",\\\"vehicleType\\\":\\\"MINIBUS\\\",\\\"vehicleTypeCode\\\":\\\"MINIBUS\\\",\\\"carPriceShow\\\":\\\"376,200,000\\\",\\\"coveragePeriod\\\":\\\"1\\\",\\\"plateCode\\\":\\\"B\\\",\\\"vehicleUsage\\\":\\\"2\\\",\\\"flow_token\\\":\\\"QUICK_QUOTE:8619830441461:25550e154d404cae9da8ab1abbbf7e82\\\"}
    ${msg_body}=    Get Msg Body   type=${msg_type}     content=${content}
    # -》发送请求
    ${resonse}=     pchat_whatsapp_webhook.Send Request And Get Response Data    ${msg_body}

    # 验证接口调用成功，并获得trace
    Log    ${resonse.text}
    Should Not Be Empty    ${resonse.text}
    Set Test Variable    ${trace_id}    ${resonse.text}

    Sleep    10s


Return Msg "newCommissionCompareMessage"
    ${response_data}=    Get Response Data From DB    ${trace_id}
    Log    ${response_data}
    FOR    ${alertItem}    IN    ${response_data}
        Log    ${alertItem}
        ${acutal_reslut}=   Get From Dictionary    ${alertItem}    reply_id
        Should Be Equal As Strings    ${acutal_reslut}    newCommissionCompareMessage
    END

Click button "Lihat Detail"
    ${msg_type}  Set Variable    button
    ${content}  Set Variable    {\\\"id\\\": \\\"getPriceDetail\\\",\\\"title\\\":\\\"getPriceDetail\\\"}
    ${msg_body}=    Get Msg Body   type=${msg_type}     content=${content}
    # -》发送请求
    ${resonse}=     pchat_whatsapp_webhook.Send Request And Get Response Data    ${msg_body}

    # 验证接口调用成功，并获得trace
    Log    ${resonse.text}
    Should Not Be Empty    ${resonse.text}
    Set Test Variable    ${trace_id}    ${resonse.text}

    Sleep    10s


Return Msg "price_comparision_pdf" and "price_comparision_id_0508"
    ${response_data}=    Get Response Data From DB    ${trace_id}
    Log    ${response_data}
    FOR    ${alertItem}    IN    ${response_data}
        Log    ${alertItem}
        ${acutal_reslut}=   Get From Dictionary    ${alertItem}    reply_id
        Should Be Equal As Strings    ${acutal_reslut}    price_comparision_pdf
        ${acutal_reslut}=   Get From Dictionary    ${alertItem}    reply
        Should Be Equal As Strings    ${acutal_reslut}    price_comparision_id_0508
    END


Get Response Data From DB
    [Arguments]     ${trace_id}
    FOR    ${counter}    IN RANGE    1    5
        ${response_data}=    dbUtil.Query by Trace_id    ${trace_id}
        #如果${response_data}长度<1，或等于空，继续循环
    #                IF    ${response_data} == [] or ${response_data} == ${None}
        #如果${response_data}长度>1，不空，退出循环
        IF    ${response_data} != [] and ${response_data} != ${None}
                BREAK
        ELSE IF     ${counter} == 5
            Fail    "数据库查询无结果"
        ELSE
               CONTINUE
        END
    END
    RETURN  ${response_data}

#Check
#    通过conversation_meta检查回复的内容
#    conversation_meta -> whatsapp -> waUserRes ->
#    For遍历waUserRes
#        1. 标准化格式
#        1.1 去除waUserRes[0]的前后引号
#        1.2 去除waUserRes[0]的\
#        1.3 转换成json格式

