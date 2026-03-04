# utils/file_io.py

import pandas as pd
from typing import List, Dict, Any
import os
from config import ( 
    INPUT_COL_REQUEST_JSON, INPUT_COL_PREDICTED_GAP,
    OUTPUT_COL_INDEX, OUTPUT_COL_REQUEST_JSON,
    OUTPUT_COL_MCP_RESPONSE, OUTPUT_COL_DIFY_RESULT,
    OUTPUT_COL_PREDICTED_GAP
)

def read_test_data(test_data_file: str) -> List[Dict[str, Any]]:
    """
    接收测试数据文件路径，读取测试用例。
    """
    test_cases = []
    try:
        df = pd.read_excel(test_data_file)
        
        required_cols = [INPUT_COL_REQUEST_JSON, INPUT_COL_PREDICTED_GAP]
        if not all(col in df.columns for col in required_cols):
            raise ValueError(f"测试文件缺少必要列: {required_cols}")

        for index, row in df.iterrows():
            # 确保request_json始终是字符串类型，避免JSON解析错误
            request_json = str(row[INPUT_COL_REQUEST_JSON]) if pd.notna(row[INPUT_COL_REQUEST_JSON]) else ""
            test_cases.append({
                "index": index,
                "request_json": request_json,
                "predicted_gap": row[INPUT_COL_PREDICTED_GAP]
            })
        return test_cases
    except FileNotFoundError:
        print(f"错误: 找不到测试用例文件 '{test_data_file}'")
        return []
    except Exception as e:
        print(f"读取测试用例时发生错误: {e}")
        return []

def write_test_results(results: List[Dict[str, Any]], result_data_file: str):
    """
    接收结果文件路径，将结果输出到 Excel。
    """
    try:
        # 创建结果文件夹（如果不存在）
        results_dir = os.path.dirname(result_data_file)
        if results_dir and not os.path.exists(results_dir):
            os.makedirs(results_dir)
            print(f"已创建结果文件夹: '{results_dir}'")

        df = pd.DataFrame(results)
        
        df.rename(columns={
            'index': OUTPUT_COL_INDEX,
            'request_json': OUTPUT_COL_REQUEST_JSON,
            'mcp_response': OUTPUT_COL_MCP_RESPONSE,
            'dify_result': OUTPUT_COL_DIFY_RESULT,
            'predicted_gap': OUTPUT_COL_PREDICTED_GAP
        }, inplace=True)
        
        output_columns = [
            OUTPUT_COL_INDEX,
            OUTPUT_COL_REQUEST_JSON,
            OUTPUT_COL_PREDICTED_GAP,
            OUTPUT_COL_MCP_RESPONSE,
            OUTPUT_COL_DIFY_RESULT
        ]
        
        df = df[output_columns]

        df.to_excel(result_data_file, index=False)
        print(f"\n✅ 测试结果已成功写入 '{result_data_file}'")
    except Exception as e:
        print(f"写入测试结果时发生错误: {e}")