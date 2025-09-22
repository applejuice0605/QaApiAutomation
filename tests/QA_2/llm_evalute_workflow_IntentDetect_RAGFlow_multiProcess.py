'''
    调用dify chatflow获取一级意图识别结果和inforamtion侧二级意图识别结果
    1. 建议：
     运行前reset, 然后获取到新的session_id，填写到下面的字段


'''
import datetime
import os
import re
import time
from multiprocessing import Pool
from typing import Dict, Any, Optional, Tuple
import pandas as pd
import requests
import json
from openpyxl import load_workbook
from openpyxl.styles import Alignment
from openpyxl.utils import get_column_letter
from config import *
from fileProcess import FileProcess
from tests.QA_2.util.llmEvaHandler import evalsite_answer_withStandAns
from tests.QA_2.llm_evalute_WebHook import evalsite_answer
from tests.QA_2.util.httpUtil import chat_chatlow
from tests.QA_2.util.llmEvaHandler import evalsite_answer_withStandAns



env = 'sit'
base_url = sit_base_url
email = sit_email
password =sit_password
workflow_app_id = sit_workflow_app_id
llm_app_id = sit_llm_app_id
chat_flow_id = sit_sf_v2
session_id = 'SN00OQUB02Z0000000041'
domain = prod_domain
user_info = sit_user_info

# 登录函数获取token
def login() -> str:
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


def multi_process(boot_dir: str, question_dir: str, answer_dir: str, num_processes: int = 2):
    print("开始多线程")
    input_dir = os.path.join(boot_dir, question_dir)
    print(input_dir)
    file_names = [f for f in os.listdir(input_dir) if f.endswith('.xlsx')]
    print(file_names)
    # 准备多进程参数
    # boot_dir, question_dir, answer_dir, fileName = args
    args_list = [(boot_dir, question_dir, answer_dir, fileName)
                 for fileName in file_names
                 # if name not in ["ETIQA CAR.json"]
                 ]
    print("处理文件")
    # 使用多进程池处理文件
    print(num_processes)
    print(args_list)
    with Pool(processes=num_processes) as pool:
        print("开始多进程")
        try:
            pool.map(process_single_file, args_list)
        except Exception as e:
            print(f"Error occurred: {e}")

# 主处理流程
def process_single_file(args):
    print("process_single_file")
    boot_dir, question_dir, answer_dir, fileName = args

    input_dir = os.path.join(boot_dir, question_dir)
    output_dir = os.path.join(boot_dir, answer_dir)

    input_file = os.path.join(input_dir, fileName)
    output_file = os.path.join(output_dir, fileName)

    # 读取文件
    df = FileProcess.real_excel(input_file)


    # 处理每个问题
    index_start = 0

    round = 15
    for index, row in df.iloc[index_start:].iterrows():
        # 每16轮重新获取token
        if round % 16 == 15:
            token = login()

        round += 1

        # 获取当前行问题
        question = str(row['问题']).strip()
        # 获取当前行标准答案，暂时没有多轮对话给标答的情况不拆分
        standard_answer = str(row['标准答案'])

        if not question or question.lower() == 'nan' or question == '' or question == '-':
            continue

        print(f"\n处理问题 {index + 1}/{len(df)}: {question}")
        knowledge_highestScore = None

        # 2. 调用chatflow处理问题
        # 2.1 分解这个问题的每个步骤
        steps = [q for q in re.split(r'\d+\.', question) if q]
        print("全部步骤：", steps)

        output_answer = ''
        output_question_rephase= ''
        output_level1_question_classifier = ''
        output_knowledge_retrieval = ''
        output_question_classifier = ''
        output_evalsition = ''
        output_knowledge_highestScore = ''
        output_chatflow_final_output = ''
        output_duration_seconds = ''

        # 2.2 逐个步骤调用chatFlow / workflow
        for step_index in range(0, len(steps)):
            answer, chatFlow_final_output, duration_seconds = '', '', ''

            step_question = str(steps[step_index]).strip()
            print(f"处理步骤{step_index+1}/{steps.__len__()}: {step_question}")

            # 调用chatFlow
            result = chat_chatlow(base_url=base_url, app_id=chat_flow_id, userInfo=user_info, query=step_question, access_token=token)


            # if result is not No
            if result is not None:
                answer, chatFlow_final_output, duration_seconds = result
            else:
                # 处理 None 的情况，例如抛出异常或返回默认值
                print("chat_chatlow 返回了 None")
                answer, chatFlow_final_output, duration_seconds = ''
                continue

            # 如果answer = 空
            if answer == None:
                answer = ''
            if chatFlow_final_output == None:
                chatFlow_final_output = ''
            if duration_seconds == None:
                duration_seconds = 0


            # 评估答案 def evalsite_answer_withStandAns(base_url: str, app_id: str, question: str, llm_answer: str, token: str, right_answer: str)
            evalsition = evalsite_answer_withStandAns(base_url=base_url, app_id=llm_app_id, token=token, question=step_question, llm_answer=answer, right_answer=standard_answer)
            if not evalsition:
                print(f"评估答案失败，跳过问题: {question}")
                continue
            print(f"评测结果: {evalsition}")
            print("=" * 200)

            # 保存答案
            # 答案
            output_answer += f"{step_index+1}. " + answer + '\n'
            # chatflow最终输出
            output_chatflow_final_output += f"{step_index+1}. " + json.dumps(chatFlow_final_output) + '\n'
            # chatflow耗时
            output_duration_seconds += f"{step_index+1}. " + str(duration_seconds) + '\n'
            # output_evalsition += f"{step_index+1}. " + evalsition + '\n'
            # 评测结果
            output_evalsition += f"{step_index+1}. " + evalsition + '\n'


        # 更新DataFrame
        df.at[index, '答案'] = output_answer
        df.at[index, 'chatflow最终输出'] = output_chatflow_final_output
        df.at[index, 'chatflow耗时'] = output_duration_seconds
        df.at[index, '评估结果'] = output_evalsition
        print("="*200)

        # 每处理3条保存一次进度
        FileProcess.save_result_temp(index=index, df=df, output_file=output_file)

        # 最终保存结果
    FileProcess.write_to_excel(df, output_file)

# 使用示例
if __name__ == "__main__":

    # 打印开始执行的时间
    start_time = time.time()
    # input_excel = "question-workshop.xlsx"  # 输入文件名
    # output_excel = "output-workshop-0805.xlsx"  # 输出文件名
    # input_excel = "question-orginalRM.xlsx"  # 输入文件名
    # output_excel = "output_orginalRM_0806.xlsx"  # 输出文件名
    # input_excel = "Jess_SIT_IntentDetect.xlsx"  # 输入文件名
    # output_excel = "A_Jess_SIT_IntentDetect.xlsx"  # 输出文件名
    input_excel = "Q_related-FUSE_FINA.xlsx"  # 输入文件名
    output_excel = "A_related-FUSE_FINA_0917_sit.xlsx"  # 输出文件名
    # input_excel = "Q_Unsupported_producat_category.xlsx"  # 输入文件名
    # output_excel = "A_Unsupported_producat_category.xlsx"  # 输出文件名
    # input_excel = "Q_0901Fina Day Feedback.xlsx"  # 输入文件名
    # output_excel = "A_0901Fina Day Feedback_0903_2.xlsx"  # 输出文件名
    # input_excel = "Q_FinamustA_Failcase.xlsx"  # 输入文件名
    # output_excel = "A_FinamustA_Failcase_0829.xlsx"  # 输出文件名
    # input_excel = "fina day 意图识别case.xlsx"  # 输入文件名
    # output_excel = "A_fina day 意图识别case.xlsx"  # 输出文件名
    # input_excel = "sample意图测试.xlsx"  # 输入文件名
    # output_excel = "A_sample意图测试_0915_uat.xlsx"  # 输出文件名
    # input_excel = "Q_Claim_condition.xlsx"  # 输入文件名
    # output_excel = "A_Claim_condition.xlsx"  # 输出文件名
    # input_excel = "Q_0901Fina Day Feedback.xlsx"  # 输入文件名
    # process_excel(input_excel, output_excel)

    source_dir = "test"
    target_dir = "result"
    suffix_ev = "score"
    boot_dir = ".\FAQ"
    multi_process(boot_dir=boot_dir, question_dir='Question', answer_dir='Answer')
    # 打印结束时间
    end_time = time.time()
    print("开始执行时间：", time.strftime("%Y-%m-%d %H:%M:%S", time.localtime(start_time)))
    print("结束执行时间：", time.strftime("%Y-%m-%d %H:%M:%S", time.localtime(end_time)))
    print(f"总耗时: {end_time - start_time:.2f} 秒")

