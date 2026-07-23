*** Settings ***
Resource    ../../../resources/api/orderInfo/policyDetail.robot

*** Keywords ***
Send request to order/v2/slip/slipLs API to get slipUids
    [Arguments]     ${token}     ${orderId}
    Sleep    5s
    ${response}    policyDetail.POST FusePro:/api/order/v2/slip/slipLs     token=${token}   orderId=${orderId}
    Set Test Variable    ${jsonResult}    ${response.json()}
    Log    ${jsonResult}

The response should contain slipUids
    [Arguments]     ${jsonResult}
    @{LIST}    Set Variable     ${jsonResult}[data]
    ${slipUids}    Create List
    FOR    ${element}    IN    @{LIST}
        Log    ${element}
        Append To List    ${slipUids}    ${element['uid']}
    END
    Set Test Variable    ${slipUids}


Send request to Boss:/api/oms/slip/v2/list API to get slipStatus
    [Arguments]     ${token}     ${orderNo}
    Set Test Variable    ${bossTokenForSlipStatus}    ${token}
    Set Test Variable    ${orderNoForSlipStatus}    ${orderNo}
    Wait Until Keyword Succeeds    5x    5s    Request Boss Slip Status List    ${token}    ${orderNo}

The response's=${jsonResult} slipStatus should be ${slipStatus}
    [Documentation]    兼容既有两段式调用：直接校验当前 ${jsonResult} 的 slipStatus
    Verify slipStatus from current jsonResult    ${slipStatus}

[Retry] Get slipStatus from Boss and verify
    [Documentation]    查询 Boss slipStatus 并校验；若状态未达预期则重试
    [Arguments]    ${token}    ${orderNo}    ${slipStatus}    ${retry_count}=5x    ${retry_interval}=5s
    Wait Until Keyword Succeeds    ${retry_count}    ${retry_interval}    Get And Verify Slip Status    method_type=Boss_Slip_V2_List    token=${token}    orderNo=${orderNo}    slipStatus=${slipStatus}

Get And Verify Slip Status
    [Documentation]    内部辅助关键字：发起查询并校验 slipStatus，供 Wait Until... 重试调用
    [Arguments]    ${method_type}    ${token}    ${orderNo}    ${slipStatus}
    IF    '${method_type}' == 'Boss_Slip_V2_List'
        Request Boss Slip Status List    ${token}    ${orderNo}
    ELSE
        Log    ${method_type} is not supported
    END
    Verify slipStatus from current jsonResult    ${slipStatus}

Request Boss Slip Status List
    [Documentation]    单次请求 Boss slipStatus 列表并写入 ${jsonResult}
    [Arguments]    ${token}    ${orderNo}
    Sleep    8s
    ${response}    policyDetail.POST Boss:/api/oms/slip/v2/list     token=${token}   orderNo=${orderNo}
    Set Test Variable    ${jsonResult}    ${response.json()}
    Log    ${jsonResult}

Verify slipStatus from current jsonResult
    [Arguments]    ${slipStatus}
    Log    ${jsonResult}
    ${total}    Set Variable    ${jsonResult}[data][total]
    FOR    ${counter}    IN RANGE    0    ${total}
        Log    ${counter}
        ${item_slipStatus}    Get From Dictionary    ${jsonResult}[data][data][${counter}]    slipStatus
        Should Be True    ${item_slipStatus} == ${slipStatus}
    END

