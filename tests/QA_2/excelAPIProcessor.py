import threading

import pandas as pd
from concurrent.futures import ThreadPoolExecutor, as_completed
import requests
import json
from queue import Queue
import os
import time


class ExcelAPIProcessor:
    def __init__(self, config):
        self.config = config
        self.results = []
        self.failed_indices = []
        self.lock = threading.Lock()

    def read_excel(self):
        """分块读取Excel文件"""
        return pd.read_excel(
            self.config['excel_path'],
            sheet_name=self.config['sheet_name'],
            usecols=self.config['columns'],
            chunksize=self.config['chunksize']
        )

    def process_row(self, row, index):
        """处理单行数据并调用API"""
        try:
            # 构建请求参数
            payload = self.config['payload_template'].format(**row.to_dict())

            # 发送请求
            response = requests.post(
                self.config['api_url'],
                headers=self.config['headers'],
                json=payload,
                timeout=self.config['timeout']
            )
            response.raise_for_status()

            # 解析结果
            result = response.json()
            return index, result.get('data', '')

        except Exception as e:
            print(f"[{index}] 请求失败: {str(e)}")
            with self.lock:
                self.failed_indices.append(index)
            return None

    def batch_process(self):
        """批量处理数据"""
        # 读取Excel数据
        all_data = []
        for chunk in self.read_excel():
            all_data.extend(chunk.to_dict('records'))

        total = len(all_data)
        print(f"共处理 {total} 条数据")

        # 创建线程池
        with ThreadPoolExecutor(max_workers=self.config['max_workers']) as executor:
            futures = []
            for idx, row in enumerate(all_data):
                futures.append(executor.submit(self.process_row, row, idx))

                # 动态调整提交速度防止API过载
                if idx % 10 == 0:
                    time.sleep(self.config['delay'])

            # 收集结果
            for future in as_completed(futures):
                result = future.result()
                if result:
                    with self.lock:
                        self.results.append(result)

    def write_excel(self):
        """结果写回Excel"""
        # 读取原始文件
        df = pd.read_excel(self.config['excel_path'], sheet_name=self.config['sheet_name'])

        # 合并结果
        for idx, value in self.results:
            df.at[idx, self.config['result_column']] = value

        # 保存文件
        with pd.ExcelWriter(self.config['output_path'], engine='openpyxl', mode='a') as writer:
            df.to_excel(writer, index=False)
        print(f"结果已保存至 {self.config['output_path']}")


if __name__ == "__main__":
    # 配置参数
    CONFIG = {
        'excel_path': 'input.xlsx',
        'sheet_name': 'Sheet1',
        'columns': ['id', 'content'],  # 需要处理的列
        'result_column': 'api_result',  # 结果写入列
        'api_url': 'https://api.example.com/process',
        'headers': {'Authorization': 'Bearer YOUR_API_KEY'},
        'payload_template': json.dumps({
            "data_id": "{id}",
            "text": "{content}",
            "lang": "zh-CN"
        }),
        'max_workers': 20,  # 线程数
        'timeout': 30,  # 请求超时
        'chunksize': 1000,  # 分块大小
        'delay': 0.1  # 请求间隔
    }

    # 初始化处理器
    processor = ExcelAPIProcessor(CONFIG)

    # 执行处理流程
    processor.batch_process()
    processor.write_excel()