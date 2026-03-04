import pandas as pd
import requests
import json
from typing import Dict, Any, List
from concurrent.futures import ThreadPoolExecutor, as_completed
import time
import os

# --- 配置区：请根据您的实际情况修改以下占位符 ---
# 0. 模式切换开关
USE_MULTI_THREADING = True # 设置为 True 使用多线程，设置为 False 使用单线程串行处理

# 1. Excel 文件路径
EXCEL_FILE_PATH = 'upload_results.xlsx'
OSS_LINK_COLUMN_NAME = 'OSS_Link'

# 2. dify相关配置
DIFY_ENDPOINT = 'https://rd-dify-sit.fuse.co.id/console/api/apps/'
dify_token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiNTUyYmRiODktNTlkOC00NDExLWJiZmYtMjM3MGQwOWQ4MTljIiwiZXhwIjoxNzY0MjI1NDA0LCJpc3MiOiJTRUxGX0hPU1RFRCIsInN1YiI6IkNvbnNvbGUgQVBJIFBhc3Nwb3J0In0.U9U6nF-TCaB5Z8_ZPZ6m29QxuITgpGZ_uZW79AG2LuE'
token = 'eyJhbGciOiJIUzI1NiIsInppcCI6IkRFRiJ9.eNpEjssOgjAQRf-la0impUzBNcZoNMYIidsBxoiP0vCIRuO_W9g4y3PuvZmP6MdSLER1oSHnh8vbG1sRCEfdYLnbO7br2vttojenw8rsskwvMx_wBWv5XvTczYEEZawig4AmUt6XzfvYjl3F3j39eE_O_XeLxnckACAqmE6mCIHgl_PYoE5TDYkKREPDDJQGNYPr0EzfKmZZpxQmxBRqMBRShFFYEZakYqZzLMX3BwAA__8.p0rddGkvM_t3ck7y9uLbnMCYxlmKsEOihBrSEQsil1o'
# 2.1 Dify 图片识别 API 配置 (用于获取图片结果)
DIFY_RECOGNITION_WORKFLOWID = '4b8e5838-a063-4dbe-97d3-d94355788e28'
# 2.2. Dify 对比 API 配置 (新增，用于对比结果)
DIFY_COMPARE_API_WORKFLOWID = '435da493-4aa2-419d-a0b0-858c48e1fb95' 

# 3. 多线程配置
MAX_WORKERS = 5

# 4. 配置对比的文件类型
file_type = 'stnk'

# 5. 配置处理的开始和结束Index
START_INDEX = 57
END_INDEX = None # 设置为 None 则处理到文件末尾


def call_dify_workflow(oss_link: str) -> Dict[str, Any]:
    """
    调用 Dify 图片识别 Workflow。
    """
    print("调用 Dify 图片识别 Workflow")
    payload = {
        "inputs": {
            "ocr_file_info": "{\"fileKey\": \"fuse-th-uat-rw_images/20251126/0d1122e7300b49aeb9f8258d1fbb1ef9.jpeg\", \"fileName\": \"chat_doc_1334447711281114.jpeg\", \"fileType\": \"jpeg\", \"fileUrl\": \"https://oss-uat.fuse.co.th/images/20251126/0d1122e7300b49aeb9f8258d1fbb1ef9.jpeg?Expires=1764201599&OSSAccessKeyId=LTAI5tQNDDRniBsyvGY8CLmW&Signature=oNCy4pAkTDGwk7rZ%2BcFpUewW9pE%3D\"}",
            "type": file_type,
            "country": "id",
            "token": "eyJhbGciOiJIUzI1NiIsInppcCI6IkRFRiJ9.eNpEjssOgjAQRf-la0impUzBNcZoNMYIidsBxoiP0vCIRuO_W9g4y3PuvZmP6MdSLER1oSHnh8vbG1sRCEfdYLnbO7br2vttojenw8rsskwvMx_wBWv5XvTczYEEZawig4AmUt6XzfvYjl3F3j39eE_O_XeLxnckACAqmE6mCIHgl_PYoE5TDYkKREPDDJQGNYPr0EzfKmZZpxQmxBRqMBRShFFYEZakYqZzLMX3BwAA__8.p0rddGkvM_t3ck7y9uLbnMCYxlmKsEOihBrSEQsil1o",
            "bizCode": "INTENT_QUICK_ORDER_1993555933615611906",
            "result": file_type,
            "tenantId": "1000662",
            "domain": "https://pchat-sit.fuse.co.id/api",
            "file": [
                {
                    "dify_model_identity": "__dify__file__",
                    "id": None,
                    "tenant_id": "d6adf5e1-c3de-49bc-8260-87165edf5771",
                    "type": "image",
                    "transfer_method": "remote_url",
                    "remote_url": oss_link,
                    "related_id": None,
                    "filename": "0d1122e7300b49aeb9f8258d1fbb1ef9.jpeg",
                    "extension": ".jpg",
                    "mime_type": "image/jpeg",
                    "size": 161653,
                    "url": oss_link
                }
            ],
            "env": "",
            "llm_first": "",
            "input_file": [
                {
                    "dify_model_identity": "__dify__file__",
                    "id": None,
                    "tenant_id": "d6adf5e1-c3de-49bc-8260-87165edf5771",
                    "type": "image",
                    "transfer_method": "remote_url",
                    "remote_url": oss_link,
                    "related_id": None,
                    "filename": "0d1122e7300b49aeb9f8258d1fbb1ef9.jpeg",
                    "extension": ".jpg",
                    "mime_type": "image/jpeg",
                    "size": 161653,
                    "url": oss_link
                }
            ],
            "trace_id": "99afa802214c6e53",
            "sys.files": [],
            "sys.user_id": "L84JXQG7MDD4ED",
            "sys.app_id": "4b8e5838-a063-4dbe-97d3-d94355788e28",
            "sys.workflow_id": "b57c27a1-e8fc-4d08-97f1-4807b4c111a2",
            "sys.workflow_run_id": "165c5eb3-04d7-4bb8-a134-020332da81bf"
        }
    }
        
    headers = {
        'Authorization': f'Bearer {dify_token}',
        'Content-Type': 'application/json',
    }
    # https://rd-dify-sit.fuse.co.id/console/api/apps/4b8e5838-a063-4dbe-97d3-d94355788e28/workflows/draft/run
    request_url = f"{DIFY_ENDPOINT}{DIFY_RECOGNITION_WORKFLOWID}/workflows/draft/run"
    print(request_url)

    try:
        resp = requests.post(request_url, headers=headers, json=payload, stream=True)
        resp.raise_for_status()

        final_answer = None
        print(resp.text)
        for line in resp.iter_lines():
            if line:
                decoded_line = line.decode('utf-8').strip()
                if decoded_line.startswith("data: "):
                    event_data = decoded_line[6:]  # 去掉 "data: "
                    try:
                        event_json = json.loads(event_data)
                        if event_json.get("event") == "workflow_finished":
                            final_answer = event_json.get("data", {}).get("outputs", {}).get("result")
                        elif event_json.get("event") == "message_end":
                            final_answer = event_json.get("metadata", {}).get("text", final_answer)
                    except json.JSONDecodeError:
                        continue

        if final_answer is not None:
            print(f"LLM 返回结果: {final_answer}")
            return final_answer
        else:
            print("No valid answer found in SSE stream.")
            return None

    except requests.exceptions.RequestException as e:
        return {'error': f'Dify_Recognition_Request_Failed: {e}', 'link': oss_link}
    except Exception as e:
        return {'error': f'Dify_Recognition_Parsing_Failed: {e}', 'link': oss_link}

def call_third_party_api(oss_link: str) -> Dict[str, Any]:
    """
    调用 Dify 图片识别 Workflow，调用三方接口
    """
    print("调用 Dify 图片识别 Workflow，调用三方接口")
    payload = {
        "inputs": {
            "ocr_file_info": "{\"fileKey\": \"fuse-th-uat-rw_images/20251126/0d1122e7300b49aeb9f8258d1fbb1ef9.jpeg\", \"fileName\": \"chat_doc_1334447711281114.jpeg\", \"fileType\": \"jpeg\", \"fileUrl\": \"https://oss-uat.fuse.co.th/images/20251126/0d1122e7300b49aeb9f8258d1fbb1ef9.jpeg?Expires=1764201599&OSSAccessKeyId=LTAI5tQNDDRniBsyvGY8CLmW&Signature=oNCy4pAkTDGwk7rZ%2BcFpUewW9pE%3D\"}",
            "type": file_type,
            "country": "id",
            "token": "eyJhbGciOiJIUzI1NiIsInppcCI6IkRFRiJ9.eNpEjssOgjAQRf-la0impUzBNcZoNMYIidsBxoiP0vCIRuO_W9g4y3PuvZmP6MdSLER1oSHnh8vbG1sRCEfdYLnbO7br2vttojenw8rsskwvMx_wBWv5XvTczYEEZawig4AmUt6XzfvYjl3F3j39eE_O_XeLxnckACAqmE6mCIHgl_PYoE5TDYkKREPDDJQGNYPr0EzfKmZZpxQmxBRqMBRShFFYEZakYqZzLMX3BwAA__8.p0rddGkvM_t3ck7y9uLbnMCYxlmKsEOihBrSEQsil1o",
            "bizCode": "INTENT_QUICK_ORDER_1993555933615611906",
            "result": file_type,
            "tenantId": "1000662",
            "domain": "https://pchat-sit.fuse.co.id/api",
            "file": [
                {
                    "dify_model_identity": "__dify__file__",
                    "id": None,
                    "tenant_id": "d6adf5e1-c3de-49bc-8260-87165edf5771",
                    "type": "image",
                    "transfer_method": "remote_url",
                    "remote_url": oss_link,
                    "related_id": None,
                    "filename": "0d1122e7300b49aeb9f8258d1fbb1ef9.jpeg",
                    "extension": ".jpg",
                    "mime_type": "image/jpeg",
                    "size": 161653,
                    "url": oss_link
                }
            ],
            "env": "",
            "llm_first": "",
            "input_file": [
                {
                    "dify_model_identity": "__dify__file__",
                    "id": None,
                    "tenant_id": "d6adf5e1-c3de-49bc-8260-87165edf5771",
                    "type": "image",
                    "transfer_method": "remote_url",
                    "remote_url": oss_link,
                    "related_id": None,
                    "filename": "0d1122e7300b49aeb9f8258d1fbb1ef9.jpeg",
                    "extension": ".jpg",
                    "mime_type": "image/jpeg",
                    "size": 161653,
                    "url": oss_link
                }
            ],
            "trace_id": "99afa802214c6e53",
            "sys.files": [],
            "sys.user_id": "L84JXQG7MDD4ED",
            "sys.app_id": "4b8e5838-a063-4dbe-97d3-d94355788e28",
            "sys.workflow_id": "b57c27a1-e8fc-4d08-97f1-4807b4c111a2",
            "sys.workflow_run_id": "165c5eb3-04d7-4bb8-a134-020332da81bf"
        }
    }
        
    headers = {
        'Authorization': f'Bearer {dify_token}',
        'Content-Type': 'application/json',
    }
    # https://rd-dify-sit.fuse.co.id/console/api/apps/4b8e5838-a063-4dbe-97d3-d94355788e28/workflows/draft/run
    request_url = f"{DIFY_ENDPOINT}{DIFY_RECOGNITION_WORKFLOWID}/workflows/draft/run"
    print(request_url)
    try:
        resp = requests.post(request_url, headers=headers, json=payload, stream=True)
        resp.raise_for_status()

        final_answer = None
        print(resp.text)
        for line in resp.iter_lines():
            if line:
                decoded_line = line.decode('utf-8').strip()
                if decoded_line.startswith("data: "):
                    event_data = decoded_line[6:]  # 去掉 "data: "
                    try:
                        event_json = json.loads(event_data)
                        if event_json.get("event") == "workflow_finished":
                            final_answer = event_json.get("data", {}).get("outputs", {}).get("result")
                        elif event_json.get("event") == "message_end":
                            final_answer = event_json.get("metadata", {}).get("text", final_answer)
                    except json.JSONDecodeError:
                        continue
                        
        if final_answer is not None:
            print(f"三方接口返回结果: {final_answer}")
            return final_answer
        else:
            print("No valid answer found in SSE stream.")
            return None
    except requests.exceptions.RequestException as e:
        return {'error': f'Dify_TP_Request_Failed: {e}', 'link': oss_link}
    except Exception as e:
        return {'error': f'Dify_TP_Parsing_Failed: {e}', 'link': oss_link}


# --- 新增的 Dify 结果对比函数 ---

def call_dify_compare_workflow(dify_result: Dict[str, Any], third_party_result: Dict[str, Any]) -> str:
    """
    调用 Dify Workflow 来对比两个结果并生成报告。
    """
    print("调用 Dify Workflow 来对比两个结果并生成报告")
    # 检查是否有前置错误
    if 'error' in dify_result or 'error' in third_party_result:
        dify_err = dify_result.get('error', 'None')
        third_err = third_party_result.get('error', 'None')
        return f"⚠️ 对比前置错误: Dify: {dify_err} | Third-Party: {third_err}"

    # 准备发送给对比 Workflow 的数据
    # 将 JSON 结果转换为字符串，作为 Workflow 的输入
    dify_output_str = json.dumps(dify_result, ensure_ascii=False)
    third_party_output_str = json.dumps(third_party_result, ensure_ascii=False)
    
    payload = {
        'inputs': {
            "dify_result_input": dify_output_str,
            "third_party_result_input": third_party_output_str
        },
        "files": []
    }

    
    headers = {
        'Authorization': f'Bearer {dify_token}',
        'Content-Type': 'application/json',
    }
    
    # https://rd-dify-sit.fuse.co.id/console/api/apps/4b8e5838-a063-4dbe-97d3-d94355788e28/workflows/draft/run
    request_url = f"{DIFY_ENDPOINT}{DIFY_COMPARE_API_WORKFLOWID}/workflows/draft/run"
    print(request_url)
    try:
        resp = requests.post(request_url, headers=headers, json=payload, stream=True)
        resp.raise_for_status()

        final_answer = None
        print(resp.text)
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
        
    except requests.exceptions.RequestException as e:
        return f'Dify_Compare_Request_Failed: {e}'
    except Exception as e:
        return f'Dify_Compare_Parsing_Failed: {e}'

# --- 单线程处理函数 (新增) ---
# --- 并行处理函数 ---

def process_link(oss_link: str) -> Dict[str, Any]:
    """
    单个链接的处理单元（内部使用双线程并行调用 API）。
    """
    
    # 1. 并行调用两个识别 API
    with ThreadPoolExecutor(max_workers=2) as executor:
        future_dify = executor.submit(call_dify_workflow, oss_link)
        future_third = executor.submit(call_third_party_api, oss_link)
        
        dify_result = future_dify.result()
        third_party_result = future_third.result()
    
    # 2. 调用 Dify 对比 Workflow
    comparison_report = call_dify_compare_workflow(dify_result, third_party_result)
    
    return {
        'oss_link': oss_link,
        'dify_result': json.dumps(dify_result, ensure_ascii=False),
        'third_party_result': json.dumps(third_party_result, ensure_ascii=False),
        'comparison_report': comparison_report
    }

# --- 核心数据加载和结果保存函数（抽象通用部分）---

def load_data():
    """读取 Excel 数据并应用索引切片。"""
    try:
        df = pd.read_excel(EXCEL_FILE_PATH)
        if OSS_LINK_COLUMN_NAME not in df.columns:
            raise KeyError(f"Excel 中找不到列名 '{OSS_LINK_COLUMN_NAME}'")

        if END_INDEX is not None and END_INDEX <= START_INDEX:
             raise ValueError("END_INDEX 必须大于 START_INDEX。")

        df_slice = df.iloc[START_INDEX:END_INDEX]
        oss_links = df_slice[OSS_LINK_COLUMN_NAME].dropna().astype(str).tolist()
        
        return df, df_slice, oss_links
    except Exception as e:
        raise e

def save_results(df_slice: pd.DataFrame, results: List[Dict[str, Any]], mode: str, total_time: float):
    """将结果合并到 DataFrame 并保存到文件。"""
    if not results:
        print("未获取到任何结果，可能是链接列表为空或处理全部失败。")
        return

    results_df = pd.DataFrame(results)
    
    final_df = df_slice[[OSS_LINK_COLUMN_NAME]].merge(results_df, left_on=OSS_LINK_COLUMN_NAME, right_on='oss_link', how='left')
    
    final_df.drop(columns=['oss_link'], inplace=True, errors='ignore')
    final_df.rename(columns={
        'dify_result': 'Dify_Recognition_Result_JSON',
        'third_party_result': 'ThirdParty_Recognition_Result_JSON',
        'comparison_report': 'Dify_Comparison_Report'
    }, inplace=True)

    base, ext = os.path.splitext(EXCEL_FILE_PATH)
    end_index_label = END_INDEX if END_INDEX is not None else len(df_slice) + START_INDEX
    
    output_file_path = f"{base}_results_{START_INDEX}_to_{end_index_label}_{mode}.xlsx"
    final_df.to_excel(output_file_path, index=False)
    
    print(f"\n==========================================")
    print(f"✅ 范围处理完毕。")
    print(f"模式: {mode}")
    print(f"总耗时: {total_time:.2f} 秒 ({total_time / 60:.2f} 分钟)")
    print(f"结果已保存到文件: {output_file_path}")
    print(f"==========================================")



def main_single_thread():
    """
    单线程串行执行所有 API 调用和对比。
    """
    start_time = time.time()
    mode = "single_thread"
    print(f"🚀 开始处理 Excel 文件，模式：{mode}")
    
    try:
        df, df_slice, oss_links = load_data()
        total_links = len(oss_links)
        
        print(f"--- 范围信息 ---")
        print(f"原始文件共 {len(df)} 行。")
        print(f"本次处理范围: 从索引 {START_INDEX} 到 {END_INDEX if END_INDEX is not None else '文件末尾'}")
        print(f"总计处理 {total_links} 个有效 OSS 链接。将以串行模式执行。")
        print(f"----------------")
    except Exception as e:
        print(f"读取 Excel 文件时发生错误: {e}")
        return

    results = []
    
    # 串行循环处理链接
    for i, link in enumerate(oss_links):
        print(f"[{i + 1}/{total_links}] ⏳ 正在处理: {link[:50]}...")
        
        # 串行调用 API 和对比
        try:
            # 串行调用两个识别 API
            dify_result = call_dify_workflow(link)
            third_party_result = call_third_party_api(link)
            
            # 调用 Dify 对比 Workflow
            comparison_report = call_dify_compare_workflow(dify_result, third_party_result)
            print(f"对比报告: {comparison_report}")

            data = {
                'oss_link': link,
                'dify_result': json.dumps(dify_result, ensure_ascii=False),
                'third_party_result': json.dumps(third_party_result, ensure_ascii=False),
                'comparison_report': comparison_report
            }
            results.append(data)

            is_failed = 'Failed' in data['comparison_report'] or '错误' in data['comparison_report']
            status_emoji = '⚠️' if is_failed else '✅'
            print(f"[{i + 1}/{total_links}] {status_emoji} 完成: {link[:50]}...")

        except Exception as exc:
            print(f"链接 {link} 生成了一个致命异常: {exc}")
            results.append({
                'oss_link': link,
                'dify_result': json.dumps({'error': 'Process_Failed'}),
                'third_party_result': json.dumps({'error': 'Process_Failed'}),
                'comparison_report': f"致命错误: {exc}"
            })

    end_time = time.time()
    save_results(df_slice, results, mode, end_time - start_time)


# --- 多线程处理函数 ---

def main_multi_thread():
    """
    多线程并行执行所有 API 调用和对比。
    """
    start_time = time.time()
    mode = "multi_thread"
    print(f"🚀 开始处理 Excel 文件，模式：{mode}")

    try:
        df, df_slice, oss_links = load_data()
        total_links = len(oss_links)
        
        print(f"--- 范围信息 ---")
        print(f"原始文件共 {len(df)} 行。")
        print(f"本次处理范围: 从索引 {START_INDEX} 到 {END_INDEX if END_INDEX is not None else '文件末尾'}")
        print(f"总计处理 {total_links} 个有效 OSS 链接。将使用 {MAX_WORKERS} 个线程并行处理...")
        print(f"----------------")
    except Exception as e:
        print(f"读取 Excel 文件时发生错误: {e}")
        return

    results = []
    
    with ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
        future_to_link = {executor.submit(process_link, link): link for link in oss_links}
        
        for i, future in enumerate(as_completed(future_to_link)):
            link = future_to_link[future]
            try:
                data = future.result()
                results.append(data)
                
                is_failed = 'Failed' in data['comparison_report'] or '错误' in data['comparison_report']
                status_emoji = '⚠️' if is_failed else '✅'
                print(f"[{i + 1}/{total_links}] {status_emoji} 完成: {link[:50]}...")
            except Exception as exc:
                print(f"链接 {link} 生成了一个异常: {exc}")
                results.append({
                    'oss_link': link,
                    'dify_result': json.dumps({'error': 'Process_Failed'}),
                    'third_party_result': json.dumps({'error': 'Process_Failed'}),
                    'comparison_report': f"致命错误: {exc}"
                })

    end_time = time.time()
    save_results(df_slice, results, mode, end_time - start_time)

if __name__ == "__main__":
    if USE_MULTI_THREADING:
        main_multi_thread()
    else:
        main_single_thread()