*** Settings ***
Resource    ../../lib/Common.robot


*** Variables ***
${withdrawal_url}=  https://ptr-uat.fuse.co.id/api/local/id/bankCard/withdraw
${check_partnerCode_url}=  https://boss-uat.fuse.co.id/api/prm/partner/manager/list
${check_manualWithdrawalTaskId_url}=  https://boss-uat.fuse.co.id/api/trading/withdrawal/bpm/manager/verification/list
${withdrawalVerifation_assign}=  https://boss-uat.fuse.co.id/api/bpm/runtime/self/assign
${withdrawalVerifation_review}=  https://boss-uat.fuse.co.id/api/bpm/flow/approval
${withdrawalPayment_assign}=  https://boss-uat.fuse.co.id/api/bpm/runtime/self/assign
${withdrawalPaymentConfirm_url}=  https://boss-uat.fuse.co.id/api/bpm/flow/approval
${withdrawalSession}=  withdrawalSession
${manual_withdrawal}=   https://ptr-uat.fuse.co.id/api/local/id/bankCard/withdraw/manual
${withdrawalPaymentTaskId}=  https://boss-uat.fuse.co.id/api/trading/withdrawal/bpm/manager/payment/list
${withdrawalPaymentAssign}=  https://boss-uat.fuse.co.id/api/bpm/runtime/self/assign
*** Keywords ***
Send Withdrawal Post Request
    [Arguments]    ${fusetoken}   ${tenantId}  ${loginAccount}  ${withdrawalAmount}  ${password}
    ${body}=  Set Variable      {"accountId":"${loginAccount}","cardId":"1846088232371478529","withdrawAmount":${withdrawalAmount},"withdrawType":1,"autoTransferVersion":1,"passWord":"${password}","manuallyWithdraw":false}
    ${headers}=  Create Dictionary      Content-Type=application/json   fusetoken=${fusetoken}  language=en_US  clientType=ANDROID  appCode=IDP_FUSE_PRO  tenantId="${tenantId}"
    ${res}=  Common.Send Post Request And Get Response Data  ${withdrawalSession}  ${withdrawal_url}  ${body}  &{headers}
    ${get_json}=  Get From Dictionary    ${res.json()}  data
    ${enMessage}=  Get From Dictionary    ${get_json}  enMessage
#    Run Keyword If   '${enMessage}'=='You have exceeded daily instant withdrawal limit, you can only proceed the withdrawal by using manual disbursement. This process will take two working days maximum.'      Send Withdrawal Verification Assign To Me Post Request
    RETURN  ${enMessage}

Send Manual withdrawal Post Rquest
    [Arguments]    ${fusetoken}   ${tenantId}  ${loginAccount}  ${withdrawalAmount}  ${password}
    ${body}=  Set Variable      {"accountId":"${loginAccount}","cardId":"1846088232371478529","withdrawAmount":"${withdrawalAmount}","withdrawType":1,"autoTransferVersion":1,"passWord":"${password}","manuallyWithdraw":true}
    ${headers}=  Create Dictionary      Content-Type=application/json   fusetoken=${fusetoken}  language=en_US  clientType=ANDROID  appCode=IDP_FUSE_PRO  tenantId="${tenantId}"
    ${res}=  Common.Send Post Request And Get Response Data   manual_withdrawalSession  ${manual_withdrawal}  ${body}  &{headers}
    ${get_json}=  Get From Dictionary    ${res.json()}  data
    ${withdrawalId}=  Get From Dictionary    ${get_json}  withdrawalId
#    Run Keyword If   '${enMessage}'=='You have exceeded daily instant withdrawal limit, you can only proceed the withdrawal by using manual disbursement. This process will take two working days maximum.'      Send Withdrawal Verification Assign To Me Post Request
    RETURN  ${withdrawalId}

Send Check Manual Withdrawal TaskId Post Request
    [Arguments]    ${fusetoken}  ${withdrawalId}
    ${body}=  Set Variable       {"endTask":0,"endProcess":0,"pageNum":1,"pageSize":20,"withdrawalId":"${withdrawalId}"}
    ${headers}=  Create Dictionary      Content-Type=application/json   fusetoken=${fusetoken}  language=en_US
    ${res}=  Common.Send Post Request And Get Response Data    WithdrawalTaskIdlSession   ${check_manualWithdrawalTaskId_url}  ${body}  &{headers}
    ${get_json}=  Get From Dictionary    ${res.json()}  data
    ${get_data}=  Get From Dictionary    ${get_json}  data
    ${get_dirt}=  Get From List    ${get_data}  0
    ${taskId}=  Get From Dictionary    ${get_dirt}  id
    RETURN  ${taskId}

Send Withdrawal Verification Assign To Me Post Request
    [Arguments]    ${fusetoken}   ${taskId}
    ${body}=  Set Variable      {"assignee":"ceo001","businessCode":[null],"taskIds":["${taskId}"]}
    ${headers}=  Create Dictionary      Content-Type=application/json   fusetoken=${fusetoken}  language=en_US
    ${res}=  Common.Send Post Request And Get Response Data  assignVerificationSession  ${withdrawalVerifation_assign}  ${body}  &{headers}
    
Send Withdrawal Review Post Request
     [Arguments]    ${fusetoken}   ${taskId}  ${withdrawalId}
    ${body}=  Set Variable      {"action":"Approval","comment":{"classify1":""},"data":{"withdrawId":"${withdrawalId}","confirmSlipLs":[],"transactionId":"","paymentBillingNo":"","bizTransactionId":"","orderId":""},"taskId":"${taskId}"}
    ${headers}=  Create Dictionary      Content-Type=application/json   fusetoken=${fusetoken}  language=en_US
    ${res}=  Common.Send Post Request And Get Response Data  reviewVerificationSession  ${withdrawalVerifation_review}  ${body}  &{headers}

Send Check Payment Withdrawal TaskId Post Request
    [Arguments]    ${fusetoken}  ${withdrawalId}
    ${body}=  Set Variable       {"endTask":0,"endProcess":0,"pageNum":1,"pageSize":20,"withdrawalId":"${withdrawalId}"}
    ${headers}=  Create Dictionary      Content-Type=application/json   fusetoken=${fusetoken}  language=en_US
    ${res}=  Common.Send Post Request And Get Response Data    withdrawalPaymentTaskId   ${withdrawalPaymentTaskId}  ${body}  &{headers}
    ${get_json}=  Get From Dictionary    ${res.json()}  data
    ${get_data}=  Get From Dictionary    ${get_json}  data
    ${get_dirt}=  Get From List    ${get_data}  0
    ${taskId}=  Get From Dictionary    ${get_dirt}  id
    RETURN  ${taskId}

Send Withdrawal Payment Assign To Me Post Request
    [Arguments]    ${fusetoken}   ${PaymentTaskId}
    ${body}=  Set Variable     {"assignee":"ceo001","businessCode":[null],"taskIds":["${PaymentTaskId}"]}
    ${headers}=  Create Dictionary      Content-Type=application/json   fusetoken=${fusetoken}  language=en_US
    ${res}=  Common.Send Post Request And Get Response Data  withdrawalPaymentAssign  ${withdrawalPaymentAssign}  ${body}  &{headers}

Send Withdrawal Payment Confirm Post Request
     [Arguments]    ${fusetoken}   ${PaymentTaskId}  ${withdrawalId}
    ${body}=  Set Variable      {"action":"ConfirmPayment","comment":{"classify1":""},"data":{"attachmentIds":["fuse-id-core-prod-rw_images/20241107/7381d96c1a55403d8b71340789edd44c.jpg","fuse-id-core-prod-rw_images/20241107/dda2e3b770594b2bb9e111135724cf7f.jpg"],"paymentTime":1730908800000,"withdrawId":"${withdrawalId}","confirmSlipLs":[],"transactionId":"","paymentBillingNo":"","bizTransactionId":"","orderId":""},"taskId":"${PaymentTaskId}"}
    ${headers}=  Create Dictionary      Content-Type=application/json   fusetoken=${fusetoken}  language=en_US
    ${res}=  Common.Send Post Request And Get Response Data  withdrawalPaymentConfirmSession  ${withdrawalPaymentConfirm_url}  ${body}  &{headers}

Send Withdrawal Review Decline Post Request
     [Arguments]    ${fusetoken}   ${taskId}  ${withdrawalId}
    ${body}=  Set Variable      {"action":"Decline","comment":{"classify1":"","content":"api_test_decline"},"data":{"withdrawId":"${withdrawalId}","comments":"decline","confirmSlipLs":[],"transactionId":"","paymentBillingNo":"","bizTransactionId":"","orderId":""},"taskId":"${taskId}"}
    ${headers}=  Create Dictionary      Content-Type=application/json   fusetoken=${fusetoken}  language=en_US
    ${res}=  Common.Send Post Request And Get Response Data  reviewVerificationSession  ${withdrawalVerifation_review}  ${body}  &{headers}

