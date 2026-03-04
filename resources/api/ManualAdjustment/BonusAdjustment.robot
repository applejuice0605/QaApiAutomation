*** Settings ***
Resource    ../../lib/Common.robot


*** Variables ***
${add_adjustment_Url}=  https://boss-uat.fuse.co.id/api/account/trading/manager/add
${check_taskId}=  https://boss-uat.fuse.co.id/api/adjustment/review/list/manager
${adjustment_assign_url}=  https://boss-uat.fuse.co.id/api/bpm/runtime/self/assign
${adjustment_approval_url}=  https://tmp-uat.fuse.co.id/trading/flow/approval


*** Keywords ***
Send Bonus Adjustment Post Request
    [Arguments]    ${body}  ${fusetoken}
    ${headers}=  Create Dictionary    fusetoken=${fusetoken}  Content-Type=application/json
    ${response}=  Common.Send Post Request And Get Response Data  addAdjustmentSession  ${add_adjustment_Url}  ${body}  &{headers}
    ${get_json}=  Get From Dictionary    ${response.json()}  data
    ${transactionId}=  Get From Dictionary    ${get_json}  transactionId
    RETURN  ${transactionId}

Send Check TaskId Post Request
    [Arguments]    ${fusetoken}  ${transactionId}
    ${headers}=  Create Dictionary    fusetoken=${fusetoken}  Content-Type=application/json
    ${body}=  Set Variable    {"pageNo":1,"pageSize":20,"transactionId":"${transactionId}","endTask":0,"endProcess":0,"existsAssignee":true}
    ${response}=  Common.Send Post Request And Get Response Data  checkTaskIsSession  ${check_taskId}  ${body}  &{headers}
    ${get_json}=  Get From Dictionary    ${response.json()}  data
    ${get_data}=  Get From Dictionary    ${get_json}  data
    ${get_dirt}=  Get From List        ${get_data}  0
    ${TaskId}=  Get From Dictionary    ${get_dirt}  id
    RETURN  ${TaskId}

Send Adjustment Assign Task Post Request
    [Arguments]    ${fusetoken}  ${TaskId}
    ${headers}=  Create Dictionary    fusetoken=${fusetoken}  Content-Type=application/json
    ${body}=  Set Variable    {"assignee":"ceo001","businessCode":[null],"taskIds":["${TaskId}"]}
    Common.Send Post Request And Get Response Data  assignToMeSession  ${adjustment_assign_url}  ${body}  &{headers}


Send Approval Adjustment Post Request
    [Arguments]    ${fusetoken}  ${TaskId}
    ${headers}=  Create Dictionary    fusetoken=${fusetoken}  Content-Type=application/json
    ${body}=  Set Variable   {"action":"Approval","comment":{"content":"123"},"taskId":"${TaskId}"}
    Common.Send Post Request And Get Response Data  approvalSession  ${adjustment_approval_url}  ${body}  &{headers}


Send Decline Adjustment Post Request
    [Arguments]    ${fusetoken}  ${TaskId}
    ${headers}=  Create Dictionary    fusetoken=${fusetoken}  Content-Type=application/json
    ${body}=  Set Variable   {"action":"Decline","comment":{"content":"dismiss"},"taskId":"${TaskId}"}
    Common.Send Post Request And Get Response Data  approvalSession  ${adjustment_approval_url}  ${body}  &{headers}
