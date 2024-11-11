*** Settings ***
Resource    ../../../../resources/lib/Common.robot
Resource    ../../../../resources/biz/order/Car/SaveBinderRFQ.robot
Resource    ../../../../resources/biz/order/Car/CreateBinderOrder.robot


*** Variables ***
${loginAccount}=  628123268989
${password}=  268989
${plate_no}=  1fda431
*** Test Cases ***
Double order when Plate Number already registered from same partner Success
    Given By Phone Number Login FusePro Success  ${loginAccount}   ${password}
    Then Send SaveBinderOrder Post Request
    Then Send CreateBinderOrder Post Request
*** Keywords ***
By Phone Number Login FusePro Success
    [Arguments]    ${loginAccount}   ${password}
    ${data}=  Get Token And TenantId And OpenId  ${loginAccount}  ${password}
    ${tenantId}=  Get From Dictionary    ${data}  tenantId
    ${token}=  Get From Dictionary    ${data}  token
    Set Test Variable    ${tenantId}   ${tenantId}
    Set Test Variable    ${token}   ${token}

Send SaveBinderOrder Post Request
    ${data}=  Send CarSaveBinderOrder Post Request  ${tenantId}  ${token}
    ${quoteNo}=  Get From Dictionary    ${data}   quoteNo
    ${rfqNo}=  Get From Dictionary    ${data}  rfqNo
    Set Test Variable     ${quoteNo}  ${quoteNo}
    Set Global Variable    ${rfqNo}  ${rfqNo}


Send CreateBinderOrder Post Request
    ${discountCommission}=  Set Variable     0
    ${discountSpecialBonusAmount}=  Set Variable     0
    Send CarCreateBinderOrder Post Request - Plate Number Exist  ${tenantId}  ${token}  ${quoteNo}  ${rfqNo}  ${plate_no}
