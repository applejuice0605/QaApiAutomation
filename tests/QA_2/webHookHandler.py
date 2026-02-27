# 定义WebhookHandler，用于处理调用webhook相关的操作
import requests


class WebHookHandler:
    def __init__(self, bot, config):
        self.bot = bot
        self.config = config
        self.webhook_url = config['webhook_url']

    def request_webhook(self, msg_body):
        print("start request_webhook")
        """
        调用webhook发送文本消息
        """
        # https://pchat-uat.fuse.co.id/api/ai/chatbot/whatsapp/webhook

        url = f"{self.webhook_url.rstrip('/')}/api/ai/chatbot/whatsapp/webhook"
        headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                          "AppleWebKit/537.36 (KHTML, like Gecko) "
                          "Chrome/137.0.0.0 Safari/537.36",
            "content-type": "application/json",
        }
        # if type(msg_body) != str:
        #     query = str(msg_body)
        # user_input="reset session"

        # TODO：动态获取messgae from的wa_id, wa_token，business_account_id
        payload = {
            "object": "whatsapp_business_account",
            "entry": [
                {
                    "id": "1851481102271082",
                    "changes": [
                        {
                            "value": {
                                "messaging_product": "whatsapp",
                                "metadata": {
                                    "display_phone_number": "6285283239812",
                                    "phone_number_id": "539655932572544"
                                },
                                "contacts": [
                                    {
                                        "profile": {
                                            "name": "nora 2号"
                                        },
                                        "wa_id": "8619830441461"
                                    }
                                ],
                                "messages": [
                                    msg_body
                                ]
                            },
                            "field": "messages"
                        }
                    ]
                }
            ]
        }

        try:
            resp = requests.post(url, headers=headers, json=payload, stream=True)
            # print(resp)
            # resp.raise_for_status()
            # print(resp.text)

        except requests.RequestException as e:
            print(f"Error calling webhook: {e}")
            if hasattr(e, 'response') and e.response:
                print(f"Response status: {e.response.status_code}")
                print(f"Response body: {e.response.text}")
            return None

        return resp.text