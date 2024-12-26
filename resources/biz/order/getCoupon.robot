*** Settings ***
Library    JSONLibrary
Resource    ../../api/order/getAvailableCoupon.robot
Resource    ../../util/utilCommon.robot


*** Keywords ***
I send request to getAvailableCoupon API
    [Arguments]    ${AP_POSITIVE_DATA}    ${token}
    #1. getJsonBody
    ${jsonBody}     Set Variable    ${AP_POSITIVE_DATA["couponBody"]}

    #2. convert jsonBody to string
    ${strBody}  Convert Json To String    ${jsonBody}

    #3. send request and get response data
    ${response} =    getAvailableCoupon.Send Request And Get Response Data    ${token}    ${strBody}
    Set Test Variable    ${jsonResult}    ${response.json()}
    Log    ${jsonResult}

the response should contain the available coupon list
    [Arguments]     ${jsonResult}   ${rawProductCode}
    ${couponDTO}=    utilCommon.Get CouponId by ProductCode    ${jsonResult}[data]    ${rawProductCode}
    ${couponUseInfo}    Create List     ${couponDTO}
    ${couponUseInfo}    Convert To String    ${couponUseInfo}
    ${couponUseInfo}    Replace String    ${couponUseInfo}    [    ${EMPTY}
    Set Test Variable    ${couponUseInfo}   ${couponDTO}
