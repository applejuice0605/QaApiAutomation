*** Settings ***
Library    Collections
Library    RequestsLibrary

# Suite Setup 为用例执行前的初始化 内容，一个robot 文件运行，最先执行的初始化部分，和java代码的上下文初始化一样

# 创建一个 可以复用的 网络请求上下文"jsonplaceholder" 然后指定一个url, 语法参考 session 部分
Suite Setup    Create Session  jsonplaceholder  https://jsonplaceholder.typicode.com

*** Test Cases ***

Get Request Test
  Create Session    google  http://www.google.com

  ${resp_google}=   GET On Session  google  /  expected_status=200
  ${resp_json}=     GET On Session  jsonplaceholder  /posts/1

  Should Be Equal As Strings          ${resp_google.reason}  OK
  Dictionary Should Contain Value     ${resp_json.json()}  sunt aut facere repellat provident

Post Request Test
  &{data}=    Create dictionary  title=Robotframework requests  body=This is a test!  userId=1
  ${resp}=    POST On Session    jsonplaceholder  /posts  json=${data}  expected_status=anything

  Status Should Be                 201  ${resp}
  Dictionary Should Contain Key    ${resp.json()}  id