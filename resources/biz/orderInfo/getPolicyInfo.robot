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

