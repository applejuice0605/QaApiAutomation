import ast
import re

import requests
import json

# 流式 API 的 URL
CHAT_FLOW_KEY = '31f725aa-dcce-4a92-a476-e4d14db2c3ed'
API_BASE_URL = 'https://rd-dify-sit.fuse.co.id/console/api/apps/'
authorization = 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiNTUyYmRiODktNTlkOC00NDExLWJiZmYtMjM3MGQwOWQ4MTljIiwiZXhwIjoxNzQ3ODc2ODI3LCJpc3MiOiJTRUxGX0hPU1RFRCIsInN1YiI6IkNvbnNvbGUgQVBJIFBhc3Nwb3J0In0.CgLrJMKbL9g2bR1E_sESPZbsi_2DiNUWHhmBae67IQ4'
payload = {"inputs":{"result":"TOYOTA,AVANZA 1.3 E M/T (F653RM-GMDFJ),2019","type":"2"},"files":[]}

url = API_BASE_URL + CHAT_FLOW_KEY + '/workflows/draft/run'

# 设置请求头和 POST 数据（根据 API 要求调整）
headers = {
    'Content-Type': 'application/json',
    'Accept': '*/*',  # 或根据接口要求设置其他 Accept 标头
    'authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiNTUyYmRiODktNTlkOC00NDExLWJiZmYtMjM3MGQwOWQ4MTljIiwiZXhwIjoxNzQ3OTU3MTM4LCJpc3MiOiJTRUxGX0hPU1RFRCIsInN1YiI6IkNvbnNvbGUgQVBJIFBhc3Nwb3J0In0.eP6L1rbKPchNSrlHaZrJxw5Cm1JL9U0vO-Y9ZVy7IKc'
}

# POST 请求的正文数据（例如向大模型发送提问）
payload = {
    "inputs": {
        "result": "TOYOTA,AVANZA 1.3 E M/T (F653RM-GMDFJ),2019",
        "type": "2"
    },
    "files": []
}

try:
    # 发送 POST 请求，启用流式模式
    with requests.post(
        url,
        headers=headers,
        json=payload,  # 自动处理 JSON 序列化和 Content-Type
        stream=True
    ) as response:
        response.raise_for_status()  # 检查 HTTP 错误

        # 逐行读取流式数据（适用于 SSE 格式）
        for line in response.iter_lines():
            if line:
                decoded_line = line.decode('utf-8')
                print(type(decoded_line))
                print("Received chunk:", decoded_line)

                # 去掉开头的字符串“data: ”，获得正确的json格式文本
                new_string = re.sub(r'^data: ', '', decoded_line)
                print(new_string)

                # 处理结构化数据（例如 JSON 块）
                try:
                    data = json.loads(new_string)
                    print("Parsed data:", data)
                except json.JSONDecodeError:
                    print("处理非 JSON 数据")
                    pass  # 处理非 JSON 数据


                # raw_str = '{"event":"node_finished","data": {"inputs": {"result": "{\\"type\\":\\"AVANZA\\"}"}}}'
                # print(type(raw_str))
                # print(raw_str)
                # # Step 1: 首先解析外层JSON
                # outer_data = json.loads(raw_str)
                #
                # # Step 2: 获取需要二次解析的字段（修正转义）
                # inner_json_str = outer_data['data']['inputs']['result']
                #
                # # 替换可能的错误转义方案，避免逃逸破坏
                # # 例如原始数据中包含未正确转义的 \" 应替换为 \"
                # fixed_inner_str = inner_json_str.encode('utf-8').decode('unicode_escape')
                #
                # # Step 3: 解析内部JSON
                # try:
                #     inner_data = json.loads(fixed_inner_str)
                #     print("成功解析内层JSON:", inner_data)
                # except json.JSONDecodeError as e:
                #     print(f"内层解析失败: {e}")
                #
                #
                #
                #
                # # 使用正则多次处理可能的问题内层键
                # fixed_str = re.sub(
                #     r'("(result)":\s*)"(\\*{.*?\\*})"',
                #     lambda m: f'{m.group(1)}{m.group(3)}',
                #     decoded_line,
                #     flags=re.DOTALL
                # )
                # print(fixed_str)
                # decoded_data = json.loads(fixed_str)
                # print(decoded_data)


                # 处理结构化数据（例如 JSON 块）
                # try:
                # 1. 解析外层
                # outer = json.loads(decoded_line)
                # print(outer)
                # # 2. 处理内层字符串（修正）
                # inner_outputs_str = outer['data']['outputs']['result']
                # fixed_inner_str = inner_outputs_str.replace('\"', '"')  # 手动移除转义字符
                #
                # # 3. 再次解析内层数据
                # inner_outputs = json.loads(fixed_inner_str)
                #
                # print(inner_outputs)  # 输出完整字典
                # print("Parsed data:", data)
                # except json.JSONDecodeError:
                #     print("处理非 JSON 数据")
                #     pass  # 处理非 JSON 数据

                # # 处理结构化数据（例如 JSON 块）
                # try:
                #     data = json.loads(decoded_line)
                #     print("Parsed data:", data)
                # except json.JSONDecodeError:
                #     print("处理非 JSON 数据")
                #     pass  # 处理非 JSON 数据

                # try:
                #     data = ast.literal_eval(decoded_line)
                #     print("Parsed data:", data)
                # except:
                #     print("ast处理非 JSON 数据")

except requests.exceptions.RequestException as e:
    print(f"请求失败: {e}")
except KeyboardInterrupt:
    print("用户中断流式接收")