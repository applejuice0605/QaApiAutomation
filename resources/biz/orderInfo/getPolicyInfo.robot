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
    Sleep    5s
    ${response}    policyDetail.POST Boss:/api/oms/slip/v2/list     token=${token}   orderNo=${orderNo}
    Set Test Variable    ${jsonResult}    ${response.json()}
    Log    ${jsonResult}

The response's slipStatus should be ${slipStatus}
    [Arguments]     ${jsonResult}
    Log    ${jsonResult}
    ${total}    Set Variable    ${jsonResult}[data][total]
    FOR    ${counter}    IN RANGE    0    ${total}
        Log    ${counter}
        ${item_slipStatus}    Get From Dictionary    ${jsonResult}[data][data][${counter}]    slipStatus
        Should Be True    ${item_slipStatus} == ${slipStatus}
    END

