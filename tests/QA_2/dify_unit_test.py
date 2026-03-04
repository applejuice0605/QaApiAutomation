import pandas as pd
import requests
import time
import re
import json

# 配置 Dify 接口参数
url = "https://rd-dify-sit.fuse.co.id/v1/chat-messages" # sit - Dify服务的API端点URL
token = "app-IbL9bdgvDiKtZAkWSlj4XXN9" # sit - 访问Dify API的认证令牌
user = "stark_unit_test"  # 用户标识符，用于追踪会话
conversation_id = ""  # 会话ID，空字符串表示新会话
inputs = {
  "session_id": "SN00OM5IWRQ000000001I",  # 会话相关的输入参数
}

def extract_answer(answer_raw):
    """
    从Dify返回的原始答案中提取final_intents字段
    
    Args:
        answer_raw (str): Dify返回的原始答案字符串
        
    Returns:
        str: 提取的意图列表，以逗号分隔的字符串形式返回
    """
    # 去掉 markdown 包裹
    if answer_raw.startswith("```json"):
        answer_raw = answer_raw.replace("```json", "").replace("```", "").strip()
    try:
        answer_json = json.loads(answer_raw)
        # 提取 final_intents 字段（是一个列表）
        final_intents = answer_json.get("final_intents", [])
        # 返回为字符串
        return ",".join(final_intents)
    except Exception as e:
        print("解析answer_raw失败:", e)
        return ""

def get_answer(question):
    """
    向Dify API发送问题并获取答案
    
    Args:
        question (str): 要发送给Dify的问题
        
    Returns:
        str: 解析后的答案或错误信息
    """
    # 构造请求体
    body = {
        "inputs": inputs,
        "query": question,
        "response_mode": "blocking",  # 阻塞模式，等待完整响应
        "conversation_id": conversation_id,
        "user": user
    }
    # 设置请求头
    headers = {
        "Authorization": f"Bearer {token}",  # 使用Bearer Token认证
        "Content-Type": "application/json"
    }
    try:
        # 发送POST请求到Dify API
        resp = requests.post(url, json=body, headers=headers, timeout=30)
        resp.raise_for_status()  # 检查HTTP错误
        data = resp.json()
        print("[Res]: ", data)
        # 提取 ragAnswer 字段
        answer_raw = data.get("answer") or data.get("output") or str(data)
        extract_result = extract_answer(answer_raw)
        print("Extracted answer: ", extract_result)
        return extract_result
    except Exception as e:
        return f"Error: {e}"

def process_csv(file_path):
    """
    处理CSV文件中的问题列表，向Dify发送每个问题并保存答案
    
    Args:
        file_path (str): 包含问题的CSV文件路径
    """
    # 读取CSV文件
    df = pd.read_csv(file_path)
    answers = []
    count = 0
    question_done = 0
    
    # 遍历每个问题
    for question in df['Question']:
        if pd.isna(question):
            answers.append("")
            continue
            
        # 获取问题答案
        answer = get_answer(question)
        answers.append(answer)
        count += 1
        question_done += 1
        print("当前进度：",question_done)
        
        # 每处理10个问题后重置会话并初始化新会话
        if count % 10 == 0:
            print("执行 resetSession ...")
            resetSession(question)
            print("执行 send_whatsapp_webhook 初始化新会话...")
            send_whatsapp_webhook()
        # time.sleep(1)  # 防止接口限流
    
    # 将答案添加到DataFrame并保存到CSV文件
    df['Answer'] = answers
    df.to_csv(file_path, index=False)
    print("处理完成，答案已写入CSV文件。")

if __name__ == "__main__":
    """
    主函数：执行CSV文件处理流程并计时
    """
    start_time = time.time()
    csv_file = "/Users/starkzheng/Documents/data_space/work/fuse/dify/python/question_examples.csv"
    process_csv(csv_file)
    end_time = time.time()
    print(f"总耗时: {end_time - start_time:.2f} 秒")