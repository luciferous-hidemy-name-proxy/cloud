from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from typing import Iterable, Optional
from uuid import uuid4


@dataclass
class DynamoDBTempData:
    uuid: str
    host: str
    ttl: int
    checked: bool
    available: Optional[bool]
    force_check: bool

    @staticmethod
    def from_iter(*, hosts: Iterable[str]) -> Iterable[DynamoDBTempData]:
        v_uuid = str(uuid4())
        dt_ttl = datetime.now(tz=timezone.utc) + timedelta(days=4)
        ttl = int(dt_ttl.timestamp())

        for x in hosts:
            yield DynamoDBTempData(
                uuid=v_uuid,
                host=x,
                ttl=ttl,
                checked=False,
                available=None,
                force_check=False,
            )
