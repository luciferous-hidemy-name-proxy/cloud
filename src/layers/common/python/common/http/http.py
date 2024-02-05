from dataclasses import dataclass, field
from datetime import datetime
from time import sleep
from typing import Callable

import requests
from requests import Response


@dataclass
class HttpGetOption:
    url: str
    kwargs: dict = field(default_factory=dict)


def create_http_get_client(interval_sec: int) -> Callable[[HttpGetOption], Response]:
    dt_prev = datetime.now()

    def process(option: HttpGetOption) -> Response:
        nonlocal dt_prev

        delta = datetime.now() - dt_prev
        duration = delta.total_seconds() - interval_sec
        if duration > 0:
            sleep(duration)

        try:
            return requests.get(option.url, **option.kwargs)
        finally:
            dt_prev = datetime.now()

    return process
