from datetime import datetime

import requests
import json
import hashlib
import re
import random,string



class EditProfile:
    def __init__(self):

        self.base_url = "https://sso-uat.fuse.co.id/api/sso"


    def generate_sign(self,options):
        sign = ""
        appkey = "fuseApp"
        app_secret = "fuseapp123456"
        salt = "fuse"
        data = options.get('data', {})
        # print(f'data是:{data}')
        params = data if isinstance(data, dict) else {}

        if not params:
            try:
                value = hashlib.md5(app_secret.encode('utf-8')).hexdigest()
                sign = hashlib.md5((appkey + value + salt).encode('utf-8')).hexdigest()
            except Exception:
                pass
        else:
            sign_params = json.dumps(params, separators=(',', ':'))
            sign_params = re.sub(r'\t', '', sign_params)
            sign_params = re.sub(r'[^a-zA-Z0-9]', '', sign_params)
            sign_params = sign_params.upper()
            param_ch = sorted(sign_params.encode('ascii'))

            try:
                value = hashlib.md5(app_secret.encode('utf-8')).hexdigest()
                ss = bytes(param_ch).decode('ascii')
                sign = hashlib.md5((appkey + value + salt + ss).encode('utf-8')).hexdigest()
            except Exception:
                pass

        return sign.upper()

    def fms_login_app(self, mobile, password):
        fms_login_url = "https://app-uat.fuseinsurtech.com/insurance-finance-vs-api/api/fuse/user/login"
        fms_headers = {
            "language":"en_US",
            "version":"5.28.0.0-uat",
            "clientType":"ANDROID",
            "timeZone":"7",
            "appCode":"IDP_FUSE_PRO"
            }
        fms_loing_data = {
            "customPhone":f"{mobile}",
            "loginWay":"0",
            "loginPassWord":f"{password}",
            "countryCode":"02130000000000",
            "vision":"5.28.0.0-uat",
            "appVersion":"5.28.0.0-uat",
            "loginErrorTimes":"0",
            "deviceId":"55d7da1cff5d1e5927d45d1bf0b622f4fbec117a5edb0d3944d437ab37211772",
            "osVision":"12",
            "systemVersion":"12",
            "udid":"HUAWEIALN-AL00",
            "phoneModel":"ALN-AL00",
            "phoneType":"HUAWEI",
            "deviceType":"Android"
            }
        res = requests.post(fms_login_url, headers=fms_headers, json=fms_loing_data)
        print(type(res.json()))
        usertoken = res.json()['resultObj']['userTokken']
        print(usertoken)
        return usertoken

    def login_app(self,mobile, password):
        # 基础设置

        headers = {
            "Content-Type": "application/json",
            "version": "3.93.0.30-uat",
            "clientType":"ANDROID",
            "appCode":"IDP_FUSE_PRO",
            "language":"en_US",
            "tenantId": "1000662",
            "accountid": f"{mobile}"
        }

        bylogin_rul = f"{self.base_url}/h5/user/tenants/byLogin"
        bylogin_data = {
            "loginAccount": mobile,
            "password": password
        }
        res = requests.post(bylogin_rul, headers=headers, json=bylogin_data)
        # print(res.json())
        tenantId = res.json()['data'][0]['tenantId']
        openId = res.json()['data'][0]['openId']
        print(f"tenantId: {tenantId}, openId: {openId}")


        login_url = f"{self.base_url}/app/user/login"

        login_headers = {
            "Content-Type": "application/json",
            "version": "3.93.0.30-uat",
            "clientType": "ANDROID",
            "appCode": "IDP_FUSE_PRO",
            "language": "en_US",
            "tenantId": "1000662",
        }

        login_data = {
            "password": f"{password}",
            "loginAccount": f"{mobile}",
            "tenantId": f"{tenantId}",
            "openId": f"{openId}",
            "deviceInfo": {
                "customPhone": f"{mobile}",
                "loginWay": "0",
                "loginPassWord": f"{password}",
                "countryCode": "02130000000000",
                "vision": "3.93.0.30-uat",
                "appVersion": "3.93.0.30-uat",
                "loginErrorTimes": "0",
                "osVision": "12",
                "systemVersion": "12",
                "deviceId": "HUAWEIALN-AL00",
                "udid": "HUAWEIALN-AL00",
                "phoneModel": "ALN-AL00",
                "phoneType": "HUAWEI",
                "deviceType": "Android",
                "latitude": "30.576889",
                "longitude": "104.062873",
                "language": "en_US"
            }
        }
        # print(f"login_data: {login_data}")
        res = requests.post(login_url, headers=login_headers, json=login_data)
        # print(res.json())
        token = res.json()['data']['token']
        print(f"token: {token}")
        return token



    def editProfie(self,accountid, usertoken):
        current_date = datetime.now().strftime('%Y%m%d')
        random_name = ''.join(random.choices( string.ascii_letters, k=6))
        # token = self.login_app('628188666666','666666')
        # usertoken = self.fms_login_app('628188666666','666666')
        edit_url = "https://app-uat.fuseinsurtech.com/insurance-finance-vs-api/api/fuse/agent/updateDetail"
        edit_headers = {
            "Content-Type": "application/json",
            "version": "3.93.0.30-uat",
            "clientType": "ANDROID",
            "appCode": "IDP_FUSE_PRO",
            "language": "en_US",
            "tenantId": "1000662",
            # "fusetoken": f"{token}",
            "host": "app-uat.fuseinsurtech.com",
            "x-app-code": "IDP_FUSE_PRO",
            "x-user-token": f"{usertoken}",
            "usertoken": f"{usertoken}",
            "accountid": f"{accountid}"
        }

        edit_data = {
    f"name": f"{current_date} {random_name}",
    "mobile": "628123268989",
    "occupationInfo": {
        "id": "12",
        "other": ""
    },
    "locationInfo": {
        "id": "1"
    },
    "city": "Kota Jakarta Selatan",
    "postCode": "12345",
    "province": "DKI Jakarta",
    "address": "",
    "addressId": "1464"
}
        options = {'data': edit_data}
        print(f'options是:{options}')
        sign = self.generate_sign(options)
        print(f'生成的sign是: {sign}')
        edit_headers["sign"] = sign
        res = requests.post(edit_url, headers=edit_headers, json=edit_data)
        print(res.json())


if __name__ == '__main__':

    edit = EditProfile()
    usertoken= edit.fms_login_app("628188666666", "666666")
    # edit.login_app("628188666666", "666666")

    edit.editProfie("628188666666",usertoken)

