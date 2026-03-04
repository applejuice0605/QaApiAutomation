import requests

# 1. 获取访问令牌（需提前在Archery中创建API账号）
auth_url = "http://archery-server:9123/api/auth/token/"
# https://rd-dms.fuseinsurtech.com/login/
auth_data = {
    "username": "caishubin",
    "password": "XV5s3h&NGquiG9dD"
}
token = requests.post(auth_url, json=auth_data).json()["access"]