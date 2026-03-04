from sseclient import SSEClient
from robot.api.deco import keyword

class SSECustom:
    @keyword
    def open_sse_stream(self, url):
        """打开 SSE 流"""
        return SSEClient(url)

    @keyword
    def read_sse_events(self, sse_client, max_events=1):
        """读取指定数量的事件"""
        events = []
        for event in sse_client:
            events.append(event.data)
            if len(events) >= max_events:
                break
        return events