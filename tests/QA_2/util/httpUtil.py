# 定义httpUtil工具类，存放各种调用http请求的静态方法
import json
from datetime import datetime
from typing import Any, Dict

import requests

# 根据traceId从数据库中查询数据
def getAnswerFromDB_bytraceId(trace_id):
    print("start queryDB_bytraceId")

    """
    调用webhook发送文本消息
    """
    # https://pchat-uat.fuse.co.id/api/ai/chatbot/whatsapp/webhook

    url = f"https://rd-dms.fuseinsurtech.com/query/"
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                      "AppleWebKit/537.36 (KHTML, like Gecko) "
                      "Chrome/137.0.0.0 Safari/537.36",
        "content-type": "application/x-www-form-urlencoded",
        "cookie": "csrftoken=EEAEDHm55KfMrKshPvHsHskULEiH3hQOOdXHKan4vpTgOtyyai0R0xmIEN36xyik; sessionid=fnpwm2s5h3qo99l38e1blq6vg57pz5su",
        "x-csrftoken": "EEAEDHm55KfMrKshPvHsHskULEiH3hQOOdXHKan4vpTgOtyyai0R0xmIEN36xyik"
    }
    if type(trace_id) != str:
        trace_id = str(trace_id)

    # trace_id = '8c6f64a18338a8da'

    sql_content = f"select reply from message.whatsapp_chat_record where 1=1 and trace_id = '{trace_id}' order by uid desc limit 1"

    # TODO：动态获取messgae from的wa_id, wa_token，business_account_id
    payload = {
        "instance_name" : "SG_SIT_MYSQL8_RW",
        "db_name" : "message",
        "schema_name" : None,
        "tb_name": None,
        "sql_content" : sql_content,
        "limit_num" : "100"
    }
    try:
        resp = requests.post(url, headers=headers, data=payload)
        resp = requests.post(url, headers=headers, data=payload)
        print(resp.json())

    except requests.RequestException as e:
        print(f"Error calling db: {e}")
        if hasattr(e, 'response') and e.response:
            print(f"Response status: {e.response.status_code}")
            print(f"Response body: {e.response.text}")
        return "Error calling db"

    if resp.json()['data']['affected_rows'] == 0:
        answer = trace_id + "在数据库中没有找到数据"
    else:
        answer = resp.json()['data']['rows'][0][0]

    print(answer)
    return answer


# 调用模型函数
def chat_dify_llm(base_url: str, app_id: str, system: str, query: str, token):
    # token = login()
    app_id = app_id
    # https://rd-dify-sit.fuse.co.id/console/api/apps/5749f5da-9fc2-463d-b00e-9893cc290b9b/workflows/draft/run
    url = f"{base_url.rstrip('/')}/api/apps/{app_id}/workflows/draft/run"

    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                      "AppleWebKit/537.36 (KHTML, like Gecko) "
                      "Chrome/137.0.0.0 Safari/537.36",
        "authorization": f"Bearer {token}",
        # "authorization": f"Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiNTUyYmRiODktNTlkOC00NDExLWJiZmYtMjM3MGQwOWQ4MTljIiwiZXhwIjoxNzUzNzEwNDI0LCJpc3MiOiJTRUxGX0hPU1RFRCIsInN1YiI6IkNvbnNvbGUgQVBJIFBhc3Nwb3J0In0.uZAtxK0YEYiPyymg_g6ZDp7ckeRPRCbIw00TTj7rSD8",
        "content-type": "application/json",
    }

    payload = {"inputs": {"user": query, "system": system}, "files": []}

    print(url)
    try:
        resp = requests.post(url, headers=headers, json=payload, stream=True)
        resp.raise_for_status()

        final_answer = None
        for line in resp.iter_lines():
            if line:
                decoded_line = line.decode('utf-8').strip()
                print(decoded_line)
                if decoded_line.startswith("data: "):
                    event_data = decoded_line[6:]  # 去掉 "data: "
                    try:
                        event_json = json.loads(event_data)
                        if event_json.get("event") == "workflow_finished":
                            final_answer = event_json.get("data", {}).get("outputs", {}).get("text")
                        elif event_json.get("event") == "message_end":
                            final_answer = event_json.get("metadata", {}).get("text", final_answer)
                    except json.JSONDecodeError:
                        continue

        if final_answer is not None:
            return final_answer
        else:
            print("No valid answer found in SSE stream.")
            print(resp)
            return None

    except requests.RequestException as e:
        print(f"Error calling chat: {e}")
        if hasattr(e, 'response') and e.response:
            print(f"Response status: {e.response.status_code}")
            print(f"Response body: {e.response.text}")
        return None

# 调用dify的workflow
def req_dify_work_RAG(base_url: str, app_id: str, query: str, access_token:str) -> tuple[Any | None, Any | None, Any | None] | None:
    print("调用dify的RAG workflow")
    """
    对指定数据集做 hit-testing，返回接口完整 JSON。
    retrieval_model 留空时使用默认 hybrid_search 配置。
    """
    # https://rd-dify-sit.fuse.co.id/console/api/apps/a1936725-1498-452c-8310-b81e94936703/workflows/draft/run
    url = f"{base_url.rstrip('/')}/api/apps/{app_id}/workflows/draft/run"
    print(url)
    # access_token = login()
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                      "AppleWebKit/537.36 (KHTML, like Gecko) "
                      "Chrome/137.0.0.0 Safari/537.36",
        "authorization": f"Bearer {access_token}",
        # "authorization": f"Bearer logineyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiNTUyYmRiODktNTlkOC00NDExLWJiZmYtMjM3MGQwOWQ4MTljIiwiZXhwIjoxNzUzNzEwNDI0LCJpc3MiOiJTRUxGX0hPU1RFRCIsInN1YiI6IkNvbnNvbGUgQVBJIFBhc3Nwb3J0In0.uZAtxK0YEYiPyymg_g6ZDp7ckeRPRCbIw00TTj7rSD8",
        "content-type": "application/json",
        "sec-fetch-site": "same-origin",
        "sec-fetch-mode": "cors"
    }
    if type(query) != str:
        query=str(query)
    # query="Do you have car product?"


    print("workflow_question: ", query)
    payload = {
        "inputs": {
            "question": query,
            # "session_id": session_id,
            # "domain": domain,
            "lan": "ID",
            # "sec-fetch-site": "same-origin",
            # "sec-fetch-mode": "cors",
            # "chat_temp_token": "eyJhbGciOiJIUzI1NiIsInppcCI6IkRFRiJ9.eNpEjMsOgjAQRf-la0ha6LTgWkOMxkeEhcu2jBEfpeERjcZ_d2TjrCbn3HvfrB8tmzF3NkOJ91C2V_QsYsF0g8duG9Ava_Jr2MFG71eLopgfNQWo4D3eqh67KZApkWcpl1JIJcjb5nVox84huQeN9yaE_27VUEdwzpVK-O_ozyKGz0BYg9ZagpYRa8wwARBZMoHL0NCgce7kRAKxMtbEUqQitoAuljJFa3JMawD2-QIAAP__.v9KsrJFHoaT-aIZPDQJHxB9iOlJey1icQvVKMGC6FVs"
        },
        "files": []
    }

    try:
        resp = requests.post(url, headers=headers, json=payload, stream=True)
        resp.raise_for_status()

        final_answer = None
        knowledge_retrieval = None
        question_classifier = None
        for line in resp.iter_lines():
            if line:
                decoded_line = line.decode('utf-8').strip()
                if decoded_line.startswith("data: "):
                    event_data = decoded_line[6:]  # 去掉 "data: "
                    print(event_data)
                    try:
                        event_json = json.loads(event_data)
                        if event_json.get("event") == 'node_finished':
                            final_answer = event_json.get("data", {}).get("outputs", {}).get("text")
                            # 获取检索到的知识库，process_guidance和general Qa知识库节点是知识库结果聚合：1753256233555；修车店是1753844464410
                            if event_json.get("data", {}).get("node_id") == '1753256233555':
                                knowledge_retrieval = event_json.get("data", {}).get("outputs", {}).get("output")
                                print("knowledge_retrieval in workflow: ", knowledge_retrieval)
                            elif event_json.get("data", {}).get("node_id") == '1753666462887':
                                knowledge_retrieval = event_json.get("data", {}).get("outputs", {}).get("result")
                                print("knowledge_retrieval in workflow: ", knowledge_retrieval)
                            # 获取意图分类结果，有两个节点
                            # 第一次意图识别，不带上下文，node id = 17553530659570
                            elif event_json.get("data", {}).get("node_id") == '17553530659570':
                                question_classifier = event_json.get("data", {}).get("outputs", {}).get("text")
                                print("RAG第一次意图识别结果: ", question_classifier)
                            # 第二次意图识别，带上下文，node id = 17553530659570
                            elif event_json.get("data", {}).get("node_id") == '1752731767860':
                                question_classifier = event_json.get("data", {}).get("outputs", {}).get("text")
                                print("RAG第二次意图识别结果: ", question_classifier)
                        elif event_json.get("event") == "message_end":
                            final_answer = event_json.get("metadata", {}).get("answer", final_answer)
                    except json.JSONDecodeError:
                        continue

        print("final_answer", final_answer)
        print("question_classifier", question_classifier)
        print("knowledge_retrieval", knowledge_retrieval)

        # 使用 json.dumps() 将字典转换为 JSON 格式的字符
        knowledge_retrieval = json.dumps(knowledge_retrieval)

        # if final_answer is not None and question_classifier is not None and knowledge_retrieval is not None:
        #     print("knowledge_retrieval："+knowledge_retrieval)
        #     return final_answer, question_classifier, knowledge_retrieval
        # else:
        #     print("No valid answer found in SSE stream.")
        #     return None

    except requests.RequestException as e:
        print(f"Error calling chat: {e}")
        if hasattr(e, 'response') and e.response:
            print(f"Response status: {e.response.status_code}")
            print(f"Response body: {e.response.text}")
        return None

    return final_answer, question_classifier, knowledge_retrieval


# 调用dify的smartfina_v2 chatflow

def chat_chatlow(base_url: str, app_id: str, userInfo: Dict[str, Any], query: str, access_token:str,) -> tuple[Any | None, Any | None, Any | None, Any | None, Any | None] | None:
    print("调用dify的smartfina_v2 chatflow")
    """
    对指定数据集做 hit-testing，返回接口完整 JSON。
    retrieval_model 留空时使用默认 hybrid_search 配置。
    """

    # https://rd-dify-sit.fuse.co.id/console/api/apps/f71f507b-da44-4d92-828b-6a37bf4d96a7/advanced-chat/workflows/draft/run
    # https://rd-dify-sit.fuse.co.id/console/api/apps/a1936725-1498-452c-8310-b81e94936703/workflows/draft/run
    url = f"{base_url.rstrip('/')}/api/apps/{app_id}/advanced-chat/workflows/draft/run"
    # access_token = login()
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                      "AppleWebKit/537.36 (KHTML, like Gecko) "
                      "Chrome/137.0.0.0 Safari/537.36",
        "authorization": f"Bearer {access_token}",
        # "authorization": f"Bearer logineyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiNTUyYmRiODktNTlkOC00NDExLWJiZmYtMjM3MGQwOWQ4MTljIiwiZXhwIjoxNzUzNzEwNDI0LCJpc3MiOiJTRUxGX0hPU1RFRCIsInN1YiI6IkNvbnNvbGUgQVBJIFBhc3Nwb3J0In0.uZAtxK0YEYiPyymg_g6ZDp7ckeRPRCbIw00TTj7rSD8",
        "content-type": "application/json",
    }

    if type(query) != str:
        query=str(query)
    # query="Do you have car product?"

    payload = {
            "files": [],
            "inputs": {
                "chat_temp_token": userInfo.get("chat_temp_token"),
                "partner_uid": userInfo.get("partner_uid"),
                "tenant_id": "1000662",
                "channel_user_id": userInfo.get("channel_user_id"),
                "channel_type": "whatsapp",
                "session_id": userInfo.get("session_id"),
                "lan": "ID"
            },
            "query": query
        }

    # 定义transation意图的枚举值列
    # transation = ['INTENT_QUICK_ORDER', 'INTENT_QUOTE_COMPARISON', 'INTENT_ORDER', 'INTENT_PAYMENT', 'INTENT_INVITE', 'INTENT_WITHDRAWAL', 'INTENT_COMPARISON_LIST', 'INTENT_QUOTATION']

    question_rephase = ""
    Level1_question_classifier = ""
    Level2_question_classifier = ""
    final_question_classifier = ""
    question_rewrite_before_llm_reply = ""
    llm_reply = ""
    chatFlow_final_output = ""




    try:
        resp = requests.post(url, headers=headers, json=payload, stream=True)
        resp.raise_for_status()


        for line in resp.iter_lines():
            if line:
                decoded_line = line.decode('utf-8').strip()
                if decoded_line.startswith("data: "):
                    event_data = decoded_line[6:]  # 去掉 "data: "
                    print(event_data)
                    try:
                        event_json = json.loads(event_data)
                        if event_json.get("event") == 'node_finished':
                            # 1. 意图识别和问题重写
                            if event_json.get("data", {}).get("node_id") == '17552427857160':    # LLM：意图识别与拆分重写
                                question_rephase = event_json.get("data", {}).get("outputs", {}).get("text")
                            # 2. 一级意图分类结果：T的细分类 / I
                            elif event_json.get("data", {}).get("node_id") == '1753082979250':    # 代码执行：意图识别结果ETL
                                Level1_question_classifier = event_json.get("data", {}).get("outputs", {}).get("inent_result")
                            # 3. I的二级意图分类结果：I的细分类
                            elif event_json.get("data", {}).get("node_id") == '1756308947332':    # 代码执行：解析I识别结果
                                Level2_question_classifier = event_json.get("data", {}).get("outputs", {}).get("intent_result")
                            # 4. 输出当前的意图识别结果
                            elif event_json.get("data", {}).get("node_id") == 'answer':    # 直接回复：当前意图识别RESULT
                                final_question_classifier = event_json.get("data", {}).get("outputs", {}).get("answer")
                            # 5. 输出问题重写结果（进入LLM回复前）
                            elif event_json.get("data", {}).get("node_id") == '1758099536484':  # 问题重写
                                question_rewrite_before_llm_reply = event_json.get("data", {}).get("outputs", {}).get("text")
                            # 6. 输出LLM回复结果（进入LLM回复后）
                            elif event_json.get("data", {}).get("node_id") == '1758094431616':    # LLM闲聊
                                llm_reply = event_json.get("data", {}).get("outputs", {}).get("text")
                            elif event_json.get("data", {}).get("node_id") == '1758276073214':    # 非Workshop
                                llm_reply = event_json.get("data", {}).get("outputs", {}).get("text")
                            elif event_json.get("data", {}).get("node_id") == '1758277040755':    # workshop
                                llm_reply = event_json.get("data", {}).get("outputs", {}).get("text")


                            elif event_json.get("data", {}).get("node_id") == '1758187502116':    # (LLM回复) SMARTFINA RAG - WORKFLOW - V2
                                llm_reply = event_json.get("data", {}).get("outputs", {}).get("text")


                        elif event_json.get("event") == 'workflow_finished':
                            # 记录开始时间和结束时间
                            start_time = event_json.get("data", {}).get("created_at")
                            end_time = event_json.get("data", {}).get("finished_at")
                            # 计算耗时
                            delta = datetime.fromtimestamp(end_time) - datetime.fromtimestamp(start_time)
                            # 转换成秒
                            duration_seconds = delta.total_seconds()

                            # 7. 输出chatFLow最后输出
                            chatFlow_final_output = event_json.get("data", {}).get("outputs", {})


                    except json.JSONDecodeError:
                        continue

        print("一级意图分类: ", Level1_question_classifier)
        # if Level1_question_classifier not in transation:
        #     #调用RAG workflow
        #     print("一级意图识别到是Information意图，调用RAG Flow")
        #     result = chat_workflow(query, access_token)
        #     if result is not None:
        #         final_answer, question_classifier, knowledge_retrieval = result
        #         print("RAG最终意图分类: ", question_classifier)
        #     else:
        #         question_classifier = None

        print("最后结果————————————————————————")
        print("输出LLM回复结果（进入LLM回复后）: ", llm_reply)
        print("输出chatFLow最后输出: ", chatFlow_final_output)
        print("输出chatFLow耗时: ", duration_seconds)



        # 截取最高分的知识
        # print("check knowledge_retrieval before json.loads: ", knowledge_retrieval)
        # # 如果knowledge_retrieval 不等于Null, 将knowledge_retrieval转换成列表
        # if knowledge_retrieval is not None and knowledge_retrieval != "":
        #     knowledge_retrieval_temp = json.loads(knowledge_retrieval)
        #     print("knowledge_retrieval_temp: ", knowledge_retrieval_temp)
        #     if knowledge_retrieval_temp and len(knowledge_retrieval_temp) > 0:
        #         #  获取列表第一条，最高分的知识
        #         knowledge_highestScore = knowledge_retrieval_temp[0]
        #         # 转换成字符串
        #         knowledge_highestScore = json.dumps(knowledge_highestScore)
        #         print("知识库最高分: ", knowledge_highestScore)
        #     else:
        #         knowledge_highestScore = "None"
        # else:
        #     knowledge_highestScore = "None"




        return llm_reply, chatFlow_final_output, duration_seconds



    except requests.RequestException as e:
        print(f"Error calling chat: {e}")
        if hasattr(e, 'response') and e.response:
            print(f"Response status: {e.response.status_code}")
            print(f"Response body: {e.response.text}")
        return None







