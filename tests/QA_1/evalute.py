import json
import os
import requests
from typing import Dict, Any, Optional
from multiprocessing import Pool


# -------------------- 登录 --------------------
def login(email: str,password: str,base_url: str = "http://localhost/console") -> str:
    """
    登录 Dify Console，返回 access_token。
    extra_login_fields 可额外传 remember_me/language 等字段。
    """
    url = f"{base_url.rstrip('/')}/api/login"
    payload = {
        "email": email,
        "password": password,
        "language": "zh-Hans",
        "remember_me": True
    }

    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                      "AppleWebKit/537.36 (KHTML, like Gecko) "
                      "Chrome/137.0.0.0 Safari/537.36",
        "content-type": "application/json",
    }

    resp = requests.post(url, headers=headers, json=payload)
    resp.raise_for_status()
    return resp.json()["data"]["access_token"]

def chat_dify(system: str, query: str):

    base_url = "https://rd-dify-sit.fuse.co.id/console"
    email = "aurielli@fuseinsurtech.com"
    password = "Wqxxqm@l3uXKEaR4"
    token = login(email, password, base_url=base_url)
    app_id = "5749f5da-9fc2-463d-b00e-9893cc290b9b"
    # https://rd-dify-sit.fuse.co.id/console/api/apps/5749f5da-9fc2-463d-b00e-9893cc290b9b/workflows/draft/run
    url = f"{base_url.rstrip('/')}/api/apps/{app_id}/workflows/draft/run"

    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                      "AppleWebKit/537.36 (KHTML, like Gecko) "
                      "Chrome/137.0.0.0 Safari/537.36",
        "authorization": f"Bearer {token}",
        "content-type": "application/json",
    }

    payload = {"inputs":{"user":query,"system":system},"files":[]}

    try:
        resp = requests.post(url, headers=headers, json=payload, stream=True)
        resp.raise_for_status()

        final_answer = None
        for line in resp.iter_lines():
            if line:
                decoded_line = line.decode('utf-8').strip()
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
            return None

    except requests.RequestException as e:
        print(f"Error calling chat: {e}")
        if hasattr(e, 'response') and e.response:
            print(f"Response status: {e.response.status_code}")
            print(f"Response body: {e.response.text}")
        return None




def chat(app_id: str,query: str,access_token: str,base_url: str = "http://localhost/console",) -> Optional[Dict[str, Any]]:
    """
    对指定数据集做 hit-testing，返回接口完整 JSON。
    retrieval_model 留空时使用默认 hybrid_search 配置。
    """
    # https://rd-dify-sit.fuse.co.id/console/api/apps/a1936725-1498-452c-8310-b81e94936703/workflows/draft/run
    url = f"{base_url.rstrip('/')}/api/apps/{app_id}/workflows/draft/run"

    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                      "AppleWebKit/537.36 (KHTML, like Gecko) "
                      "Chrome/137.0.0.0 Safari/537.36",
        "authorization": f"Bearer {access_token}",
        "content-type": "application/json",
    }
    if type(query) != str:
        query=str(query)
    # query="Do you have car product?"

    payload = {"inputs":{"question":query},"files":[]}


    try:
        resp = requests.post(url, headers=headers, json=payload, stream=True)
        resp.raise_for_status()

        final_answer = None
        for line in resp.iter_lines():
            if line:
                decoded_line = line.decode('utf-8').strip()
                if decoded_line.startswith("data: "):
                    event_data = decoded_line[6:]  # 去掉 "data: "
                    try:
                        event_json = json.loads(event_data)
                        if event_json.get("event") == 'node_finished':
                            final_answer = event_json.get("data", {}).get("outputs", {}).get("text")
                        elif event_json.get("event") == "message_end":
                            final_answer = event_json.get("metadata", {}).get("answer", final_answer)
                    except json.JSONDecodeError:
                        continue

        if final_answer is not None:
            return final_answer
        else:
            print("No valid answer found in SSE stream.")
            return None

    except requests.RequestException as e:
        print(f"Error calling chat: {e}")
        if hasattr(e, 'response') and e.response:
            print(f"Response status: {e.response.status_code}")
            print(f"Response body: {e.response.text}")
        return None






def process_single_file(args):
    name, boot_dir, source_dir, tarrget_dir, app_id, token, base_url, suffix, email, password = args
    score_list = []
    pre_name = name.split(".")[0]
    input_dir = os.path.join(boot_dir, source_dir)
    one_file_path = os.path.join(input_dir, name)

    with open(one_file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    for i, one in enumerate(data):
        print(f"开始处理文件：{name} 第{i}个", "=" * 100)
        question = one["question"]
        right_answer = one["answer"]

        if i % 10 == 0:
            token = login(email, password, base_url=base_url)

        llm_answer = chat(app_id, question, token, base_url=base_url)
        user_prompt = f"""
            你是一个专业的保险行业专家，负责严格评估AI客服系统的回答质量。请根据以下标准对模型回答进行1-10分的评分：

            评分标准及权重：
            1. 相关性（40%）：回答与用户问题和标准答案的关联程度（首要评分项）
            2. 准确性（30%）：回答内容是否准确无误
            3. 完整性（20%）：是否涵盖标准答案的关键信息点
            4. 清晰性（10%）：表达是否清晰易懂

            相关性分级标准（细化版）：
            - 完全相关(9-10分)：100%覆盖问题核心，与标准答案主题完全一致
            - 大部分相关(7-8分)：覆盖主要问题点(≥70%)，与标准答案基本一致
            - 部分相关(5-6分)：涉及部分问题点(30%-69%)，与标准答案有部分偏离
            - 小部分相关(3-4分)：仅涉及边缘问题点(<30%)，与标准答案明显偏离
            - 不相关(1-2分)：完全偏离问题和标准答案主题

            强制规则：
            1. 如判定为不相关(is_relevant=false)，overall_score不得超过2分
            2. 相关性评分必须严格参照分级标准执行

            评分说明：
            - 9-10分：完全相关且专业准确，信息完整清晰
            - 7-8分：大部分相关且基本准确，主要信息完整
            - 5-6分：部分相关或有少量错误，缺失重要信息
            - 3-4分：小部分相关或有多处错误，信息严重不全
            - 1-2分：完全不相关或完全错误

            用户问题：
            {question}

            标准参考答案：
            {right_answer}

            待评估的模型回答：
            {llm_answer}

            评估流程：
            1. 首先严格评估相关性等级
            2. 对比标准答案检查准确性和完整性
            3. 根据权重计算总分
            4. 应用强制规则调整

            请输出严格JSON格式结果：
            {{
                "overall_score": 6,
                "relevance_level": "部分相关",  // [完全相关|大部分相关|部分相关|小部分相关|不相关]
                "relevance_score": 5,
                "accuracy_score": 6,
                "completeness_score": 5,
                "clarity_score": 7,
                "question": "用户的问题",
                "detailed_feedback": "具体指出相关性和质量问题",
                "is_relevant": false,
                "missing_key_elements": ["标准答案关键点1", "关键点2"],
                "incorrect_elements": ["错误描述1", "错误描述2"],
                "irrelevant_content": ["无关内容1", "无关内容2"],
                "relevance_analysis": "详细说明相关性判定依据"
            }}

            特别注意：
            1. 必须首先明确relevance_level和is_relevant
            2. 不相关时总分强制≤2分
            3. 所有评分项必须与relevance_level逻辑一致
            4. 不得包含非JSON内容
            """
        system_message = "你是语意判断专家"
        r = chat_dify(system_message, user_prompt)
        print(f"问题：{question}")
        print(f"正确答案：{right_answer}")
        print(f"答案：{llm_answer}")
        print(f"结果：{r}")
        if r:
            score_list.append(r)

    output_path = os.path.join(boot_dir, tarrget_dir, f"{pre_name}_{suffix}.json")
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(score_list, f, ensure_ascii=False, indent=4)


def llm_evaluate(boot_dir: str, source_dir: str, tarrget_dir: str, app_id: str, token: str,
                 base_url: str, suffix: str, email: str, password: str, num_processes: int = 4):
    input_dir = os.path.join(boot_dir, source_dir)
    file_names = [f for f in os.listdir(input_dir) if f.endswith('.json')]

    # 准备多进程参数
    args_list = [(name, boot_dir, source_dir, tarrget_dir, app_id, token, base_url, suffix, email, password)
                 for name in file_names if name not in ["ETIQA CAR.json"]]

    # 使用多进程池处理文件
    with Pool(processes=num_processes) as pool:
        pool.map(process_single_file, args_list)

def turn_json(dir_path:str,source_dir:str,suffix:str):
    file_path = os.path.join(dir_path, source_dir)
    file_name = [f for f in os.listdir(file_path) if f.endswith(f'_{suffix}.json')]
    for name in file_name:
        # if name in ["AUTOPRO CAR_score.json"]:
        #     continue
        one_file_path = os.path.join(file_path, name)
        with open(one_file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        right_json = []
        for i,one in enumerate(data):
            # json化
            try:
                if one and type(one) == str:
                    one = json.loads(one)
                right_json.append(one)
            except Exception as e:
                print(f"文件：{name} 第{i}个错误：{e}")
                system_message ="你是json专家,用户输入的内容无法json化,请修改输出正确json，不要输出其他内容"
                r = chat_dify(system_message,one)
                try:
                    r=json.loads(r)
                    right_json.append(r)
                except Exception as e:
                    print(f"文件：{name} 第{i}个错误：{e}")
                    system_message =  f"你是json专家,用户输入的内容无法json化，报错{e},请修改输出正确json，不要输出其他内容"
                    r = chat_dify(system_message,one)
                    try:
                        r=json.loads(r)
                        right_json.append( r)
                    except Exception as e:
                        raise
                        print(f"json化错误{e}")

        with open(one_file_path, 'w', encoding='utf-8') as f:
            json.dump(right_json, f, ensure_ascii=False, indent=4)

def summary_qa_score(dir_path:str,source_dir:str,suffix: str):
    fi = dir_path.split("/")[-1]
    file_path = os.path.join(dir_path, source_dir)
    file_name = [f for f in os.listdir(file_path) if f.endswith(f'_{suffix}.json')]
    score_1 = 0
    score_2 = 0
    score_3 = 0
    score_4 = 0
    score_5 = 0
    score_6 = 0
    score_7 = 0
    score_8 = 0
    score_9 = 0
    score_10 = 0
    score_error = 0
    cout =0
    for name in file_name:
        one_file_path = os.path.join(file_path, name)
        with open(one_file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        cout += len(data)
        for i,one in enumerate(data):

            score = one["overall_score"]
            if score == 1:
                score_1 += 1
            elif score == 2:
                score_2 += 1
            elif score == 3:
                score_3 += 1
            elif score == 4:
                score_4 += 1
            elif score == 5:
                score_5 += 1
            elif score == 6:
                score_6 += 1
            elif score == 7:
                score_7 += 1
            elif score == 8:
                score_8 += 1
            elif score == 9:
                score_9 += 1
            elif score == 10:
                score_10 += 1
            else:
                score_error += 1

    print(f"{fi}一共有{cout}问答  1:{score_1}  2:{score_2}  3:{score_3}  4:{score_4}  5:{score_5}  6:{score_6}  7:{score_7}  8:{score_8}  9:{score_9}  10:{score_10}  error(不在1-10内的):{score_error}")
    print(f"7分以上的占有率：{(score_10+score_9+score_8+score_7)/cout}  8分以上的占有率：{(score_10+score_9+score_8)/cout}  9分以上的占有率：{(score_10+score_9)/cout}   10分以上的占有率：{score_10/cout}")
    # 平均分
    score_sum = score_10*10 + score_9*9 + score_8*8 + score_7*7 + score_6*6 + score_5*5 + score_4*4 + score_3*3 + score_2*2 + score_1*1
    print(f"平均分：{score_sum/cout}")

# ==================== 使用示例 ====================
if __name__ == "__main__":

    base_url = "https://rd-dify-sit.fuse.co.id/console"
    email = "nora.cai@fuse.co.id"
    password = "Csb2337763269."


    # 1. 单独调用
    token = login(email, password,base_url=base_url)
    # print( token)
    # 大模型评测两答案间相似得分
    # 知识库+大模型的测试
    app_id = "a1936725-1498-452c-8310-b81e94936703"  # sit

    source_dir="test"
    target_dir="result"
    suffix_ev ="score"
    boot_dir="./FAQ"
    detail = """评分说明：
                        - 9-10分：完全相关且专业准确，信息完整清晰
                        - 7-8分：大部分相关且基本准确，主要信息完整
                        - 5-6分：部分相关或有少量错误，缺失重要信息
                        - 3-4分：小部分相关或有多处错误，信息严重不全
                        - 1-2分：完全不相关或完全错误
                """


    # 打印两答案间相似得分
    print(detail)

    # 利用大模型转换成json
    turn_json(boot_dir, target_dir, suffix_ev)
    # 总结并打印
    summary_qa_score(boot_dir, target_dir, suffix_ev)

