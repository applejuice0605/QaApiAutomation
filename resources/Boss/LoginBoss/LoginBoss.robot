*** Settings ***
Resource    ../../lib/Common.robot

*** Variables ***
${boss_byLogin}=  https://sso-uat.fuse.co.id/api/sso/h5/user/tenants/byLogin
${boss_userLogin}=  https://sso-uat.fuse.co.id/api/sso/h5/user/login
${BossLoginAccount}=   ceo001
${BossPassword}=  Fuse!001

*** Keywords ***
Send Boss_byLogin Post Request
    &{headers}=  Create Dictionary     Content-Type=application/json   appCode=IDP_BOSS
    ${body}=  Set Variable   {"loginAccount":"${BossLoginAccount}","password":"${BossPassword}"}
    ${response}=  Common.Send Post Request And Get Response Data  BossByLoginSession  ${boss_byLogin}  ${body}  &{headers}
    ${get_data}=  Get From Dictionary    ${response.json()}  data
    ${get_dirt}=  Get From List       ${get_data}  1
    ${tenantId}=  Get From Dictionary    ${get_dirt}  tenantId
    ${openId}=  Get From Dictionary    ${get_dirt}  openId
    ${data}=  Create Dictionary    openId=${openId}    tenantId=${tenantId}
    RETURN  ${data}


Send boss_userLogin Post Request
    ${get_data}=  Send Boss_byLogin Post Request
    ${tenantId}=  Get From Dictionary    ${get_data}  tenantId
    ${openId}=  Get From Dictionary    ${get_data}  openId
    &{headers}=  Create Dictionary     Content-Type=application/json   appCode=IDP_BOSS
    ${body}=  Set Variable   {"loginAccount":"${BossLoginAccount}","password":"${BossPassword}","tenantId":${tenantId},"openId":"${openId}"}
    ${response}=  Common.Send Post Request And Get Response Data  BossUserLoginSession  ${boss_userLogin}  ${body}  &{headers}
    ${get_data}=  Get From Dictionary    ${response.json()}  data
    ${fuseToken}=  Get From Dictionary    ${get_data}  token
    ${data}=  Create Dictionary    fuseToken=${fuseToken}  tenantId=${tenantId}  openId=${openId}
    RETURN  ${data}

