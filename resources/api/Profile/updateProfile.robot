*** Settings ***
Library    Collections
Library    OperatingSystem
Library     ../../lib/signGeneration.py
Resource   ../../lib/Common.robot
*** Variables ***
${updateDetail_url}=  https://app-uat.fuseinsurtech.com/insurance-finance-vs-api/api/fuse/agent/updateDetail
${updateSession}=   updateSession
${token}=  eyJhbGciOiJIUzI1NiIsInppcCI6IkRFRiJ9.eNpcUdFKwzAU_RXJ8wppm6bp3sQpDEWrIogv4ZpEF03T0qbiGPt3b1PG5t7COeeec3LvjgTjwQdpNVmmlFLOswUZxneyJDwTaZZnXFSiIgvSdsZHGbkrH9lbnd--8oIhMQ6ml33rDLID0rs9gsqBbaRqmw78Vo7TnB-dOydUq82BCdsO3ylK2tGHfrueK6U5R6xp1ff6aDIrruI0Wa8wEFQEpYdmwmrogzf9xdx9UO3kTchsdB81s5X57TCmzNOcUsEYGnXdYRsM0xfEQogKyitOJ8VXsOilTJErpvOkNEwkrCyKBMOKJBXAs6wEURpNZjt16FnLm5fna1k_PSDzA85qCEZ20EMz_F_QxuJST9Zmh0vdWE-WH-AGc_xuPMjZpeJBIpEKPCktBS15RZHRRtkG3Mp-2oCB9KTEBrx2pp_z9n8AAAD__w.zSu8FYM11pcBkrgKz3Ty5NtDoQ09-YlSLzf1LsoKqIU
*** Keywords ***
Send updateDetail Post Request
    [Arguments]    ${token}  ${sign}
    ${new_name}=   Create RandomString_5
    ${body}=  Set Variable  {"name":"Partner-${new_name}","mobile":"628123268989","occupationInfo":{"id":"76","other":""},"locationInfo":{"id":"3"},"city":"Kota Jakarta Selatan","postCode":"12345","province":"DKI Jakarta","address":"3423412uy","addressId":"fdsfsd341"}
    &{headers}=  Create Dictionary    content-type=application/json  language=id_ID  x-client-type=ANDROID  sign=${sign}  fusetoken=${token}
#    ${signGenerator}=  generate_sign   ${option}
    ${response}=  Send Post Request And Get Response Data  ${updateSession}  ${updateDetail_url}  ${body}  &{headers}
    Log  ${response}

*** Test Cases ***
TestDome
    ${option}=   Set Variable    {"name":"1","mobile":"628123268989","occupationInfo":{"id":"76","other":""},"locationInfo":{"id":"3"},"city":"Kota Jakarta Selatan","postCode":"12345","province":"DKI Jakarta","address":"3423412uy","addressId":"fdsfsd341"}
    ${sign}=  generate_sign   ${option}
    Send updateDetail Post Request  ${token}  ${sign}