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
# https://rd-dify-sit.fuse.co.id/console/api/apps/cec5e67c-fcdd-472b-81bb-e8bb4b1db5fa/workflows/draft/nodes/1761544503052/run
url = "https://rd-dify-sit.fuse.co.id/console/api/apps/cec5e67c-fcdd-472b-81bb-e8bb4b1db5fa/workflows/draft/nodes/1761544503052/run"
token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiNTUyYmRiODktNTlkOC00NDExLWJiZmYtMjM3MGQwOWQ4MTljIiwiZXhwIjoxNzYyMzI3NTA4LCJpc3MiOiJTRUxGX0hPU1RFRCIsInN1YiI6IkNvbnNvbGUgQVBJIFBhc3Nwb3J0In0.7bEO0uTt7MCqW8EWC3UWnuPhiB10NNbSfX6Ufq3vabI"
# token = "app-y9y1NCXH1hoZV1heFctfIzd7"
user = "nn"
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
            "inputs": {
                "#17616706670560.intent_code#": "INTENT_QUICK_ORDER",
                "#17616706670560.intent_slot_dict#": "[{\\\"slotCode\\\": \\\"insuranceCompany\\\", \\\"slotName\\\": \\\"insuranceCompany\\\", \\\"slotPrompt\\\": \\\"{\\\\n    \\\\\\\"desc\\\\\\\": \\\\\\\"insurance company name.\\\\\\\",\\\\n    \\\\\\\"example\\\\\\\":\\\\\\\"MSIG,ABDA\\\\\\\",\\\\n    \\\\\\\"exampleData\\\\\\\":\\\\\\\"please check if user input match any of below insurance company name or abbr , and reply the fullname.   Leave it  empty if no preference.\\\\\\\\n* PT Asuransi Bina Dana Arta Tbk, ABDA, OONA, ABDA Insurance, Oona ABDA, Bina Dana, \\\\\\\\n* PT Asuransi Intra Asia, Intra, Intra Asia, Intra Asia Insurance, Asuransi Intra, IntraAsia, \\\\\\\\n* PT Asuransi Umum SeaInsure, SeaInsure, Sea, Sea Insurance, SeaGeneral, Sea Ins, \\\\\\\\n* PT KB Insurance Indonesia, KB, KB Insurance, KB Asuransi, KB Indo, \\\\\\\\n* PT Asuransi Tugu Pratama Indonesia Tbk, Tugu, Tugu Pratama, Tugu Insurance, Asuransi Tugu, TPI, \\\\\\\\n* PT Asuransi Etiqa Internasional Indonesia, Etiqa, Etiqa Insurance, Asuransi Etiqa, Etiqa Indo, Etiqa International, \\\\\\\\n* PT Zurich General Takaful Indonesia, Zurich Takaful, Zurich, Zurich Syariah, Takaful Zurich, Zurich General, ZTGI\\\\\\\\n* PT Asuransi Umum Mega, Mega Insurance, Mega, Asuransi Mega, Mega Umum, AUM, \\\\\\\\n* PT Asuransi Simas Insurtech, Simas Insurtech, Simas, Sintech, Asuransi Simas, Insurtech Simas, ASI\\\\\\\\n* PT Asuransi Multi Artha Guna Tbk, MAG, Multi Artha Guna, MAG Insurance, Asuransi MAG, Artha Guna\\\\\\\",\\\\n    \\\\\\\"clarification\\\\\\\": {\\\\n        \\\\\\\"en\\\\\\\": \\\\\\\"Bot: May I know your insurance company name? (e.g., Allianz, AXA, Prudential, ABDA)\\\\\\\",\\\\n        \\\\\\\"id\\\\\\\": \\\\\\\"Bot: Bolehkah saya mengetahui nama perusahaan asuransi Anda? (contoh: Allianz, AXA, Prudential, ABDA)\\\\\\\"\\\\n    },\\\\n    \\\\\\\"fallback\\\\\\\": {\\\\n        \\\\\\\"en\\\\\\\": \\\\\\\"Bot: The insurance company you provided is invalid. Please provide a valid insurer name.\\\\\\\",\\\\n        \\\\\\\"id\\\\\\\": \\\\\\\"Bot: Perusahaan asuransi yang Anda berikan tidak valid. Harap berikan nama perusahaan asuransi yang valid.\\\\\\\"\\\\n    }\\\\n}\\\", \\\"slotRule\\\": \\\"{\\\\\\\"insuranceCompany\\\\\\\": {\\\\\\\"required\\\\\\\": true,\\\\\\\"field\\\\\\\":\\\\\\\"$.data.insuranceCompany\\\\\\\"}}\\\"}, {\\\"slotCode\\\": \\\"ktp\\\", \\\"slotName\\\": \\\"ktp\\\", \\\"slotPrompt\\\": \\\"{\\\\\\\"clarification\\\\\\\":{ \\\\\\\"en\\\\\\\": \\\\\\\"Bot: We need a copy of your ID card (KTP). Could you upload it?\\\\\\\", \\\\\\\"id\\\\\\\": \\\\\\\"Bot: Kami membutuhkan salinan KTP Anda. Bisakah Anda mengunggahnya?\\\\\\\" },\\\\\\\"fallback\\\\\\\": { \\\\\\\"en\\\\\\\": \\\\\\\"Bot: Your ID (KTP) is invalid or expired. Please upload a valid, unexpired ID document.\\\\\\\", \\\\\\\"id\\\\\\\": \\\\\\\"Bot: KTP Anda tidak valid atau kedaluwarsa. Harap unggah dokumen ID yang valid dan belum kedaluwarsa.\\\\\\\" }}\\\", \\\"slotRule\\\": \\\"{\\\\\\\"ktp\\\\\\\": {\\\\\\\"required\\\\\\\": true,\\\\\\\"field\\\\\\\":\\\\\\\"$.files.ktp\\\\\\\"}}\\\"}, {\\\"slotCode\\\": \\\"stnk\\\", \\\"slotName\\\": \\\"stnk\\\", \\\"slotPrompt\\\": \\\"{\\\\\\\"clarification\\\\\\\":{ \\\\\\\"en\\\\\\\": \\\\\\\"Bot: Please share a photo of your vehicle registration document (STNK).\\\\\\\", \\\\\\\"id\\\\\\\": \\\\\\\"Bot: Harap bagikan foto dokumen registrasi kendaraan Anda (STNK).\\\\\\\" },\\\\\\\"fallback\\\\\\\": { \\\\\\\"en\\\\\\\": \\\\\\\"Bot: The vehicle registration (STNK) is invalid. Please upload a clear, unexpired STNK document.\\\\\\\", \\\\\\\"id\\\\\\\": \\\\\\\"Bot: STNK tidak valid. Harap unggah dokumen STNK yang jelas dan belum kedaluwarsa.\\\\\\\" }}\\\", \\\"slotRule\\\": \\\"{\\\\\\\"stnk\\\\\\\": {\\\\\\\"required\\\\\\\": true,\\\\\\\"field\\\\\\\":\\\\\\\"$.files.stnk\\\\\\\"}}\\\"}, {\\\"slotCode\\\": \\\"bstk\\\", \\\"slotName\\\": \\\"bstk\\\", \\\"slotPrompt\\\": \\\"{\\\\\\\"clarification\\\\\\\":{ \\\\\\\"en\\\\\\\": \\\\\\\"Bot: Could you upload your vehicle tax payment receipt (BSTK)?\\\\\\\", \\\\\\\"id\\\\\\\": \\\\\\\"Bot: Bisakah Anda mengunggah tanda terima pembayaran pajak kendaraan (BSTK)?\\\\\\\" },\\\\\\\"fallback\\\\\\\": { \\\\\\\"en\\\\\\\": \\\\\\\"Bot: The tax receipt (BSTK) is invalid. Please upload a current-year payment receipt.\\\\\\\", \\\\\\\"id\\\\\\\": \\\\\\\"Bot: Tanda terima pajak (BSTK) tidak valid. Harap unggah tanda terima pembayaran tahun berjalan.\\\\\\\" }}\\\", \\\"slotRule\\\": \\\"{\\\\\\\"bstk\\\\\\\": {\\\\\\\"required\\\\\\\": true,\\\\\\\"field\\\\\\\":\\\\\\\"$.files.bstk\\\\\\\"}}\\\"}, {\\\"slotCode\\\": \\\"dashboard\\\", \\\"slotName\\\": \\\"dashboard\\\", \\\"slotPrompt\\\": \\\"{\\\\\\\"desc\\\\\\\":\\\\\\\"dashboard\\\\\\\",\\\\\\\"example\\\\\\\":\\\\\\\"dashboard\\\\\\\",\\\\n\\\\\\\"clarification\\\\\\\":{ \\\\\\\"en\\\\\\\": \\\\\\\"Bot: Could you please upload a photo of your vehicle\\\\u2019s dashboard showing odometer and warning lights?\\\\\\\", \\\\\\\"id\\\\\\\": \\\\\\\"Bot: Bisakah Anda mengunggah foto dashboard kendaraan Anda yang menunjukkan odometer dan lampu peringatan?\\\\\\\" },\\\\\\\"fallback\\\\\\\": { \\\\\\\"en\\\\\\\": \\\\\\\"Bot: The dashboard photo is unclear/invalid. Please upload a clear image showing mileage and warning lights.\\\\\\\", \\\\\\\"id\\\\\\\": \\\\\\\"Bot: Foto dashboard tidak jelas/tidak valid. Harap unggah gambar yang jelas yang menunjukkan jarak tempuh dan lampu peringatan.\\\\\\\" }}\\\", \\\"slotRule\\\": \\\"{\\\\\\\"dashboard\\\\\\\": {\\\\\\\"required\\\\\\\": true,\\\\\\\"field\\\\\\\":\\\\\\\"$.files.dashboard\\\\\\\"}}\\\"}, {\\\"slotCode\\\": \\\"front\\\", \\\"slotName\\\": \\\"front\\\", \\\"slotPrompt\\\": \\\"{\\\\\\\"clarification\\\\\\\":{ \\\\\\\"en\\\\\\\": \\\\\\\"Bot: Please provide a clear photo of your vehicle\\\\u2019s front side including license plate.\\\\\\\", \\\\\\\"id\\\\\\\": \\\\\\\"Bot: Harap berikan foto jelas bagian depan kendaraan Anda termasuk plat nomor.\\\\\\\" },\\\\\\\"fallback\\\\\\\": { \\\\\\\"en\\\\\\\": \\\\\\\"Bot: The front photo is incomplete. Please upload a full view including license plate.\\\\\\\", \\\\\\\"id\\\\\\\": \\\\\\\"Bot: Foto depan tidak lengkap. Harap unggah tampilan penuh termasuk plat nomor.\\\\\\\" }}\\\", \\\"slotRule\\\": \\\"{\\\\\\\"front\\\\\\\": {\\\\\\\"required\\\\\\\": true,\\\\\\\"field\\\\\\\":\\\\\\\"$.files.front\\\\\\\"}}\\\"}, {\\\"slotCode\\\": \\\"back\\\", \\\"slotName\\\": \\\"back\\\", \\\"slotPrompt\\\": \\\"{\\\\\\\"clarification\\\\\\\":{ \\\\\\\"en\\\\\\\": \\\\\\\"Bot: Kindly upload a photo showing the rear of your vehicle including license plate.\\\\\\\", \\\\\\\"id\\\\\\\": \\\\\\\"Bot: Harap unggah foto yang menunjukkan bagian belakang kendaraan termasuk plat nomor.\\\\\\\" },\\\\\\\"fallback\\\\\\\": { \\\\\\\"en\\\\\\\": \\\\\\\"Bot: The rear photo is unclear. Please upload a clear image showing the full back with license plate.\\\\\\\", \\\\\\\"id\\\\\\\": \\\\\\\"Bot: Foto belakang tidak jelas. Harap unggah gambar yang jelas yang menunjukkan bagian belakang lengkap dengan plat nomor.\\\\\\\" }}\\\", \\\"slotRule\\\": \\\"{\\\\\\\"back\\\\\\\": {\\\\\\\"required\\\\\\\": true,\\\\\\\"field\\\\\\\":\\\\\\\"$.files.back\\\\\\\"}}\\\"}, {\\\"slotCode\\\": \\\"left\\\", \\\"slotName\\\": \\\"left\\\", \\\"slotPrompt\\\": \\\"{\\\\\\\"clarification\\\\\\\":{ \\\\\\\"en\\\\\\\": \\\\\\\"Bot: We need a photo of the left side of your vehicle. Could you share it?\\\\\\\", \\\\\\\"id\\\\\\\": \\\\\\\"Bot: Kami membutuhkan foto sisi kiri kendaraan Anda. Bisakah Anda membagikannya?\\\\\\\" },\\\\\\\"fallback\\\\\\\": { \\\\\\\"en\\\\\\\": \\\\\\\"Bot: The left-side photo is missing. Please upload a clear image of the vehicle\\\\u2019s left side.\\\\\\\", \\\\\\\"id\\\\\\\": \\\\\\\"Bot: Foto sisi kiri hilang. Harap unggah gambar yang jelas dari sisi kiri kendaraan.\\\\\\\" }}\\\", \\\"slotRule\\\": \\\"{\\\\\\\"left\\\\\\\": {\\\\\\\"required\\\\\\\": true,\\\\\\\"field\\\\\\\":\\\\\\\"$.files.left\\\\\\\"}}\\\"}, {\\\"slotCode\\\": \\\"right\\\", \\\"slotName\\\": \\\"right\\\", \\\"slotPrompt\\\": \\\"{\\\\\\\"clarification\\\\\\\":{ \\\\\\\"en\\\\\\\": \\\\\\\"Bot: Please provide a photo of the right side of your vehicle.\\\\\\\", \\\\\\\"id\\\\\\\": \\\\\\\"Bot: Harap berikan foto sisi kanan kendaraan Anda.\\\\\\\" },\\\\\\\"fallback\\\\\\\": { \\\\\\\"en\\\\\\\": \\\\\\\"Bot: The right-side photo is missing/invalid. Please upload a clear image of the vehicle\\\\u2019s right side.\\\\\\\", \\\\\\\"id\\\\\\\": \\\\\\\"Bot: Foto sisi kanan hilang/tidak valid. Harap unggah gambar yang jelas dari sisi kanan kendaraan.\\\\\\\" }}\\\", \\\"slotRule\\\": \\\"{\\\\\\\"right\\\\\\\": {\\\\\\\"required\\\\\\\": true,\\\\\\\"field\\\\\\\":\\\\\\\"$.files.right\\\\\\\"}}\\\"}, {\\\"slotCode\\\": \\\"coverageType\\\", \\\"slotName\\\": \\\"coverageType\\\", \\\"slotPrompt\\\": \\\"{\\\\\\\"desc\\\\\\\":\\\\\\\"Desired type of protection:[1] Comprehensive (complete coverage);[2] TLO (Total Loss Only)\\\\\\\",\\\\\\\"clarification\\\\\\\":{ \\\\\\\"en\\\\\\\": \\\\\\\"Bot: What type of insurance coverage are you looking for? (All Risk, TLO, or Third Party)\\\\\\\", \\\\\\\"id\\\\\\\": \\\\\\\"Bot: Jenis pertanggungan asuransi apa yang Anda cari? (All Risk, TLO, atau Third Party)\\\\\\\" },\\\\\\\"fallback\\\\\\\": { \\\\\\\"en\\\\\\\": \\\\\\\"Bot: Invalid coverage type. Please specify: All Risk, TLO, or Third Party.\\\\\\\", \\\\\\\"id\\\\\\\": \\\\\\\"Bot: Jenis pertanggungan tidak valid. Harap tentukan: All Risk, TLO, atau Third Party.\\\\\\\" }}\\\", \\\"slotRule\\\": \\\"{\\\\\\\"coverageType\\\\\\\": {\\\\\\\"required\\\\\\\": true,\\\\\\\"field\\\\\\\":\\\\\\\"$.data.coverageType\\\\\\\"}}\\\"}, {\\\"slotCode\\\": \\\"displayCategoryId\\\", \\\"slotName\\\": \\\"displayCategoryId\\\", \\\"slotPrompt\\\": \\\"{\\\\\\\"desc\\\\\\\":\\\\\\\"displayCategoryId\\\\\\\",\\\\\\\"example\\\\\\\":\\\\\\\"49\\\\\\\",\\\\n  \\\\\\\"en\\\\\\\": \\\\\\\"\\\\\\\",\\\\n  \\\\\\\"id\\\\\\\": \\\\\\\"\\\\\\\"\\\\n}\\\"}]",
                "#17616706670560.query#": question
            }
        }



        headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json"
        }
        resp = requests.post(url, json=body, headers=headers, timeout=60)
        resp.raise_for_status()
        data = resp.json()
        print(data)
        print(type(data))
        print(data['outputs']['text'])
        # 取data字段的output的text字段值
        answer_raw = data['outputs']['text']

        return answer_raw
    except Exception as e:
        logging.error(f"API请求失败: {e}")
        return f"Error: {str(e)}", "", False, f"API请求失败: {str(e)}"


def get_slot_answer(question):
    """调用API获取答案，新增JSON解析准备（核心修改点）"""
    try:
        # 请求前先通过限流器控制频率
        rate_limiter.acquire()
        body = {
            "inputs": {
                "message": question,
                "token": "eyJhbGciOiJIUzI1NiIsInppcCI6IkRFRiJ9.eNpEjE0OwiAQRu_CuiTQTvnxBq5c2B4A6DTiDyWURqPx7k66cZbvffM-bN08O7BwcXXARx6WGybWsOxKTVhOGdNxIm8tzKYFT4qmKeF9XLHsyijZgWzbXksQ5H18n5etBCT3pOzqcv4Xx0g_0gg6bYQRUjUMX5mYVkANYaFh0dUdSKX6HVxrpFoXgpk7GXiQ4DioHrmxOHPvNE6dCEZ4YN8fAAAA__8.5gilS8IPX8qgRU_kxaSQKIdojRQ0qauwHeMid_C0gnw",
                "host": "https://pchat-sit.fuse.co.id/api",
                "tenantId": "1000662",
                "intentCode": "INTENT_QUOTE_COMPARISON",
                "intentBizCode": "INTENT_QUOTE_COMPARISON_1984994513886236674",
                "isCmd": "false",
                "channelType": "whatsapp",
                "channelUserId": "8613412257140",
                "cmd": "",
                "lan": "ID",
                "productCategory": "",
                "displayCategoryId": "",
                "imagePreprocessData": "{\"result\": null}",
                "inputFiles": [],
                "sys.files": [],
                "sys.user_id": "994f824b",
                "sys.app_id": "0aa13934-a51e-49c5-a202-4fd04254191a",
                "sys.workflow_id": "df27374b-4b45-4c2a-b6bc-18e1bcb2c845",
                "sys.workflow_run_id": "b7100b0a-9495-435e-b445-c8728a5f2739"
            },
            "query": "test",
            "response_mode": "blocking",
            "conversation_id": "",
            "user": "test-from-postman",
            "files": []
        }


        headers = {
            "Authorization": f"Bearer app-MQj9luhufFChyAFzcqMIz11D",
            "Content-Type": "application/json"
        }
        resp = requests.post("https://rd-dify-sit.fuse.co.id/v1/chat-messages", json=body, headers=headers, timeout=60)
        resp.raise_for_status()
        data = resp.json()
        # print(data)
        # print(type(data))
        # print(data['answer'])
        # 取data字段的output的text字段值
        answer_raw = data['answer']
        # print(f"slot::{answer_raw}", answer_raw)
        return answer_raw
    except Exception as e:
        logging.error(f"Slot-API请求失败: {e}")
        return f"Error: {str(e)}", "", False, f"API请求失败: {str(e)}"


def get_intent_answer(question):
    """调用API获取答案，新增JSON解析准备（核心修改点）"""
    try:
        # 请求前先通过限流器控制频率
        rate_limiter.acquire()

        body = {
            "inputs": {
                "tenant_id": "1000662",
                "query": question,
                "domain": "https://pchat-sit.fuse.co.id/api",
                "token": "eyJhbGciOiJIUzI1NiIsInppcCI6IkRFRiJ9.eNpEjMsOgjAURP-la0h6aSnFHzBGjRhhwbLANdZHaaBEo_HfvenGWZ6ZOR82Lx1bsf5iQo0PX483dCxh3kzB4XTw6DYD9btKrKvtca_bts3XNKCDc3hvZpziQCsoteBSglRAfWffp3GZeqTuSfLZeP_3NpY-wDlXKuMxoiwShi9PuFCyULzM84RZEyLIQOkIrsGSEAbQ0IshxazLU6kFppoLk5pMnQG7ngtA9v0BAAD__w.DKxdoZOhibErelBEB_IWvlTfCqIajW56oMTKBS3_bpk",
                "dialogue_history": "[{\\\"role\\\": \\\"assistant\\\", \\\"content\\\": \\\"Maaf, plan produk yang kamu pilih saat ini belum tersedia untuk jenis mobil kamu.\\\\n\\\\nTapi jangan khawatir, Fina punya pilihan produk lainnya. Klik tombol di bawah untuk melihat daftar produk yang tersedia.\\\"}]",
                "intent_state": "SLOT_COLLECTING",
                "language": "ID",
                "channel_type": "whatsapp",
                "channel_user_id": "8619830441461",
                "request_from": "",
                "partner_uid": "1000662000000397",
                "trace_id": "",
                "preprocess_data": "",
                "current_intent": ""
            },
            "response_mode": "streaming"
        }



        headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json"
        }
        resp = requests.post("https://rd-dify-sit.fuse.co.id/console/api/installed-apps/980b57f8-97d3-425b-b6f0-3e3e37a2f8ca/workflows/run", json=body, headers=headers, timeout=60)
        # --- 关键的调试步骤 ---
        print(f"HTTP 状态码: {resp.status_code}")
        print(f"原始响应文本: {resp.text}")  # <-- 检查这里输出的内容！
        resp.raise_for_status()

        # 1. 使用 list() 将生成器转换为列表
        lines_list = list(resp.iter_lines())  # <-- 消耗生成器并保存为列表

        # 2. 安全地使用下标/索引
        if lines_list:  # 检查列表是否为空
            print("--- 逆序遍历 ---")
            for line in lines_list[::-1]:
                if line:
                    decoded_line = line.decode('utf-8').strip()
                    if decoded_line.startswith("data: "):
                        event_data = decoded_line[6:]  # 去掉 "data: "
                        print(event_data)
                        try:
                            event_json = json.loads(event_data)
                            if event_json.get("event") == 'workflow_finished':
                                answer_raw = event_json.get("data", {}).get("outputs", {}).get("result")
                                break
                        except requests.RequestException as e:
                            print(f"Error calling chat: {e}")
                            if hasattr(e, 'response') and e.response:
                                print(f"Response status: {e.response.status_code}")
                                print(f"Response body: {e.response.text}")
                            return None
        else:
            print("API 响应中没有返回任何行数据。")







        print(f"intent::{answer_raw}", answer_raw)
        return answer_raw
    except Exception as e:
        logging.error(f"Intent-API请求失败: {e}")
        return f"Error: {str(e)}", "", False, f"API请求失败: {str(e)}"

#组装Mix FLow的入参
def get_mix_flow_input(slot_result: str, intent_result: str) -> dict:
    result = {
        "slot_result": slot_result,
        "intent_result": intent_result,
        "channel_type": "whatsapp",
        "channel_user_id": "8619830441461",
        "domain": "https://pchat-sit.fuse.co.id/api",
        "token": "eyJhbGciOiJIUzI1NiIsInppcCI6IkRFRiJ9.eNpEjMsOgjAURP-la0h6aSnFHzBGjRhhwbLANdZHaaBEo_HfvenGWZ6ZOR82Lx1bsf5iQo0PX483dCxh3kzB4XTw6DYD9btKrKvtca_bts3XNKCDc3hvZpziQCsoteBSglRAfWffp3GZeqTuSfLZeP_3NpY-wDlXKuMxoiwShi9PuFCyULzM84RZEyLIQOkIrsGSEAbQ0IshxazLU6kFppoLk5pMnQG7ngtA9v0BAAD__w.DKxdoZOhibErelBEB_IWvlTfCqIajW56oMTKBS3_bpk",
        "intent_type": "TRANSACTIONAL",
        "biz_code": "INTENT_QUOTATION_1985314000846176257"
    }
    return {
        "result": json.dumps(result),
    }

def parse_intent_result(intent_result: str) -> dict:

    # 图片请求不做意图识别，直接走槽位识别，所以这里没有意图识别结果
    if intent_result is None or intent_result == "":
        return None
    """
    解析intent_result，返回核心字段
    """
    data = json.loads(intent_result)
    print(f"data: {data}")
    intent_recognition = data.get("intent_recognition", {})
    print(f"intent_recognition: {intent_recognition}", intent_recognition)
    print(type(intent_recognition))
    return {
        # "intent_pass": admission.get("is_pass"),
        # "intent_code": admission.get("intent_code"),
        # "intent_type": admission.get("intent_type"),
        # "intent_biz_code": admission.get("biz_code"),
        "need_clarification": intent_recognition.get("need_clarification"),
        "first_intent": intent_recognition.get("first_intent"),
        "first_intent_confidence": intent_recognition.get("intent_queue", [])[0].get("confidence") if intent_recognition.get("intent_queue") else "",
        # "intent_question": admission.get("highestPriorityQuestion"),
    }

def parse_slot_result(slot_result: str) -> dict:
    """
    解析slot_result，返回核心字段
    """
    data = json.loads(slot_result)
    return {
        "recognizeSlot": data.get("recognizeSlot"),
        "slotVerifySuccess": data.get("slotVerifySuccess"),
        "slotFailReason": data.get("slotFailReason"),
        "slotFailReasonData": data.get("slotFailReasonData"),
        "slotFinish": data.get("slotFinish"),
        "completedSlots": data.get("completedSlots"),
        "unfilledSlots": data.get("unfilledSlots"),
        "completionCondition": data.get("completionCondition"),
    }


    # 如果槽位recognizeSlot等于true，意图need_clarification=true，返回槽位老流程策略
    # 如果槽位recognizeSlot等于true，意图need_clarification=false，返回澄清策略
    # 如果槽位recognizeSlot等于false，意图need_clarification=true，返回槽位老流程策略
    # 如果槽位recognizeSlot等于false，意图need_clarification=false，返回意图新流程策略
def route_strategy(parsed_slot: dict, parsed_intent: dict) -> str:
    intent_type = None
    recognizeSlot = True  # 默认为true，当当前问题是槽位收集的流程
    need_clarification = True  # 默认为true，这样是不走意图识别

    # return新意图
    if parsed_intent is not None:
        if parsed_intent.get("need_clarification") is not True:
            need_clarification = False

    if parsed_slot is not None:
        if parsed_slot.get("recognizeSlot") != "True" and parsed_slot.get("recognizeSlot") != "true":
            recognizeSlot = False

    # 如果槽位检测不通过，返回fallback策略
    slot_finish = parsed_slot.get("slotFinish")
    slotFailReason = parsed_slot.get("slotFailReason")

    if parsed_intent is None or (recognizeSlot is True and need_clarification is True) or (
            recognizeSlot is False and need_clarification is True):
        # 如果槽位recognizeSlot等于true，意图need_clarification=true，返回槽位老流程策略
        # 如果槽位recognizeSlot等于false，意图need_clarification=true，返回槽位老流程策略
        if slot_finish == "false" and slotFailReason != "missingSlot":
            return "slot_clarify"

        if intent_type == "INFORMATIONAL":
            return "INFORMATIONAL"
        else:
            return "TRANSACTION"
    elif recognizeSlot is True and need_clarification is False:
        # 如果槽位recognizeSlot等于true，意图need_clarification=false
        # 满足以下规则，可以不用澄清，直接进入意图准入
        # 1. 如果当前识别的意图时系统意图
        if "INTENT_SYSTEM" in parsed_intent.get("first_intent"):
            return "intent_verify"
        if parsed_intent.get("first_intent_confidence") is not None:
            # 2. 如果当前识别的意图置信度小于0.7，继续老流程
            if parsed_intent.get("first_intent_confidence") is not None and parsed_intent.get(
                    "first_intent_confidence") != '' and parsed_intent.get("first_intent_confidence") < 0.7:
                if slot_finish == "false" and slotFailReason != "missingSlot":
                    return "slot_clarify"
                if intent_type == "INFORMATIONAL":
                    return "INFORMATIONAL"
                else:
                    return "TRANSACTION"

        # 否则，返回澄清策略
        # update_session_state(domain, token, channel_type, channel_user_id, "INTENT_CLARIFYING", "INTENT_SWITCH")
        return "intent_clarify"
    # elif recognizeSlot is False and need_clarification is True:
    # 如果槽位recognizeSlot等于false，意图need_clarification=true，返回槽位老流程策略
    elif recognizeSlot is False and need_clarification is False:
        # 如果槽位recognizeSlot等于false，意图need_clarification=false，返回意图新流程策略
        return "intent_clarify"
    return "INFORMATIONAL"

def get_mix_answer(slot_result: str, intent_result: str) -> str:
    # mix路由逻辑
    # 槽位识别有结果，意图识别无结果，继续老意图流程，返回slot_clarify、information、transaction
    # 槽位识别无结果，意图识别有结果，切换新意图流程，返回intent_verify
    # 槽位识别有结果，意图识别有结果，意图澄清由用户决策，返回intent_clarify
    # 槽位识别无结果，意图识别无结果，默认继续老流程，返回slot_clarify、information、transaction
    # intent_json = safe_json_parse(intent_result)
    parsed_intent = parse_intent_result(intent_result)
    parsed_slot = parse_slot_result(slot_result)
    strategy = route_strategy(parsed_slot, parsed_intent)
    return strategy

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


def process_single_question_orginal(idx, question, answers, answer_raws, need_clarifies, clarify_needs, total_questions):
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
        print(f"处理问题{idx + 1}/{total_questions}: {str(question)}")
        # 调用SLOT的workflow，获取SLOT的结果
        slot_answer= get_slot_answer(question)
        # 调用intent的workflow，获取intent的结果
        intent_answer = get_intent_answer(question)
        # 调用Mix Flow的逻辑，获取Mix Flow的结果
        print("调用Mix Flow")
        mix_answer = get_mix_answer(slot_answer, intent_answer)
        print(f"问题{idx + 1}的Mix Flow结果: {mix_answer}")
        print(f"index: {idx}")
        answers[idx] = mix_answer
        print(f"问题{idx + 1}的答案保存成功")
        return idx, True
    except Exception as e:
        logging.error(f"处理问题{idx + 1}时出错: {e}")
        answers[idx] = f"处理出错: {str(e)}"
        answer_raws[idx] = ""
        need_clarifies[idx] = False
        clarify_needs[idx] = f"处理出错: {str(e)}"
        return idx, False


# ... (其他函数保持不变)

# 修复后的 process_single_question 函数
def process_single_question(idx, question, answers, answer_raws, need_clarifies, clarify_needs, total_questions):
    """处理单个问题，新增2个结果列表（核心修改点）"""
    try:
        if pd.isna(question) or str(question).strip() == "":
            with file_lock:
                answers[idx] = ""
                answer_raws[idx] = ""
                need_clarifies[idx] = False
                clarify_needs[idx] = "问题为空，跳过处理"
            logging.info(f"问题{idx + 1}/{total_questions}为空，跳过")
            return idx, True

        logging.info(f"处理问题{idx + 1}/{total_questions}: {str(question)[:50]}...")
        print(f"处理问题{idx + 1}/{total_questions}: {str(question)}")

        slot_answer = get_slot_answer(question)
        intent_answer = get_intent_answer(question)
        print("调用Mix Flow")
        mix_answer = get_mix_answer(slot_answer, intent_answer)

        # NOTE: 由于 Mix Flow 的结果 (mix_answer) 只是一个路由策略字符串，
        # 实际的 JSON Raw Data 和 Clarification Need 是在 Mix Flow 内部逻辑中获取的。
        # 这里为了保持逻辑完整性（即赋值所有四个结果列表），我们进行如下赋值，
        # 如果需要将原始JSON和澄清需求传出，get_mix_answer 必须返回更多字段。

        print(f"问题{idx + 1}的Mix Flow结果: {mix_answer}")
        print(f"index: {idx}")

        # 确保在锁保护下，所有结果列表都在正确的索引处被赋值。
        with file_lock:
            # 成功获取 Mix Flow 结果
            answers[idx] = mix_answer
            answer_raws[idx] = ""  # 假设这里没有原始 JSON 返回
            need_clarifies[idx] = False  # 假设这里没有澄清需求信息
            clarify_needs[idx] = ""  # 假设这里没有澄清需求信息

        print(f"问题{idx + 1}的答案保存成功")
        return idx, True

    except Exception as e:
        logging.error(f"处理问题{idx + 1}时出错: {e}")
        # 确保在错误处理分支中，所有结果列表都在锁保护下被赋值。
        with file_lock:
            answers[idx] = f"处理出错: {str(e)}"
            answer_raws[idx] = ""
            need_clarifies[idx] = False
            clarify_needs[idx] = f"处理出错: {str(e)}"
        return idx, False

def process_csv_original(file_path, start_id=20, end_id=None, max_workers=5):
    """主处理函数，初始化新增的结果列表（核心修改点）"""
    # 读取CSV并校验必需列
    df = None
    try:
        df = pd.read_csv(file_path, encoding='gb18030', encoding_errors='ignore')
    except UnicodeDecodeError:
        print("❌ 错误：虽然检测结果是 UTF-8，但读取仍然失败。")
        print("💡 建议：尝试使用 encoding='utf-8' 和 errors='ignore' 忽略无法解码的字符。")
    except FileNotFoundError:
        print(f"❌ 错误：文件 {file_path} 未找到。")
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
    # total_to_process = 1
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

        try:
            final_df.to_csv(file_path, index=False, encoding='utf-8')
        except UnicodeDecodeError:
            print("❌ 错误：虽然检测结果是 UTF-8，但读取仍然失败。")
            print("💡 建议：尝试使用 encoding='utf-8' 和 errors='ignore' 忽略无法解码的字符。")
        except FileNotFoundError:
            print(f"❌ 错误：文件 {file_path} 未找到。")

        logging.info(f"处理完成！已保存ID={start_id}到ID={end_id - 1}的结果（含2个澄清相关字段）")


# 修复后的 process_csv 函数片段 (仅修改恢复逻辑)
def process_csv(file_path, start_id=20, end_id=None, max_workers=5):
    """主处理函数，初始化新增的结果列表（核心修改点）"""
    # 读取CSV并校验必需列
    df = None
    try:
        df = pd.read_csv(file_path, encoding='gb18030', encoding_errors='ignore')
    except UnicodeDecodeError:
        print("❌ 错误：虽然检测结果是 UTF-8，但读取仍然失败。")
        print("💡 建议：尝试使用 encoding='utf-8' 和 errors='ignore' 忽略无法解码的字符。")
    except FileNotFoundError:
        print(f"❌ 错误：文件 {file_path} 未找到。")
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
    total_questions = len(df)
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

                # --- 关键修复点：不再重新分配/重新赋值列表引用 ---
                # 而是迭代 temp_df 的数据，并用索引赋值的方式更新已初始化的列表内容。
                # 这样可以保持列表的引用不变，避免多线程错误。

                temp_answers = temp_df['Answer'].fillna("").tolist()
                temp_raws = temp_df['Answer_json'].fillna("").tolist()
                temp_need_clarifies = temp_df['need_clarification'].fillna(False).tolist()
                temp_clarify_needs = temp_df['explanation.clarification_need'].fillna("").tolist()

                # 仅用恢复的数据更新已初始化的列表，长度不超过 total_questions
                # 我们只需要更新，而不需要重新创建 answers, answer_raws 等变量
                for i in range(min(total_questions, len(temp_df))):
                    answers[i] = temp_answers[i]
                    answer_raws[i] = temp_raws[i]
                    need_clarifies[i] = temp_need_clarifies[i]
                    clarify_needs[i] = temp_clarify_needs[i]

                logging.info(f"从{latest_temp}恢复进度（含新增的2个澄清相关字段）")
            except Exception as e:
                logging.warning(f"恢复临时文件失败: {e}，将从指定ID开始")

    # 确定需要处理的索引范围
    process_indices = list(range(start_id, end_id))
    total_to_process = len(process_indices)
    # total_to_process = 1
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

        try:
            final_df.to_csv(file_path, index=False, encoding='utf-8')
        except UnicodeDecodeError:
            print("❌ 错误：虽然检测结果是 UTF-8，但读取仍然失败。")
            print("💡 建议：尝试使用 encoding='utf-8' 和 errors='ignore' 忽略无法解码的字符。")
        except FileNotFoundError:
            print(f"❌ 错误：文件 {file_path} 未找到。")

        logging.info(f"处理完成！已保存ID={start_id}到ID={end_id - 1}的结果（含2个澄清相关字段）")


if __name__ == "__main__":
    start_time = time.time()
    try:
        process_csv(
            file_path="slotOrIntent_第三个数据样本_Plan B_11.4.19.21 - 副本A.csv",  # 输入输出文件（需包含Question和Target Intent ID列）
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