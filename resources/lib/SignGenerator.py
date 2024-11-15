import json # 用于处理 JSON 数据
import hashlib # 用于 MD5 加密
import re # 用于正则表达式操作

from robot.api.deco import keyword


class SignGenerator(object):
    @keyword
    def generate_sign(self, options):
        sign = ""
        appkey = "fuseApp"
        app_secret = "fuseapp123456"
        salt = "fuse"
        data = options.get('data', {})
        params = data if isinstance(data, dict) else {}

        if not params:
            appkey = "fuseApp"
            app_secret = "fuseapp123456"
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
        print(type(sign.upper()))

        return str(sign.upper())

    def get_keyword_names(self):
        return ['generate_sign']

if __name__ == '__main__':
    options = {'data': {
    "name": "Partner-1",
    "mobile": "628123268989",
    "occupationInfo": {
        "id": "76",
        "other": ""
    },
    "locationInfo": {
        "id": "3"
    },
    "city": "Kota Jakarta Selatan",
    "postCode": "12345",
    "province": "DKI Jakarta",
    "address": "3423412uy",
    "addressId": "fdsfsd341"
}}
    result = SignGenerator.generate_sign("", options)

