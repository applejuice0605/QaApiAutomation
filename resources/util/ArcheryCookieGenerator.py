from __future__ import annotations

from robot.api.deco import keyword
import requests

class ArcheryCookieGenerator:
    def __init__(self):
        self.session = requests.Session()

    @keyword
    def get_archery_cookie(self, username, password):
        if not username or not password:
            raise ValueError("Archery username/password 不能为空，请检查 varfile_defvar.py 或 CI 注入的变量。")

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
        # 3. 从 Session Cookies 中取 csrftoken/sessionid（更稳健，不依赖响应头 set-cookie）
        csrftoken = self.session.cookies.get("csrftoken")
        sessionid = self.session.cookies.get("sessionid")
        if not csrftoken or not sessionid:
            # 便于排查：输出状态码与少量头信息
            status = getattr(response, "status_code", None)
            location = response.headers.get("Location")
            raise RuntimeError(
                "获取 Archery csrftoken/sessionid 失败。"
                f" status_code={status}, Location={location}。"
                " 可能是用户名密码错误、站点不可访问、或登录流程变更。"
            )
        return csrftoken, sessionid

__all__ = ["ArcheryCookieGenerator"]
