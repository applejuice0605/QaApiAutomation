import requests
import json
from robot.api.deco import keyword


@keyword("Check Msg ID Match")
def check_msg_id_match(trace_id, target_key, expeceted_value):
    """
    通过API接口执行SQL查询，检查返回数据中特定key是否匹配给定的msg_id

    参数:
        msg_id (str/int): 要匹配的消息ID

    返回:
        tuple: (是否匹配的布尔值, 格式化后的数据字典/错误信息)
    """
    # API端点配置
    api_url = "https://rd-dms.fuseinsurtech.com/query/"
    sql_query = "select * from message.whatsapp_chat_record where trace_id = '" + trace_id + "' order by desc limit 10"
    print(sql_query)

    try:
        # 调用API执行SQL查询
        response = requests.post(
            api_url,
            headers={"cookie": "csrftoken=auML5dvwr0x0a14MmNeuoDc9U7d4nGKk2Mda778j802nE3lJYMM15u5dwmOx3HND; sessionid=0bqc3qc4umrvwusiki78urf0f23u8f61", "x-csrftoken":"auML5dvwr0x0a14MmNeuoDc9U7d4nGKk2Mda778j802nE3lJYMM15u5dwmOx3HND"},
            #建立一个字典
            data={"instance_name": "ID_UAT_CORE_MYSQL8.0", "db_name": "message", "schema_name": "null", "tb_name": "whatsapp_chat_record", "sql_content": sql_query},
            # data
            # data=json.dumps({
            #     "instance_name": "ID_UAT_CORE_MYSQL8.0",
            #     "db_name": "message",
            #     "schema_name": "null",
            #     "tb_name": "sms_record",
            #     "sql_content": sql_query
            # }),
            timeout=10
        )

        # 检查API响应是否成功
        response.raise_for_status()
        print(response.status_code)

        # 解析API返回的数据
        api_data = response.json().get("data")
        print(api_data)

        # 假设API返回的数据是一个包含记录的列表
        if not api_data or len(api_data) == 0:
            return (False, "未查询到数据")

        print("hello")
        column_list = api_data.get("column_list")
        print(column_list)
        column_value = api_data.get("rows")[0]
        print(column_value)

        result_dict = dict(zip(column_list, column_value))
        print(result_dict)

        if target_key in result_dict:
            print(result_dict[target_key])
            print(expeceted_value)
            is_match = str(result_dict[target_key]) == str(expeceted_value)
            return (is_match)
        else:
            return (False)

    except requests.exceptions.RequestException as e:
        print(f"API请求失败: {str(e)}")
        return (False)
    except json.JSONDecodeError:
        print("API返回的不是有效的JSON数据")
        return (False)
    except Exception as e:
        print(f"处理过程中发生错误: {str(e)}")
        return (False)


# 使用示例
if __name__ == "__main__":
    test_msg_id = "12345"
    is_match = check_msg_id_match("8619830441461", "reply_id", "quotation_form_new")

    print(f"匹配结果: {is_match}")