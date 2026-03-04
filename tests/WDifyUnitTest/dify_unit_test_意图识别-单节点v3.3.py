import pandas as pd
import requests
import time
import json
import logging
import glob
from concurrent.futures import ThreadPoolExecutor, as_completed
import threading
import chardet

# 配置日志（指定编码为utf-8）
# logging.basicConfig(
#     level=logging.INFO,
#     format='%(asctime)s - %(levelname)s - %(message)s',
#     handlers=[
#         logging.FileHandler("process.log", encoding='utf-8'),
#         logging.StreamHandler()
#     ]
# )

# 配置API参数
url = "https://rd-dify-sit.fuse.co.id/v1/chat-messages"
token = "app-IbL9bdgvDiKtZAkWSlj4XXN9"
# token = "app-y9y1NCXH1hoZV1heFctfIzd7"
user = "shirley_wu_unitTest"
conversation_id = ""
inputs = {}

# 线程锁和限流器
file_lock = threading.Lock()


class RateLimiter:
    """请求频率控制器，确保单位时间内不超过最大请求数"""

    def __init__(self, max_requests, period=1):
        self.max_requests = max_requests  # 周期内最大请求数
        self.period = period  # 时间周期（秒）
        self.requests = []
        self.lock = threading.Lock()

    def acquire(self):
        with self.lock:
            now = time.time()
            # 清除过期的请求记录
            self.requests = [t for t in self.requests if now - t < self.period]

            # 如果超过限制，计算需要等待的时间
            if len(self.requests) >= self.max_requests:
                sleep_time = self.period - (now - self.requests[0])
                if sleep_time > 0:
                    time.sleep(sleep_time)
                    # 再次清理过期记录
                    now = time.time()
                    self.requests = [t for t in self.requests if now - t < self.period]

            # 记录当前请求时间
            self.requests.append(time.time())


# 初始化限流器：每秒最多5个请求（可调整）
rate_limiter = RateLimiter(max_requests=5, period=1)


def extract_answer(answer_raw):
    """提取final_intents（原有功能）"""
    try:
        if answer_raw.startswith("```json"):
            answer_raw = answer_raw.replace("```json", "").replace("```", "").strip()
        answer_json = json.loads(answer_raw)
        return ",".join(answer_json.get("final_intents", [])), answer_json  # 额外返回完整JSON对象
    except Exception as e:
        logging.error(f"提取答案失败: {e}")
        return "", None


def extract_answer_raw(answer_raw):
    """提取原始JSON字符串（原有功能）"""
    try:
        if answer_raw.startswith("```json"):
            answer_raw = answer_raw.replace("```json", "").replace("```", "").strip()
        return answer_raw
    except Exception as e:
        logging.error(f"提取原始JSON失败: {e}")
        return ""


def get_answer(question):
    """调用API获取答案，新增JSON解析准备（核心修改点）"""
    try:
        # 请求前先通过限流器控制频率
        rate_limiter.acquire()

        body = {
            "inputs": inputs,
            "query": question,
            "response_mode": "blocking",
            "conversation_id": conversation_id,
            "user": user
        }
        headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json"
        }
        resp = requests.post(url, json=body, headers=headers, timeout=60)
        resp.raise_for_status()
        data = resp.json()
        answer_raw = data.get("answer") or data.get("output") or str(data)

        # 调用提取函数，同时获取final_intents和完整JSON对象
        final_intents, answer_json_obj = extract_answer(answer_raw)
        # 提取原始JSON字符串
        raw_json_str = extract_answer_raw(answer_raw)

        # 提取need_clarification和explanation.clarification_need（核心新增逻辑）
        need_clarify = False
        clarify_need_desc = ""
        if answer_json_obj:
            # 提取顶层need_clarification字段
            need_clarify = answer_json_obj.get("need_clarification", False)
            # 提取explanation下的clarification_need字段（处理嵌套）
            explanation = answer_json_obj.get("explanation", {})
            clarify_need_desc = explanation.get("clarification_need", "")

        # 返回4个结果：final_intents、原始JSON字符串、need_clarification、clarification_need描述
        return final_intents, raw_json_str, need_clarify, clarify_need_desc
    except Exception as e:
        logging.error(f"API请求失败: {e}")
        return f"Error: {str(e)}", "", False, f"API请求失败: {str(e)}"


def save_temporary_results(df, answers, answer_raws, need_clarifies, clarify_needs, batch_num):
    """保存临时结果，新增2个目标字段（核心修改点）"""
    with file_lock:
        # 确保所有结果列表长度与DataFrame匹配
        len_df = len(df)
        adjusted_answers = answers[:len_df] + [""] * max(0, len_df - len(answers))
        adjusted_raws = answer_raws[:len_df] + [""] * max(0, len_df - len(answer_raws))
        adjusted_need_clarifies = need_clarifies[:len_df] + [False] * max(0, len_df - len(need_clarifies))
        adjusted_clarify_needs = clarify_needs[:len_df] + [""] * max(0, len_df - len(clarify_needs))

        # 复制原始DataFrame，更新所有字段（含新增的2个目标字段）
        temp_df = df.copy()
        temp_df['Answer'] = adjusted_answers
        temp_df['Answer_json'] = adjusted_raws
        temp_df['need_clarification'] = adjusted_need_clarifies  # 新增字段1
        temp_df['explanation.clarification_need'] = adjusted_clarify_needs  # 新增字段2

        temp_file = f"temp_results_batch_{batch_num}.csv"
        temp_df.to_csv(temp_file, index=False, encoding='utf-8-sig')
        logging.info(f"已暂存第{batch_num}批结果到{temp_file}（含need_clarification和clarification_need字段）")


def process_single_question(idx, question, answers, answer_raws, need_clarifies, clarify_needs, total_questions):
    """处理单个问题，新增2个结果列表（核心修改点）"""
    try:
        if pd.isna(question) or str(question).strip() == "":
            answers[idx] = ""
            answer_raws[idx] = ""
            need_clarifies[idx] = False
            clarify_needs[idx] = "问题为空，跳过处理"
            logging.info(f"问题{idx + 1}/{total_questions}为空，跳过")
            return idx, True

        logging.info(f"处理问题{idx + 1}/{total_questions}: {str(question)[:50]}...")
        # 接收4个返回值（含新增的2个目标字段）
        answer, answer_raw, need_clarify, clarify_need = get_answer(question)
        answers[idx] = answer
        answer_raws[idx] = answer_raw
        need_clarifies[idx] = need_clarify  # 赋值目标字段1
        clarify_needs[idx] = clarify_need  # 赋值目标字段2

        print(f"{idx + 1} 个意图是：{answer} | 需要澄清：{need_clarify}")
        return idx, True
    except Exception as e:
        logging.error(f"处理问题{idx + 1}时出错: {e}")
        answers[idx] = f"处理出错: {str(e)}"
        answer_raws[idx] = ""
        need_clarifies[idx] = False
        clarify_needs[idx] = f"处理出错: {str(e)}"
        return idx, False


def process_csv(file_path, start_id=20, end_id=None, max_workers=5):
    """主处理函数，初始化新增的结果列表（核心修改点）"""
    # 读取CSV并校验必需列
    # df = pd.read_csv(file_path, encoding='utf-8-sig')
    df = pd.read_csv(file_path, encoding='gbk')
    required_columns = ['Question', 'Target Intent ID']
    missing_cols = [col for col in required_columns if col not in df.columns]
    if missing_cols:
        raise ValueError(f"CSV文件缺少必需列: {', '.join(missing_cols)}")

    total_questions = len(df)
    logging.info(f"CSV文件共包含{total_questions}个问题（已确认包含Question和Target Intent ID列）")

    # 处理索引边界
    if end_id is None:
        end_id = total_questions
    else:
        end_id = min(end_id, total_questions)
    start_id = max(0, start_id)
    if start_id >= end_id:
        logging.warning(f"开始索引{start_id}大于等于结束索引{end_id}，无需处理")
        return
    logging.info(f"处理范围：从ID={start_id}到ID={end_id - 1}（共{end_id - start_id}个问题）")

    # 初始化结果列表（新增2个目标字段的列表）
    answers = [""] * total_questions
    answer_raws = [""] * total_questions
    need_clarifies = [False] * total_questions  # 新增：存储need_clarification
    clarify_needs = [""] * total_questions  # 新增：存储explanation.clarification_need

    # 尝试从临时文件恢复进度（含新增字段）
    if start_id == 0:
        temp_files = glob.glob("temp_results_batch_*.csv")
        if temp_files:
            latest_temp = max(temp_files, key=lambda x: int(x.split("_")[-1].split(".")[0]))
            try:
                temp_df = pd.read_csv(latest_temp, encoding='utf-8-sig')
                # 恢复原有字段
                if 'Answer' in temp_df.columns:
                    answers = temp_df['Answer'].fillna("").tolist()[:total_questions]
                if 'Answer_json' in temp_df.columns:
                    answer_raws = temp_df['Answer_json'].fillna("").tolist()[:total_questions]
                # 恢复新增字段
                if 'need_clarification' in temp_df.columns:
                    need_clarifies = temp_df['need_clarification'].fillna(False).tolist()[:total_questions]
                if 'explanation.clarification_need' in temp_df.columns:
                    clarify_needs = temp_df['explanation.clarification_need'].fillna("").tolist()[:total_questions]
                logging.info(f"从{latest_temp}恢复进度（含新增的2个澄清相关字段）")
            except Exception as e:
                logging.warning(f"恢复临时文件失败: {e}，将从指定ID开始")

    # 确定需要处理的索引范围
    process_indices = list(range(start_id, end_id))
    total_to_process = len(process_indices)
    logging.info(f"实际需要处理的问题数量: {total_to_process}")

    # 多线程处理（传入新增的2个结果列表）
    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        futures = {
            executor.submit(
                process_single_question,
                idx,
                df.iloc[idx]['Question'],
                answers,
                answer_raws,
                need_clarifies,  # 传入新增列表1
                clarify_needs,  # 传入新增列表2
                total_questions
            ): idx for idx in process_indices
        }

        completed = 0
        batch_num = 1
        batch_size = 15  # 每15个问题保存一次临时结果

        for future in as_completed(futures):
            idx = futures[future]
            try:
                result_idx, success = future.result()
                completed += 1
                # 按批次保存（含新增字段）
                if completed % batch_size == 0 or completed == total_to_process:
                    save_temporary_results(
                        df, answers, answer_raws, need_clarifies, clarify_needs, batch_num
                    )
                    batch_num += 1
            except Exception as e:
                logging.error(f"线程处理问题{idx}时发生异常: {e}")

    # 最终保存结果到原文件（含所有字段）
    with file_lock:
        final_df = df.copy()
        final_df['Answer'] = answers
        final_df['Answer_json'] = answer_raws
        final_df['need_clarification'] = need_clarifies  # 写入目标字段1
        final_df['explanation.clarification_need'] = clarify_needs  # 写入目标字段2
        final_df.to_csv(file_path, index=False, encoding='utf-8-sig')
        logging.info(f"处理完成！已保存ID={start_id}到ID={end_id - 1}的结果（含2个澄清相关字段）")


if __name__ == "__main__":
    start_time = time.time()
    try:
        process_csv(
            file_path="长尾意图+多意图_千问.csv",  # 输入输出文件（需包含Question和Target Intent ID列）
            # file_path="长尾意图+多意图_Gemini.csv",  # 输入输出文件（需包含Question和Target Intent ID列）
            start_id=0,
            end_id=None,
            max_workers=5
        )
    except ValueError as ve:
        logging.error(f"执行失败: {ve}")
    except Exception as e:
        logging.error(f"执行过程中发生未知错误: {e}")
    finally:
        print(f"总耗时: {time.time() - start_time:.2f}秒")