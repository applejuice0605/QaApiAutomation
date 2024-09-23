*** Settings ***
# 加载变量
#Variables    login.py
# 加载资源
Resource    ../../../resources/page/LoginPage/LoginPage.resource



*** Test Cases ***
# 通过传入不同的文件，实现不同的用例效果执行
Test Login
      # 数据获取屏蔽掉，通过约定好和配置。
      # Given 的用法？ 检查一下官方文档。
      # when
      When Open Android FUSE PRO
      # when And Then
      When Login To Android FUSE PRO

      # then
      Then Login Success

      # When
      When Logout

      Close Application

      Sleep    1S


Test Login2
      # 数据获取屏蔽掉，通过约定好和配置。
      # Given 的用法？ 检查一下官方文档。
      # when
      When Open Android FUSE PRO
      # when And Then
      When Login To Android FUSE PRO

      # then
      Then Login Success



Test RFQ
      ${category_select} get Data ${data}[2]
      When select Category ${category_select}
       # When
      When Logout

      Close Application

      Sleep    1S



# 写case
# 准备数据
# 实现用例
Close Application
    Sleep    1S

#  poetry run robot  --listener allure_robotframework:log4 --variable DATA_FILE:data/data001_ID.csv   tests/module/Login/TestLogin.robot



# 下单demo.
# webview

# 登录，周二下午。
#