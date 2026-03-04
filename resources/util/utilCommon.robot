*** Settings ***
Library    DateTime
Library    Collections
Library    JSONLibrary
Library    String
Library    os

Library    SeleniumLibrary

Resource    ../api/Login/loginA.robot

*** Keywords ***
Get Effective Time
    # 获取当前时间
    ${effective}   Get Current Date  result_format=%Y-%m-%d %H:%M:%S
    ${effective}    Add Time To Date    ${effective}    3 days
#    ${effective}    Evaluate    datetime.datetime(${now.year}, ${now.month}, ${now.day}, 1, 0, 0)    datetime

    Log    ${effective}
    # 转换为原始时间戳
    ${effective_timestamp}    Convert Date    ${effective}    epoch
    Log    ${effective_timestamp}
    # 转换为毫秒级时间戳
    ${effective_timestamp_ms}    Evaluate    int(round(${effective_timestamp} * 1000))
    Log    ${effective_timestamp_ms}
    RETURN    ${effective_timestamp_ms}

Get Expire Time
#    todo:增加${effective}参数
    [Arguments]    ${add_days}
    ${effective}   Get Current Date  result_format=%Y-%m-%d %H:%M:%S time_zone=GMT
    ${effective}    Add Time To Date    ${effective}    3 days
    ${expireTime}    Add Time To Date    ${effective}    365 days
    Log    ${expireTime}
    # 转换为原始时间戳
    ${expireTime_timestamp}    Convert Date    ${expireTime}    epoch
    Log    ${expireTime_timestamp}
    # 转换为毫秒级时间戳
    ${expireTime_timestamp_ms}    Evaluate    int(round(${expireTime_timestamp} * 1000))
    Log    ${expireTime_timestamp_ms}
    RETURN  ${expireTime_timestamp_ms}

Get CouponId by ProductCode
    [Arguments]    ${couponDTO}     ${productCode}
    ${couponId}    Set Variable    ${None}
    FOR    ${item}    IN    @{couponDTO}
        Log    ${item}
        ${couponId}   Set Variable    ${item}[couponAvailableList][0][couponId]
        ${item_productCode}     Get From Dictionary    ${item}    productCode
        Run Keyword If    '${item_productCode}' =='${productCode}'
        ...    Set Variable     ${couponId}   ${item}[couponAvailableList][0][couponId]

        Exit For Loop If    '${item_productCode}' =='${productCode}'
    END

    ${couponDTO}     Create Dictionary    couponId=${couponId}   productCode=${productCode}
    Log     ${couponDTO}
    RETURN    ${couponDTO}

Get CouponId by CouponCode
    [Arguments]    ${couponDTO}     ${couponCode}
    Log    ${couponDTO}
    Log    ${couponCode}
    ${couponId}    Set Variable    ${None}
    ${couponAvailableList}   Set Variable    ${couponDTO}[0][couponAvailableList]
    ${length}      Get Length    ${couponAvailableList}
    Log    ${length}
    FOR    ${counter}    IN RANGE    0    ${length}
        Log    ${counter}
        ${item}     Set Variable    ${couponAvailableList}[${counter}]
        Log    ${item}
        ${item_couponCode}     Get From Dictionary    ${item}    couponCode
        Log    ${item_couponCode}
        IF    '${item_couponCode}' == '${couponCode}'
            ${couponId}    Set Variable   ${item}[couponId]
            Log    ${couponId}
        END
        Exit For Loop If    '${item_couponCode}' == '${couponCode}'
    END
    Set Variable If    '${couponId}' == '${None}'    ${couponAvailableList}[0][couponId]    ${couponId}
    ${couponUseInfo}     Create Dictionary    couponId=${couponId}   productCode=${couponDTO}[0][productCode]
    Log     ${couponUseInfo}
    RETURN    ${couponUseInfo}

Get First Available Coupon
    [Arguments]    ${couponDTO}
    Log    ${couponDTO}
    ${couponAvailableList}   Set Variable    ${couponDTO}[0][couponAvailableList]
    ${couponId}    Set Variable    ${couponAvailableList}[0][couponId]

    ${couponUseInfo}     Create Dictionary    couponId=${couponId}   productCode=${couponDTO}[0][productCode]
    Log     ${couponUseInfo}
    RETURN    ${couponUseInfo}




Generate Random identityNo
    [Documentation]    生成随机十位数字
    ${counter}  Set Variable    0
    ${identityNo}=    Set Variable
    FOR    ${counter}    IN RANGE    0    10
        Log    ${counter}
        ${num}   Evaluate    random.randint(0,9)
        ${identityNo}=    Catenate    SEPARATOR=    ${identityNo}    ${num}
    END
#    ${type}    Evaluate    type(${identityNo})
    RETURN    ${identityNo}

Generate Random chars
    [Documentation]    生成一个6位数，包含数字+字符
    ${random_string}=    Evaluate    ''.join(random.choice(string.ascii_letters + string.digits) for _ in range(6))    random, string
    RETURN  ${random_string}


Get Installment Amount
    [Arguments]    ${installmentSchemaDTOList}    ${installmentNumber}
    ${installmentAmount}=    Set Variable    0

    Run Keyword If    ${installmentNumber} == 1
    ...    Set Test Variable     ${installmentAmount}    ${installmentSchemaDTOList}[0][amount]
    ...  ELSE IF    ${installmentNumber} == 3
    ...    Set Test Variable     ${installmentAmount}    ${installmentSchemaDTOList}[1][amount]
    ...  ELSE IF    ${installmentNumber} == 6
    ...    Set Test Variable     ${installmentAmount}    ${installmentSchemaDTOList}[2][amount]
    ...  ELSE IF    ${installmentNumber} == 12
    ...    Set Test Variable     ${installmentAmount}    ${installmentSchemaDTOList}[3][amount]

#
#    FOR    ${item}    IN    @{installmentSchemaDTOList}
#        Log    ${item}
#        ${num}    Get From Dictionary    ${item}    count
#        Log     ${num}
#        Run Keyword If    ${num} == ${installmentNumber}    Set Variable     ${installmentAmount}    ${item}[amount]
#        Exit For Loop If    '${num}' =='${installmentNumber}'
#    END
    Log   ${installmentAmount}
    ${installmentAmount}    Evaluate    int(${installmentAmount})
    RETURN    ${installmentAmount}

Get Data From Jsonfile
    [Arguments]    ${BODY_FILE_PATH}    ${key}
    Log     ${BODY_FILE_PATH}
    Log     ${key}
    ${AP_POSITIVE_DATA}=    Load JSON From File    ${BODY_FILE_PATH}
    ${jsonBody}     Set Variable    ${AP_POSITIVE_DATA["${key}"]}
    RETURN    ${jsonBody}


Generate Random Number
    [Documentation]    随机生成指定长度的数字字符串
    [Arguments]    ${length}
    ${counter}  Set Variable    0
    ${numStr}=    Set Variable
    FOR    ${counter}    IN RANGE    0    ${length}
        Log    ${counter}
        ${num}   Evaluate    random.randint(0,9)
        ${numStr}=    Catenate    SEPARATOR=    ${numStr}    ${num}
    END
#    ${type}    Evaluate    type(${identityNo})
    RETURN    ${numStr}

finally Log the OrderNo ${orderNo}
    Log    ${orderNo}

Check JSON Data List Not Empty
    [Documentation]    Check if the data list in JSON response is not empty.
    [Arguments]    ${JSON_RESPONSE}
    ${parsed_json}     Convert Json To String    ${JSON_RESPONSE}
    ${is_not_empty}    Evaluate    len(${parsed_json['data']}) > 0
#    Should Be True    ${is_not_empty}    Data list should not be empty
    RETURN    ${is_not_empty}

#BREAK IF
#    [Documentation]    Break the loop if the condition is met.
#    [Arguments]    ${condition}
#    Run Keyword If     ${condition}    BREAK

Convert to Json
    [Documentation]    Convert the given data to JSON format.
    [Arguments]     ${data}
#    Log    ${data}
#    Log    ${data.__class__}
    ${response_data}    Create List
    ${result_dict}  Create Dictionary
    #1. 遍历字典，获取column_list字段值
    ${column_list} =    Get From Dictionary    ${data}    column_list
    #2. 获取总记录数
    ${count}=   Set Variable    ${data}[affected_rows]
    Log    ${column_list} # 列表
    ${column_values} =    Get From Dictionary    ${data}    rows

    FOR    ${counter}    IN RANGE    0    ${count}
        Log    ${counter}
        ${column_value} =     Get From List    ${column_values}    ${counter}
        Log    ${column_value}
        FOR    ${key}    IN    @{column_list}
            Log    ${key}
            #2. 获得列表的index
            ${index} =    Get Index From List    ${column_list}    ${key}
            Log    ${index}
            #3. 获得列表的值
            ${value} =    Get From List    ${column_value}    ${index}
    #        Log    ${column_value}[index]
            #4. 将key和value写入字典
            ${result_dict} =    Set To Dictionary    ${result_dict}    ${key}    ${value}
        END
        Log    ${result_dict}
#        ${text}     Get From Dictionary    ${result_dict}   conversation_metadata

        Append To List    ${response_data}    ${result_dict}
    END
    Log    ${response_data}

#    ${expected_key} =    Set Variable    "whatapp_id"
#    ${index} =    Evaluate    ${column_list}.index(${expected_key})


#    ${actual_key} =    Get From List    ${column_list}    ${expected_key}


#    Log    ${actual_key}
#    ${index} =    Get Index From List    ${column_list}    ${actual_key}
#    ${index} =    Get Index From List    ${column_list}    whatapp_id

    RETURN  ${response_data}
