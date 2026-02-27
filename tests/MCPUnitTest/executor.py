import threading
from typing import List, Dict, Any
from concurrent.futures import ThreadPoolExecutor, as_completed
import time
import json

from utils.file_io import read_test_data, write_test_results
from utils.dify_workflow import *

# 定义批量保存的阈值
BATCH_SIZE = 10
CONVERSATION_ID = None

def _process_single_case_use_agent(test_case: Dict) -> Dict:
    global CONVERSATION_ID
    """
    处理单个测试用例的逻辑：调用MCP -> 调用Dify -> 返回结果。
    """
    index = test_case['index']
    request_json_str = test_case['request_json']
    predicted_gap = test_case['predicted_gap']
    
    print(f"--- 正在处理案例: {index} ---")
    
    # 0. 打印入参
    print(f"入参：{request_json_str}")

    # 1. 调用 agent 接口
    mcp_response = None
    dify_result = None
    # need to do: 修改这里的MCP接口参数
    # mcp_response = call_mcp_Agent_Sub_Quotation(request_json_str)
    # 如果CONVERSATION_ID为空，说明是第一次调用，则需要先调用一次agent, 并获取CONVERSATION_ID, 再继续调用agent
    if CONVERSATION_ID is None:
        query = "kevin"
        # 第一次调用agent, 并获取CONVERSATION_ID
        mcp_response, CONVERSATION_ID = call_langchain_agent(input_data=query)
        # 接着调用agent, 开始测试
        mcp_response, CONVERSATION_ID = call_langchain_agent(input_data=request_json_str, conversation_id=CONVERSATION_ID) 
    else:
        mcp_response, CONVERSATION_ID = call_langchain_agent(input_data=request_json_str, conversation_id=CONVERSATION_ID) 

    print(f"mcp结果：{mcp_response}")

    # 2. 调用 Dify Workflow 进行比较
    if mcp_response is None:
        mcp_response = "None"
        dify_result = {"error": "跳过Dify比对，因MCP接口调用失败", "mcp_error": mcp_response['error']}
    else:
        dify_result = run_dify_comparison_str(mcp_response, predicted_gap)
        print(f"dify结果：{dify_result}")




    # 3. 格式化结果
    result = {
        'index': index,
        'request_json': request_json_str,
        'predicted_gap': predicted_gap,
        'mcp_response': json.dumps(mcp_response, ensure_ascii=False, indent=2), 
        'dify_result': json.dumps(dify_result, ensure_ascii=False, indent=2)
    }
    
    return result


def _process_single_case(test_case: Dict) -> Dict:
    """
    处理单个测试用例的逻辑：调用MCP -> 调用Dify -> 返回结果。
    """
    index = test_case['index']
    request_json_str = test_case['request_json']
    predicted_gap = test_case['predicted_gap']
    
    print(f"--- 正在处理案例: {index} ---")
    
    # 0. 打印入参
    print(f"入参：{request_json_str}")

    # 1. 调用 MCP 接口
    mcp_response = None
    dify_result = None
    # need to do: 修改这里的MCP接口参数
    # mcp_response = call_mcp_Agent_Sub_Quotation(request_json_str)
    mcp_response = call_mcp_list_policies(request_json_str)

    print(f"mcp结果：{mcp_response}")

    # 2. 调用 Dify Workflow 进行比较
    if mcp_response is None:
        mcp_response = "None"
        dify_result = {"error": "跳过Dify比对，因MCP接口调用失败", "mcp_error": mcp_response['error']}
    else:
        dify_result = run_dify_comparison_str(mcp_response, predicted_gap)
        print(f"dify结果：{dify_result}")

    # 3. 格式化结果
    result = {
        'index': index,
        'request_json': request_json_str,
        'predicted_gap': predicted_gap,
        'mcp_response': json.dumps(mcp_response, ensure_ascii=False, indent=2), 
        'dify_result': json.dumps(dify_result, ensure_ascii=False, indent=2)
    }
    
    return result

def run_tests(
    test_data_file: str, 
    result_data_file: str,
    start_index: int, 
    end_index: int, 
    use_multithreading: bool, 
    max_workers: int = 5,
    model: str = "MCP"
):
    """
    根据运行模式执行测试，并控制测试用例索引范围。
    """
    
    all_test_cases = read_test_data(test_data_file) 
    if not all_test_cases:
        print("没有可执行的测试用例。")
        return

    # 过滤测试用例 (Excel index 从 0 开始)
    test_cases_to_run = [
        case for case in all_test_cases 
        if start_index <= case['index'] <= end_index
    ]

    print(f"\n🔔 共有 {len(all_test_cases)} 个测试用例，实际执行范围: [{start_index} - {end_index}]，共 {len(test_cases_to_run)} 个。")
    print(f"模式: {'多线程' if use_multithreading else '单线程'}")
    
    if not test_cases_to_run:
        print("在指定索引范围内没有找到测试用例。")
        return

    # 初始化结果列表和计数器
    all_final_results = [] # 存储所有结果
    results_buffer = []    # 缓存当前批次的结果

    start_time = time.time()
    
    def _save_batch(results: List[Dict[str, Any]]):
        """将缓存中的结果追加写入文件，并清空缓存。"""
        if not results:
            return
        
        # 实时写入时需要确保文件IO模块支持追加模式。
        # 由于当前的 file_io.py 是覆盖模式，这里我们先收集到 final_results 中，最后统一写入。
        # 
        # **为了实现真正的“批量写入/实时保存”功能，我们需要修改 file_io.py 使其支持 Excel 追加。**
        #
        # 考虑到 pandas/openpyxl 对 Excel 追加操作比较复杂且性能不高，
        # 我们在这里采取一种更安全、更通用的“检查点”机制：
        # 1. 将所有结果收集到 `all_final_results`。
        # 2. 每达到 `BATCH_SIZE` 个结果时，调用 `write_test_results` 覆盖保存一次，作为检查点。
        
        # 将当前批次结果添加到总列表
        all_final_results.extend(results)
        
        # 覆盖保存（作为检查点）
        write_test_results(all_final_results, result_data_file)
        
        print(f"\n[检查点] 成功保存 {len(results)} 个结果。当前总计保存 {len(all_final_results)} 个。")



    if use_multithreading:
        # --- 多线程模式 ---
        with ThreadPoolExecutor(max_workers=max_workers) as executor:
            future_to_case = {executor.submit(_process_single_case, case): case for case in test_cases_to_run}
            
            for future in as_completed(future_to_case):
                try:
                    result = future.result()
                    results_buffer.append(result)
                    
                    # 达到批量大小，执行保存
                    if len(results_buffer) >= BATCH_SIZE:
                        _save_batch(results_buffer)
                        results_buffer = [] # 清空缓存
                        
                except Exception as e:
                    case_index = future_to_case[future]['index']
                    print(f"案例 {case_index} 运行异常: {e}")
                    
    else:
        # --- 单线程模式 ---
        for case in test_cases_to_run:
            if model == "MCP":            # 调用MCP接口
                result = _process_single_case(case)
            elif model == "Agent":
            # 调用Dify接口
                result = _process_single_case_use_agent(case)

            results_buffer.append(result)
            
            # 达到批量大小，执行保存
            if len(results_buffer) >= BATCH_SIZE:
                _save_batch(results_buffer)
                results_buffer = [] # 清空缓存

    end_time = time.time()
    
    # 最终保存：处理剩余在 buffer 中的结果
    if results_buffer:
        _save_batch(results_buffer) 
        
    # 如果总结果列表不为空，则再次执行最终写入 (如果_save_batch是覆盖模式，这一步是必要的)
    # 由于 _save_batch 已经执行了最终写入，这里仅做收尾打印
    if all_final_results:
        print(f"\n🎉 所有测试案例处理完成。总耗时: {end_time - start_time:.2f} 秒。")