*** Settings ***
Resource    ../../lib/Common.robot


*** Variables ***
${withdrawal_url}=  https://ptr-uat.fuse.co.id/api/local/id/bankCard/withdraw
${withdrawalSession}=  withdrawalSession

*** Keywords ***
Send Withdrawal Post Request
    [Arguments]    ${fusetoken}   ${tenantId}  ${loginAccount}  ${withdrawalAmount}  ${password}
    ${body}=  Set Variable      {"accountId":"${loginAccount}","cardId":"1846088232371478529","withdrawAmount":${withdrawalAmount},"withdrawType":1,"autoTransferVersion":1,"passWord":"${password}","manuallyWithdraw":false}
    ${headers}=  Create Dictionary      Content-Type=application/json   fusetoken=${fusetoken}  language=en_US  clientType=ANDROID  appCode=IDP_FUSE_PRO  tenantId="${tenantId}"
    ${res}=  Common.Send Post Request And Get Response Data  ${withdrawalSession}  ${withdrawal_url}  ${body}  &{headers}
    ${get_json}=  Get From Dictionary    ${res.json()}  data
    ${enMessage}=  Get From Dictionary    ${get_json}  enMessage
    RETURN  ${enMessage}

Send Withdrawal Verification Assign To Me Post Request

Send Withdrawal Review Post Request

Send Withdrawal Payment Assign To Me Post Request

Send Withdrawal Payment Confirm Post Request