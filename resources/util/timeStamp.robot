*** Settings ***
Library    DateTime



*** Keywords ***
Get Effective Time
    # 获取当前时间
    ${effective}   Get Current Date  result_format=%Y-%m-%d %H:%M:%S time_zone=GMT+7
    Log    ${effective}
    # 转换为原始时间戳
    ${effective_timestamp}    Convert Date    ${effective}    epoch
    Log    ${effective_timestamp}
    # 转换为毫秒级时间戳
    ${effective_timestamp_ms}    Evaluate    int(round(${effective_timestamp} * 1000))
    Log    ${effective_timestamp_ms}
    RETURN    ${effective_timestamp_ms}

Get Expire Time
    [Arguments]    ${add_days}
    ${effective}   Get Current Date  result_format=%Y-%m-%d %H:%M:%S time_zone=GMT+7
    ${expireTime}    Add Time To Date    ${effective}    365 days
    Log    ${expireTime}
    # 转换为原始时间戳
    ${expireTime_timestamp}    Convert Date    ${expireTime}    epoch
    Log    ${expireTime_timestamp}
    # 转换为毫秒级时间戳
    ${expireTime_timestamp_ms}    Evaluate    int(round(${expireTime_timestamp} * 1000))
    Log    ${expireTime_timestamp_ms}
    RETURN  ${expireTime_timestamp_ms}