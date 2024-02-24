from dataclasses import dataclass


@dataclass
class DynamoDBTempData:
    uuid: str
    host: str
    ttl: int
    checked: bool
    force_check: bool
