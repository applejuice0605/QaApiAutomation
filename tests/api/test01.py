# 功能：
url_query_basic = 'https://rd-dms.fuseinsurtech.com/query/'
# 【重点修改！！！！！】认证信息cookie
cookie = '_fbp=fb.1.1733142474905.999082740886285070; _ga_WC78SS231Y=GS1.2.1733142469.1.1.1733142597.60.0.0; __adroll_fpc=456d1c8ba8d7ffe36273e2e9dd9a6b3f-1733220877732; _ga_T4M2Z710MP=GS1.1.1733836515.1.0.1733836522.0.0.0; ajs_user_id=1d55ebfced2d97b904aef02306772743833ce092; ajs_anonymous_id=5fd2a4e0-111d-46b8-9850-c026a98f3fa2; _ga_NXY6JBL0TS=GS1.1.1734677139.1.1.1734677336.0.0.0; _ga=GA1.1.600245566.1736403946; _ga_XX0J2JJJYY=GS1.1.1736403946.1.1.1736406427.0.0.0; csrftoken=anemtB0sLio9z7DFQb0mhlBJi5eusxeDU9cEpdH6Jbq94utfHFDR1PdKYES7gc5j; sessionid=hld5tlidpqtflr3o7l985ei80ekdb9kg'
XCSRFToken = 'anemtB0sLio9z7DFQb0mhlBJi5eusxeDU9cEpdH6Jbq94utfHFDR1PdKYES7gc5j'
# 设置请求头
headers = {
    'Content-Type': 'application/json',
    'Cookie': cookie,
    'X-CSRFToken': XCSRFToken,
}


def login_archery():
    if len(cookie) != 0:
        print('cookie is not empty, use current: ', cookie)
        return cookie;
    login_url = 'https://rd-dms.fuseinsurtech.com/authenticate/'
    form_data = {
        'username': 'xxx',
        'password': 'xxx'
    }
    header = {
        'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
    }
    cookie = post_form(login_url, form_data, header)
    print('login token:', cookie)
    return cookie


query_instance_url = 'https://rd-dms.fuseinsurtech.com/group/user_all_instances/?tag_codes%5B%5D=can_read'
query_db_url = 'https://rd-dms.fuseinsurtech.com/instance/instance_resource/?instance_name={instance_name}&resource_type=database'
query_table_url = 'https://rd-dms.fuseinsurtech.com/instance/instance_resource/?instance_name={instance_name}&db_name={db_name}&resource_type=table'

if __name__ == '__main__':
    print(login_archery())
