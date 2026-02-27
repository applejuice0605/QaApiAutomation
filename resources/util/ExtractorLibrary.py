import json
from tabnanny import check
from robot.api.deco import keyword

class ExtractorLibrary:
    """
    一个用于从复杂的数据库/API响应中提取特定数据的自定义库。
    """
    
    def __init__(self):
        # 初始化，如果需要的话
        pass

    @keyword("Get Comparison Code")
    def get_comparison_code(self, db_check_result):
        """
        从 DB 结果(conversation_metadata)中提取 comparison_code
        """
        if not isinstance(db_check_result, dict):
            # 简单处理非字典输入
            return None

        waUserRes = db_check_result.get('whatsapp').get('waUserRes')
        print(waUserRes)
        # 示例提取逻辑：假设 Code 位于 'payload' -> 'metadata' -> 'comparison_code'
        try:
            # 确保输入是 JSON 字符串时先解析
            print("开始解析")
            # 如果waUserRes长度<1，说明没有给用户返回内容
            if len(waUserRes) < 1:  
                return None
            
            # 从 whatsapp_data 中用SUBSTRING_INDEX 提取 comparison_code，提取第一个comparison_code=之后的内容
            comparison_code = waUserRes[0].get('template', {}).get('components', [{}])[1].get('parameters', [{}])[0].get('text', '').split('comparison_code=')[1].split(' ')[0]
            # 提取第一个&之前的内容
            comparison_code = comparison_code.split('&')[0]
            print(comparison_code)

            return comparison_code
        except (KeyError, TypeError):
            # 提取失败，返回 None
            return None

    
    # 您可以添加更多的提取方法，例如：
    @keyword("Get BizCode")
    def get_biz_code(self, db_check_result):
        """
        从 DB 结果中提取 biz_code
        """
        if not isinstance(db_check_result, dict):
            # 简单处理非字典输入
            return None
        
        biz_code = db_check_result.get('markInfo').get('intentCode')

        return biz_code

# 生成单元测试
if __name__ == "__main__":
    # 假设 db_check_result 是一个示例输入
    db_check_result = {
        "whatsapp": {
            "waHttpRes": [
                {
                    "messaging_product": "whatsapp",
                    "contacts": [
                        {
                            "input": "8619830441461",
                            "wa_id": "8619830441461"
                        }
                    ],
                    "messages": [
                        {
                            "id": "wamid.HBgNODYxOTgzMDQ0MTQ2MRUCABEYEkE3RDdDNkZCOEU2MTVGNjJGOAA=",
                            "message_status": "accepted"
                        }
                    ]
                },
                {
                    "messaging_product": "whatsapp",
                    "contacts": [
                        {
                            "input": "8619830441461",
                            "wa_id": "8619830441461"
                        }
                    ],
                    "messages": [
                        {
                            "id": "wamid.HBgNODYxOTgzMDQ0MTQ2MRUCABEYEjcxRkY4QjRGMTkxNTRDNDJERgA="
                        }
                    ]
                }
            ],
            "waUserReq": {
                "context": {
                    "from": "6285283239812",
                    "id": "wamid.HBgNODYxOTgzMDQ0MTQ2MRUCABEYEjc3QUQ5QUQ4NzcyNDY3NTM4NwA="
                },
                "interactive": {
                    "nfm_reply": {
                        "name": "flow",
                        "response_json": {
                            "brandCode": "TOYOTA",
                            "vehicleManufactureYear": "2022",
                            "brandModelCode": "ALL NEW KIJANG INNOVA",
                            "brandSeriesCode": "2.0 G A/T BENSIN",
                            "vehicleType": "MINIBUS",
                            "vehicleTypeCode": "MINIBUS",
                            "carPriceShow": "376,200,000",
                            "coveragePeriod": "1",
                            "coverageType": "PBP_100020",
                            "plateCode": "B",
                            "vehicleUsage": "2",
                            "productCategoryWithDisplayCategoryId": "car#49",
                            "flow_token": "QUICK_QUOTE:8619830441461:90519a6d16ac4d36bdc2bffff7f0d511"
                        },
                        "body": "Sent"
                    },
                    "type": "nfm_reply"
                },
                "from": "8619830441461",
                "id": "wamid.HBgNODYxOTgzMDQ0MTQ2MRUCABIYIEFDMTMxQjNEMTY3REM3NTE1QzUxQUI5OTlGMjBCRjUzAA==",
                "type": "interactive",
                "timestamp": "1763452163"
            },
            "waUserRes": [
                {
                    "messaging_product": "whatsapp",
                    "recipient_type": "individual",
                    "template": {
                        "components": [
                            {
                                "parameters": [
                                    {
                                        "text": "RAMAYANA CAR COMPREHENSIVE",
                                        "type": "text"
                                    },
                                    {
                                        "text": "8,474,260",
                                        "type": "text"
                                    },
                                    {
                                        "text": "2,953,741",
                                        "type": "text"
                                    },
                                    {
                                        "text": "SIMAS BASIC LIVE PHOTO - COMPREHENSIVE",
                                        "type": "text"
                                    },
                                    {
                                        "text": "8,439,260",
                                        "type": "text"
                                    },
                                    {
                                        "text": "2,953,741",
                                        "type": "text"
                                    },
                                    {
                                        "text": " SIMAS BASIC - COMPREHENSIVE",
                                        "type": "text"
                                    },
                                    {
                                        "text": "8,439,260",
                                        "type": "text"
                                    },
                                    {
                                        "text": "2,953,741",
                                        "type": "text"
                                    }
                                ],
                                "type": "body"
                            },
                            {
                                "index": "1",
                                "parameters": [
                                    {
                                        "text": "49/1?x-wa-temp-token=eyJhbGciOiJIUzI1NiIsInppcCI6IkRFRiJ9.eNpEjMsOgjAQRf-la0hmSinFtcRojC6ERJZQhoiP0vCIRuO_O2HjXZ577_mIca7FSthLNeX08Hl_IycC4athcjQcPbltw_1encvNLpKHLDPlmgd8cI7uxUjDMjAaUxOBUqg0cl9371M_D5a4e7J8rLz_e4uOPwgAWktYkqg0EPTyjBMdIypQEIiumhYgYykXcJ06FkppoW4lhG2sk1A1cRSmLAqtMTbRSIjQiO8PAAD__w.bPYlpagV_twIosMYzAQCiChvo-tzyjgrI__pSIofq-o&comparison_code=C-1990688784058494977&lan=id&utm_source=wa&region=ID&bizCode=INTENT_QUOTE_COMPARISON_1990655410950451202",
                                        "type": "text"
                                    }
                                ],
                                "sub_type": "url",
                                "type": "button"
                            }
                        ],
                        "language": {
                            "code": "id"
                        },
                        "name": "original_recommend_plan_3"
                    },
                    "to": "8619830441461",
                    "type": "template"
                },
                {
                    "messaging_product": "whatsapp",
                    "recipient_type": "individual",
                    "text": {
                        "body": "Catatan dari Fina:1. Foto Kamera: Pengambilan foto mobil secara langsung melalui kamera handphone, bukan mengunggah dari galeri (wajib untuk plan dengan Foto Kamera)2. Pendapatan di atas hanya estimasi & belum dipotong pajak.3. Premi belum termasuk diskon.4. Premi dapat berbeda tergantung pada pilihan manfaat asuransi."
                    },
                    "to": "8619830441461",
                    "type": "text"
                }
            ]
        },
        "markInfo": {
            "intentCode": "INTENT_QUOTE_COMPARISON_1990655410950451202",
            "sessionId": "SN00R9ZJ9XJ00000000BG",
            "isContactCS": False
        },
        "dify": {
            
        },
        "remark": "convert messageId:newCommissionCompareMessageV2;;;convert messageId:commissionCompareMessageV2Conditions;;;bizCode:INTENT_QUOTE_COMPARISON_1990655410950451202;;;traceId:3e60c564d30d6ca8",
        "timeCost": {
            "reqStartTime": 1763452164592,
            "reqEndTime": 1763452167804,
            "totalCost": 3212
        }
    }
    extractor = ExtractorLibrary()
    comparison_code = extractor.get_comparison_code(db_check_result)
    print(comparison_code)