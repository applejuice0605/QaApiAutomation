# utils/dify_workflow.py

import re
from numpy.random import f
import requests
import json
import config
from typing import Dict

from config import *


MCP_Quotation_API_KEY = SIT_MCP_Quotation_API_KEY
MCP_list_policies_API_KEY = SIT_MCP_list_policies_API_KEY

Compare_STR_API_KEY = SIT_Compare_STR_API_KEY


# 调用报价的MCP工具
def call_mcp_Agent_Sub_Quotation(request_json_str: str) -> Dict:
    """
    调用 MCP 报价 工具，读取 JSON 字符串并发送 POST 请求。
    返回流式响应。
    获取workflow_finished事件（最后输出）的结果
    """
    print(f"调用MCP报价工具")
    print(f"request_data: {request_json_str}")
    try:
        request_data = json.loads(request_json_str)
    except json.JSONDecodeError:
        return {"error": "请求JSON格式不正确", "original_request": request_json_str}
    
    # 把json转换成字符串
    json_string_pretty = json.dumps(request_data, indent=4)

    payload = {
        "inputs": {
            "input_data": json_string_pretty,
            "token": WA_TOKEN
        },
        "files": [],
        "response_mode": "streaming",
        "user": "abc-456"
    }
    # print(f"payload: {payload}")
    mcp_output = call_dify_workflow(MCP_Quotation_API_KEY, payload)

    return mcp_output


# 调用获取保单列表的MCP工具
def call_mcp_list_policies(request_json_str: str) -> Dict:
    """
    调用 MCP 报价 工具，读取 JSON 字符串并发送 POST 请求。
    返回流式响应。
    获取workflow_finished事件（最后输出）的结果
    """
    print(f"调用MCP获取保单列表工具")
    print(f"request_data: {request_json_str}")
    try:
        request_data = json.loads(request_json_str)
    except json.JSONDecodeError:
        return {"error": "请求JSON格式不正确", "original_request": request_json_str}
    
    # 把json转换成字符串
    # json_string_pretty = json.dumps(request_data, indent=4)

    payload = {
        "inputs": request_data,
        "files": [],
        "response_mode": "streaming",
        "user": "abc-456"
    }
    print(f"payload: {payload}")
    mcp_output = call_dify_workflow(MCP_list_policies_API_KEY, payload)

    return mcp_output


# 调用Langchain API的chain FLow进入某个angent，并获取返回结果
def call_langchain_agent(input_data: str, conversation_id : str = "", agent_name: str = "kevin") -> Dict:
    """
    调用 Langchain API 的 chain Flow 进入指定 agent，并获取返回结果。
    """
    payload = {
        "files": [],
        "inputs": {
            "tenant_id": "1000662",
            "chat_temp_token": WA_TOKEN,
            "partner_uid": "1000662000000397",
            "channel_user_id": "8619830441461",
            "channel_type": "whatsapp"
        },
        "query": input_data,
        "conversation_id": conversation_id, #如果没有置空，默认值为空字符串
        "user": "test-from-postman",
        "response_mode": "streaming"
    }
    # print(f"payload: {payload}")

    mcp_output, conversation_id = call_dify_chatflow(LANGCHAIN_API_KEY, payload)
    if mcp_output is not None:
        print(f"调用angent【{conversation_id}】返回结果: {mcp_output}")
        return mcp_output, conversation_id
    else:
        print(f"调用angent【{conversation_id}】: No valid answer found in SSE stream.")
        return None, conversation_id







# 调用Dify的Workflow比较MCP返回和预期差距
def run_dify_comparison_str(mcp_response: Dict, expected: str) -> Dict:
    """
    调用 Dify 的 Workflow 比较 MCP 返回和预期差距。
    """


    payload = {
        "inputs": {
            "dify_result_input": mcp_response,
            "third_party_result_input": expected,
            "compare_type": "str"
        },
        "files": [],
        "user": "abd-456",
        "response_mode": "streaming",
    }
    # print(f"payload: {payload}")

    mcp_output = call_dify_workflow(Compare_STR_API_KEY, payload)

    return mcp_output


# 调用dify的接口，返回响应数据
def call_dify_workflow(API_KEY: str, payload: Dict) -> requests.Response:
    """
    调用 Dify 的 Workflow 接口，发送 POST 请求并返回流式响应。
    """
    headers = {
        "Authorization": f"Bearer {API_KEY}",
        "Content-Type": "application/json"
    }

    try:
        resp = requests.post(DIFY_WORKFLOW_RUN_API_URL, headers=headers, json=payload, stream=True)
        resp.raise_for_status()

        mcp_output = None
        # print(resp.text)
        for line in resp.iter_lines():
            if line:
                decoded_line = line.decode('utf-8').strip()
                if decoded_line.startswith("data: "):
                    event_data = decoded_line[6:]  # 去掉 "data: "
                    try:
                        event_json = json.loads(event_data)
                        if event_json.get("event") == "workflow_finished":
                            mcp_output = event_json.get("data", {}).get("outputs", {}).get("result")
                    except json.JSONDecodeError:
                        continue

        if mcp_output is not None:
            print(f"MCP工具【{API_KEY}】返回结果: {mcp_output}")
            return mcp_output
        else:
            print(f"MCP工具【{API_KEY}】: No valid answer found in SSE stream.")
            return None

    except requests.exceptions.RequestException as e:
        return {'error': f'{API_KEY} Dify_Workflow_Request_Failed: {e}'}
    except Exception as e:
        return {'error': f'{API_KEY} Dify_Workflow_Parsing_Failed: {e}'}











    try:
        headers = {
            "Authorization": f"Bearer Bearer {API_KEY}",
            "Content-Type": "application/json"
        }
        resp = requests.post(DIFY_API_URL, headers=headers, json=payload, stream=True)
        resp.raise_for_status()
        return resp
    except requests.exceptions.RequestException as e:
        # return 加上APIkey的值
        return {f'{API_KEY} error': f'Dify_Workflow_Request_Failed: {e}'}
    except Exception as e:
        return {f'{API_KEY} error': f'Dify_Workflow_Parsing_Failed: {e}'}


def call_dify_chatflow(API_KEY: str, payload: Dict) -> requests.Response:
    """
    调用 Dify 的 Chatflow 接口，发送 POST 请求并返回流式响应。
    """
    headers = {
        "Authorization": f"Bearer {API_KEY}",
        "Content-Type": "application/json"
    }

    try:
        resp = requests.post(DIFY_CHATFLOW_RUN_API_URL, headers=headers, json=payload, stream=True)
        resp.raise_for_status()

        mcp_output = None
        # print(resp.text)
        for line in resp.iter_lines():
            if line:
                decoded_line = line.decode('utf-8').strip()
                if decoded_line.startswith("data: "):
                    event_data = decoded_line[6:]  # 去掉 "data: "
                    try:
                        event_json = json.loads(event_data)
                        if event_json.get("event") == "workflow_finished":
                            mcp_output = event_json.get("data", {}).get("outputs", {}).get("answer")
                            conversation_id = event_json.get("conversation_id")
                    except json.JSONDecodeError:
                        continue

        if mcp_output is not None:
            print(f"调用angent【{conversation_id}】返回结果: {mcp_output}")
            return mcp_output, conversation_id
        else:
            print(f"调用angent【{conversation_id}】: No valid answer found in SSE stream.")
            return None

    except requests.exceptions.RequestException as e:
        return {'error': f'{API_KEY} Dify_Chatflow_Request_Failed: {e}'}
    except Exception as e:
        return {'error': f'{API_KEY} Dify_Chatflow_Parsing_Failed: {e}'}
