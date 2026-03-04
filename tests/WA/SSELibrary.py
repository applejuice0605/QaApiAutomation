import sys
from sseclient import SSEClient
from requests import Session
from robot.api.deco import keyword
class SSELibrary:
    def __init__(self):
        self.session = Session()
        self.sse_client = None

    @keyword
    def open_event_stream(self, url, headers=None):
        """打开事件流连接"""
        if headers is None:
            headers = {}
        response = self.session.get(url, stream=True, headers=headers)
        self.sse_client = SSEClient(response)
        return "SSE Connection Established"

    @keyword
    def read_events(self, max_events=1, timeout=30):
        """读取指定数量的事件"""
        events = []
        try:
            for index, event in enumerate(self.sse_client):
                if index >= max_events:
                    break
                events.append({
                    "data": event.data,
                    "event": event.event,
                    "id": event.id,
                    "retry": event.retry
                })
        except Exception as e:
            raise Exception(f"读取事件失败: {str(e)}")
        return events

    @keyword
    def close_event_stream(self):
        """关闭事件流连接"""
        if self.sse_client:
            self.sse_client.resp.close()
            self.sse_client = None
            return "SSE Connection Closed"
        return "No active connection"