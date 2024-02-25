from dataclasses import dataclass

from aws_lambda_powertools.utilities.data_classes import SQSEvent, event_source
from common.logger import create_logger, logging_handler


@dataclass(frozen=True)
class ParsedEvent:
    uuid: str
    host: str
    table_name: str


logger = create_logger(__name__)


@logging_handler(logger)
@event_source(data_class=SQSEvent)
def handler(event: dict, context):
    pass
