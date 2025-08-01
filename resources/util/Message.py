#定义一个消息类型，消息属性有类型type, 不同消息的模板，消息的具体内容；需要定义一个方法用于获取指定消息类型的完整的消息体，入参是消息的内容和类型，通过类型获取对应的模板，并把内容拼接到模板中，获取到完整的消息体，并返回from typing import Dict
import json
import string
from robot.api.deco import keyword
# 定义消息模板（可按需扩展）
MESSAGE_TEMPLATES = {
    "text": '{"from":"8619830441461","id":"wamid.HBgNODYxOTgzMDQ0MTQ2MRUCABIYIDdFM0M5QUM4NzAxQ0ZCM0I1QkZFRkYyODNGOEEwNkU5AA==","timestamp":"1751018237","text":{"body":"{content}"},"type":"text"}',
    "interactive_flow": '{"context":{"from":"6285283239812","id":"wamid.HBgNODYxOTgzMDQ0MTQ2MRUCABEYEjZDMEM2RDA1RTI2NUJGRDQ0NQA="},"from":"8619830441461","id":"wamid.HBgNODYxOTgzMDQ0MTQ2MRUCABIYIDQ5RjNDQkU5NDdCMUEyMjI3RDg1M0Y3ODE4RTNFNTkwAA==","timestamp":"1751265435","type":"interactive","interactive":{"type":"nfm_reply","nfm_reply":{"response_json":"{content}","body":"Sent","name":"flow"}}}',
    "interactive_button": '{"context":{"from":"6285283239812","id":"wamid.HBgNODYxOTgzMDQ0MTQ2MRUCABEYEkQyNEVGODA4RDAyNEI4QTk1RgA="},"from":"8619830441461","id":"wamid.HBgNODYxOTgzMDQ0MTQ2MRUCABIYIEI5NzZBRjk3MzgyNEUxNUI4NDJBMTg4RDNGNTlCRThDAA==","timestamp":"1751277600","type":"interactive","interactive":{"type":"button_reply","button_reply":{}}}',
    "document": '{"from":"8619830441461","id":"wamid.HBgNODYxOTgzMDQ0MTQ2MRUCABIYIDNEMTFFNUQzOTQyQTc2QzA2NEE1Rjc4RjFGQjA0NjJEAA==","timestamp":"1751279391","type":"image","image":{}}',
    "default": "消息：{content}",
    "text_v2": '{"from":"{from_wa}","id":"{id}","timestamp":"{timestamp}","text":{"body":"{content}"},"type":"text"}'
}

# text消息的context格式要求：str
# interactive_flow消息的context格式要求：dict



def get_msg_body_byType(type, content) -> str:
    """根据类型获取模板，并填充内容生成完整消息"""
    template = MESSAGE_TEMPLATES[type]
    print(template)
    return template.format(content=content)

@keyword("Get Test Msg Body")
def get_test_msg_body(content, from_wa=None, id=None, timestamp=None):
    template = {
        "from": "8619830441461",
        "id": "wamid.HBgNODYxOTgzMDQ0MTQ2MRUCABIYIDdFM0M5QUM4NzAxQ0ZCM0I1QkZFRkYyODNGOEEwNkU5AA==",
        "timestamp": "1751018237",
        "text": {
            "body": "Quote"
        },
        "type": "text"
    }

    if content:
        template["text"]["body"] = content
    if  from_wa:
        template["from"] = from_wa
    if id:
        template["id"] = id
    if timestamp:
        template["timestamp"] = timestamp

    return json.dumps(template, ensure_ascii=False)  # 返回 JSON 字符串

@keyword("Get Flow Msg Body")
def get_flow_msg_body(content, from_wa=None, id=None, timestamp=None):
    template = {
        "context": {
            "from": "6285283239812",
            "id": "wamid.HBgNODYxOTgzMDQ0MTQ2MRUCABEYEjZDMEM2RDA1RTI2NUJGRDQ0NQA="
        },
        "from": "8619830441461",
        "id": "wamid.HBgNODYxOTgzMDQ0MTQ2MRUCABIYIDQ5RjNDQkU5NDdCMUEyMjI3RDg1M0Y3ODE4RTNFNTkwAA==",
        "timestamp": "1751265435",
        "type": "interactive",
        "interactive": {
            "type": "nfm_reply",
            "nfm_reply": {
                "response_json": "{\\\"brandCode\\\":\\\"TOYOTA\\\",\\\"vehicleManufactureYear\\\":\\\"2022\\\",\\\"brandModelCode\\\":\\\"ALL NEW KIJANG INNOVA\\\",\\\"brandSeriesCode\\\":\\\"2.0 G A\\/T BENSIN\\\",\\\"vehicleType\\\":\\\"MINIBUS\\\",\\\"vehicleTypeCode\\\":\\\"MINIBUS\\\",\\\"carPriceShow\\\":\\\"376,200,000\\\",\\\"coveragePeriod\\\":\\\"1\\\",\\\"plateCode\\\":\\\"B\\\",\\\"vehicleUsage\\\":\\\"2\\\",\\\"flow_token\\\":\\\"QUICK_QUOTE:8619830441461:25550e154d404cae9da8ab1abbbf7e82\\\"}",
                "body": "Sent",
                "name": "flow"
            }
        }
    }
    # todo: 对content加上json格式校验
    if content:
        template["interactive"]["nfm_reply"]["response_json"] = content
    if  from_wa:
        template["from"] = from_wa
    if id:
        template["id"] = id
    if timestamp:
        template["timestamp"] = timestamp

    return json.dumps(template, ensure_ascii=False)  # 返回 JSON 字符串

@keyword("Get Button Msg Body")
def get_button_msg_body(content, from_wa=None, id=None, timestamp=None):
    template = {
        "context": {
            "from": "6285283239812",
            "id": "wamid.HBgNODYxOTgzMDQ0MTQ2MRUCABEYEjJDQjQzNDg2RkFEMzRCNDNGMwA="
        },
        "from": "8619830441461",
        "id": "wamid.HBgNODYxOTgzMDQ0MTQ2MRUCABIYIDhFRDU4MjIzQjkwRkM2NkRFMUU5NjdFRTk3NDExNDYzAA==",
        "timestamp": "1751278203",
        "type": "interactive",
        "interactive": {
            "type": "button_reply",
            "button_reply": {
                "id": "MP_00003",
                "c": "Plan A"
            }
        }
    }

    if content:
        template["interactive"]["button_reply"] = content
    if  from_wa:
        template["from"] = from_wa
    if id:
        template["id"] = id
    if timestamp:
        template["timestamp"] = timestamp

    return json.dumps(template, ensure_ascii=False)  # 返回 JSON 字符串

@keyword("Get Document Msg Body")
def get_document_msg_body(doucmentMediaId, from_wa=None, id=None, timestamp=None):
    template = {
        "from": "8619830441461",
        "id": "wamid.HBgNODYxOTgzMDQ0MTQ2MRUCABIYIDNEMTFFNUQzOTQyQTc2QzA2NEE1Rjc4RjFGQjA0NjJEAA==",
        "timestamp": "1751279391",
        "type": "image",
        "image": {
            "mime_type": "image/jpeg",
            "sha256": "xUwnlAo9RXb24KRrInXJQeHZg2gdGxNxqiokU4I8PRo=",
            "id": "699509946392104"
        }
    }

    if doucmentMediaId:
        template["image"]["id"] = doucmentMediaId
    if  from_wa:
        template["from"] = from_wa
    if id:
        template["id"] = id
    if timestamp:
        template["timestamp"] = timestamp

    return json.dumps(template, ensure_ascii=False)  # 返回 JSON 字符串

@keyword("Get Msg Body")
def get_msg_body(type, content=None, buttonId=None, buttonTitle=None, doucmentMediaId=None, from_wa=None, id=None, timestamp=None) -> str:
    if type == "text":
        return get_test_msg_body(content=content)
    elif type == "flow":
        return get_flow_msg_body(content=content)
    elif type == "button":
        return get_button_msg_body(content=content)
    elif type == "document":
        return get_document_msg_body(doucmentMediaId=doucmentMediaId)
    else:
        return "Undefined message type"



if __name__ == "__main__":
    # print(Message.get_msg_body_byType("text", "8619830441461"))
    # print("______________________________________")
    # print(Message.get_text_msg_body("text_v2", "你好", from_wa="8619830441461", id="wamid.HBgNODYxOTgzMDQ0MTQ2MRUCABIYIDdFM0M5QUM4NzAxQ0ZCM0I1QkZFRkYyODNGOEEwNkU5AA==", timestamp="1751277600"))
    # print("______________________________________")
    print(get_test_msg_body(content="你好"))

