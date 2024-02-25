from dataclasses import dataclass

from aws_lambda_powertools.utilities.data_classes import SQSEvent, event_source
from aws_lambda_powertools.utilities.data_classes.sqs_event import SQSRecord
from common.aws import create_resource
from common.logger import create_logger, logging_function, logging_handler
from mypy_boto3_dynamodb.service_resource import DynamoDBServiceResource, Table
from mypy_boto3_dynamodb.type_defs import UpdateItemOutputTableTypeDef
from requests import get as http_get


@dataclass(frozen=True)
class ParsedEvent:
    uuid: str
    host: str
    table_name: str


logger = create_logger(__name__)


@logging_handler(logger)
@event_source(data_class=SQSEvent)
def handler(
    event: SQSEvent,
    context,
    resource_ddb: DynamoDBServiceResource = create_resource("dynamodb"),
):
    pe = parse_event(event=event)
    flag = check_proxy(host=pe.host)
    update_item(pe=pe, flag=flag, resource=resource_ddb)


@logging_function(logger)
def parse_event(*, event: SQSEvent) -> ParsedEvent:
    def load_event() -> SQSRecord:
        for x in event.records:
            return x
        raise ValueError("unreached: parse_event() -> load_event()")

    record = load_event()
    data = record.json_body
    return ParsedEvent(
        uuid=data["dynamodb"]["Keys"]["uuid"]["S"],
        host=data["dynamodb"]["Keys"]["host"]["S"],
        table_name=data["eventSourceARN"].split("/")[1],
    )


@logging_function(logger)
def check_proxy(*, host: str) -> bool:
    proxy = f"socks5h://{host}"
    try:
        resp = http_get(
            url="https://ifconfig.io/ip",
            proxies={"http": proxy, "https": proxy},
            timeout=(15, 150),
        )
        return resp.status_code == 200
    except Exception:
        logger.debug("error occurred in check proxy", exc_info=True)
        return False


@logging_function(logger)
def update_item(
    *, pe: ParsedEvent, flag: bool, resource: DynamoDBServiceResource
) -> UpdateItemOutputTableTypeDef:
    table: Table = resource.Table(pe.table_name)

    return table.update_item(
        Key={"uuid": pe.uuid, "host": pe.host},
        UpdateExpression="set #checked = :checked, #available = :available, #force_check = :force_check",
        ExpressionAttributeNames={
            "#checked": "checked",
            "#available": "available",
            "#force_check": "force_check",
        },
        ExpressionAttributeValues={
            ":checked": True,
            ":available": flag,
            ":force_check": False,
        },
        ReturnValues="ALL_NEW",
    )
