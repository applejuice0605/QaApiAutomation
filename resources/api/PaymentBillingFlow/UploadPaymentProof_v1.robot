*** Settings ***
Resource    ../../lib/Common.robot


*** Variables ***
${uploadProof_url}=  https://cashier-uat.fuse.co.id/api/cashier/partner/payment/bs/uploadProof
${check_taskId_url}=  https://boss-uat.fuse.co.id/api/paymentBilling/list/manager
${paymentBillinAssign_url}=  https://boss-uat.fuse.co.id/api/bpm/runtime/self/assign
${paymentBillinApproval_url}=  https://boss-uat.fuse.co.id/api/bpm/flow/approval
${checkPaymentBillingInfo_url}=  https://boss-uat.fuse.co.id/api/paymentBilling/info
*** Keywords ***
Send UploadProof Post Request
    [Arguments]   ${paymentBillNo}  ${fuseToken}   ${amount}
    &{headers}=  Create Dictionary   content-type=application/json  Fusetoken=${fuseToken}  language=en-US  appcode=IDP_BOSS
    ${body}=  Set Variable     {"paymentBillNo":"${paymentBillNo}","uploadProofLs":[{"amount":${amount},"attachmentLs":[{"fileKey":"fuse-id-core-prod-rw_images/20241105/b6134390a2494cd082f14b033a1e4298.jpg","fileName":"1.jpg","fileType":"jpg","fileUrl":"https://oss-pre.fuse.co.id/images/20241105/b6134390a2494cd082f14b033a1e4298.jpg?Expires=1730851199&OSSAccessKeyId=LTAI5tPgSx4JTJLnSZwvmfay&Signature=t%2FuPG9kZo1v5LH7dFXZgNzOFySs%3D","uploadUrl":"https://fuse-id-core-prod-rw.oss-ap-southeast-5.aliyuncs.com/images/20241105/b6134390a2494cd082f14b033a1e4298.jpg?Expires=1730772204&OSSAccessKeyId=LTAI5tPgSx4JTJLnSZwvmfay&Signature=B8Nmq8nty9AehqREhgSE4XwFH10%3D","name":"1.jpg","url":"https://oss-pre.fuse.co.id/images/20241105/b6134390a2494cd082f14b033a1e4298.jpg?Expires=1730851199&OSSAccessKeyId=LTAI5tPgSx4JTJLnSZwvmfay&Signature=t%2FuPG9kZo1v5LH7dFXZgNzOFySs%3D","uid":1730771907703,"status":"success","attachmentId":"fuse-id-core-prod-rw_images/20241105/b6134390a2494cd082f14b033a1e4298.jpg","attachKey":1}],"index":0,"finishTime":1730736000000,"beneficiaryBankAccount":"124000410571511","beneficiaryId":"6603000931","beneficiaryName":"PT. Asuransi Intra Asia","beneficiaryRole":1}],"transferAmount":${amount},"finalPayableAmount":10973000,"payerType":2,"beneficiaryId":"6603000931","beneficiaryBankAccount":"124000410571511","finishTime":1730736000000,"bonus":0,"point":0,"paymentScheme":1,"beneficiaryName":"PT. Asuransi Intra Asia","beneficiaryRole":1}
    ${response} =  Common.Send Post Request And Get Response Data  checkPaymentBillingNoSession  ${uploadProof_url}  ${body}  &{headers}
    RETURN   ${response}
Send PaymentBillingListManager Post Request
    [Arguments]   ${paymentBillNo}  ${fuseToken}
    &{headers}=  Create Dictionary   content-type=application/json  Fusetoken=${fuseToken}  language=en-US  appCode=IDP_BOSS
    ${body}=  Set Variable     {"endTask":0,"endProcess":0,"pageNum":1,"pageSize":20,"multiFieldQuery":"${paymentBillNo}"}
    ${response} =  Common.Send Post Request And Get Response Data  PaymentBillingListmanagerSession  ${check_taskId_url}  ${body}  &{headers}
    ${get_data}=  Get From Dictionary    ${response.json()}  data
    ${get_data2}=  Get From Dictionary    ${get_data}  data
    ${get_dirt}=  Get From List        ${get_data2}  0
    ${id}=  Get From Dictionary    ${get_dirt}  id
    RETURN  ${id}
    
Send Assign Post Request
    [Arguments]   ${id}  ${fuseToken}
    &{headers}=  Create Dictionary   content-type=application/json  Fusetoken=${fuseToken}  language=en-US
    ${body}=  Set Variable     {"assignee":"ceo001","businessCode":[null],"taskIds":["${id}"]}
    ${response} =  Common.Send Post Request And Get Response Data  PaymentBillingListmanagerSession  ${paymentBillinAssign_url}  ${body}  &{headers}
#    RETURN  ${id}

Send PaymentBillingFlow Approval Request
    [Arguments]    ${paymentBillNo}   ${paymentSlipNo}  ${referenceNo}  ${id}  ${fuseToken}  ${actualAmount}
    &{headers}=  Create Dictionary    content-type=application/json  Fusetoken=${fuseToken}  language=en-US
    ${body}=  Set Variable   {"action":"Approval","comment":{"classify1":""},"data":{"paymentBillingNo":"${paymentBillNo}","confirmSlipLs":[{"amount":${actualAmount},"beneficiaryBankAccount":"124000410571511","beneficiaryId":"6603000931","beneficiaryName":"PT. Asuransi Intra Asia","beneficiaryRole":1,"bizId":"1856872868960079874","bizTransactionId":"DB8AC2AB81544E74AE854D9439590920","bizType":1,"body":"INTRA ASIA BASIC CAR","channelAccountId":302,"channelCode":"offline","channelId":9,"currency":"IDR","expirationTime":1731634366000,"extra":{"mpCode":"M_00004","source":0,"groupId":"1856872868960079874","orderId":"1856872868960079874","orderNo":"FUSE-20241114-083245653","version":2,"realName":"Wei","bizSource":1,"payerType":2,"businessId":"FUSE-20241114-083245653","partnerUid":1800007807690,"insuredName":"2024-11-14 09:32:43.956569 Cece-Api","orderSlipId":"1856872872550404097","partnerCode":"99485f35","partnerName":"Wei","customerCity":"Kab. Cilegon","customerName":"","partnerEmail":"SHIRLEY22@FUSEINSURTECH.COM","partnerMobile":"8123268989","partnerAddress":"place","productCategory":"car","customerDistrict":"Citangkil","customerProvince":"Banten","insuranceCompanyAbbr":"INTRA ASIA"},"finishTime":1730736000000,"initTime":1731547970000,"methodChannelId":110,"methodCode":"1101","methodId":10048,"paymentBillingId":13462,"paymentBillingNo":"${paymentBillNo}","paymentSlipNo":"${paymentSlipNo}","referenceNo":"${referenceNo}","status":2,"subject":"paying[FUSE-20241114-083245653]","tenantId":1000662,"userId":"1800007807690","voucherSchema":[{"attachKey":"1","attachmentId":"fuse-id-core-prod-rw_images/20241105/b6134390a2494cd082f14b033a1e4298.jpg","code":"96FDC17631894B06A73C54579ACF99FF","tradingId":"5AB4BB911DBB4169AD7131584461CFEA","tradingType":1,"uid":5537}],"index":0,"actualAmount":10973000,"attachmentLs":[{"fileKey":"fuse-id-core-prod-rw_pdf/20241114/ea11117e954642e99b58d2775bfb3226.pdf","fileName":"1.pdf","fileType":"pdf","fileUrl":"https://oss-pre.fuse.co.id/pdf/20241114/ea11117e954642e99b58d2775bfb3226.pdf?Expires=1731628799&OSSAccessKeyId=LTAI5tPgSx4JTJLnSZwvmfay&Signature=m3XrqG0p2baRDx8zVOdgobCtl5Y%3D","uploadUrl":"https://fuse-id-core-prod-rw.oss-ap-southeast-5.aliyuncs.com/pdf/20241114/ea11117e954642e99b58d2775bfb3226.pdf?Expires=1731548529&OSSAccessKeyId=LTAI5tPgSx4JTJLnSZwvmfay&Signature=K5JvDOZSmfqWoyI301r6G%2F%2Fb8qo%3D","name":"1.pdf","url":"https://oss-pre.fuse.co.id/pdf/20241114/ea11117e954642e99b58d2775bfb3226.pdf?Expires=1731628799&OSSAccessKeyId=LTAI5tPgSx4JTJLnSZwvmfay&Signature=m3XrqG0p2baRDx8zVOdgobCtl5Y%3D","uid":1731548242554,"status":"success","attachmentId":"fuse-id-core-prod-rw_pdf/20241114/ea11117e954642e99b58d2775bfb3226.pdf","attachKey":1}]}],"finalPayableAmount":10973000,"overpaymentAmount":0,"paymentBillNo":"1856872888643821569","paymentBizType":1,"paymentBizId":"1856872868960079874","businessId":"FUSE-20241114-083245653","methodCode":"1101","balanceDeductionLs":[],"bonus":0,"point":0,"payerType":2,"paymentScheme":1,"bizAmount":10973000,"finishTime":1730736000000,"beneficiaryBankAccount":"124000410571511","actualPaymentAmount":${amount},"beneficiaryId":"6603000931","beneficiaryName":"PT. Asuransi Intra Asia","beneficiaryRole":1,"beneficiaryOptions":[{"beneficiaryId":"6603000931","beneficiaryName":"PT. Asuransi Intra Asia","beneficiaryRole":1},{"beneficiaryId":"6604000375","beneficiaryName":"PT Pialang Asuransi Indotekno","beneficiaryRole":2}],"transactionId":"","bizTransactionId":"","orderId":""},"taskId":"${id}"}
    ${response} =  Common.Send Post Request And Get Response Data  paymentBillingApprovalSession  ${paymentBillinApproval_url}  ${body}  &{headers}
    
Send Check PaymentBillingInfo Post Request
    [Arguments]   ${paymentBillNo}   ${fuseToken}
    &{headers}=  Create Dictionary    content-type=application/json  Fusetoken=${fuseToken}  language=en-US
    ${body}=  Set Variable   {"paymentBillingNo":"${paymentBillNo}"}
    ${response} =  Common.Send Post Request And Get Response Data  checkPaymentBillingInfoSession  ${checkPaymentBillingInfo_url}  ${body}  &{headers}
#    ${get_data}=  Get From Dictionary    ${response.json()}  data
#    ${get_string}=  Convert Json To String    ${response.json()}
#    ${json_file_path}=  Set Variable    resources/data/uploadPaymentBilling/checkPaymentBillingInfo_response.json
##    ${json_data}=  To Json    ${response.json()}
    ${get_data}=  Get From Dictionary    ${response.json()}  data
    ${slipLs}=  Get From Dictionary    ${get_data}  slipLs
    ${get_dirct1}=  Get From List       ${slipLs}  0
    ${paymentSlipNo}=  Get From Dictionary       ${get_dirct1}  paymentSlipNo
    ${referenceNo}=  Get From Dictionary       ${get_dirct1}  referenceNo

    ${slipInfos}=  Get From Dictionary    ${get_data}  slipInfos
    ${get_dirct2}=  Get From List    ${slipInfos}  0
    ${slipTotalPaymentAmount}=  Get From Dictionary    ${get_dirct2}  slipTotalPaymentAmount
    ${data}=  Create Dictionary    gross_amount=${slipTotalPaymentAmount}  paymentSlipNo=${paymentSlipNo}  referenceNo=${referenceNo}
#    Create File    ${json_file_path}  ${get_string}
    RETURN  ${data}