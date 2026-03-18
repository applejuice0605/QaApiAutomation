from robot.api.deco import keyword
import requests

class ArcheryCookieGenerator():
    def __init__(self):
        self.session = requests.Session()

    @keyword
    def get_archery_cookie(self, username, password):
        # 1. 先访问首页，获取初始的 csrftoken (Django 等框架会在首次访问时设置)
        res = self.session.get('https://rd-dms.fuseinsurtech.com/sqlworkflow/')
        token = self.session.cookies.get('csrftoken')

        print(f"获取到的 Token: {token}")

        # 2. 带着这个 token 发送 POST 请求
        headers = {
            'X-CSRFToken': token,
            'Referer': 'https://rd-dms.fuseinsurtech.com/authenticate/'
        }
        data = {'username': username, 'password': password}
        response = self.session.post('https://rd-dms.fuseinsurtech.com/authenticate/', data=data, headers=headers)
        print(response.headers)
        # 从heards里面获取set-cookie
        set_cookie = response.headers.get('set-cookie')
        print(set_cookie)
        # set_cookie = csrftoken=7vjIixXEEYLHnH0nImTjTywXD2ezgu4wRYeVeXUfR156Sa2tGaOjZbrEKbkgJdG6; expires=Tue,16 Mar 2027 11: 09: 49 GMT; Max-Age=31449600; Path=/; SameSite=Lax, sessionid=z60axw34nmjhgg5zlkpk9b7stnhupbzx; HttpOnly; Path=/; SameSite=Lax
        # 从set_cookie中获取csrftoken和sessionid
        csrftoken = set_cookie.split(';')[0].split('=')[1]
        sessionid = set_cookie.split(';')[4].split('=')[2]
        print(f"获取到的 csrftoken: {csrftoken}")
        print(f"获取到的 sessionid: {sessionid}")
        return csrftoken, sessionid

a = ArcheryCookieGenerator()
cookie = a.get_archery_cookie('caishubin', 'XV5s3h&NGquiG9dD')
