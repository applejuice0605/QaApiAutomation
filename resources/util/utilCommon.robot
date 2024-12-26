*** Settings ***
Library    DateTime
Library    Collections
Library    JSONLibrary
Library    String
Library    os


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
