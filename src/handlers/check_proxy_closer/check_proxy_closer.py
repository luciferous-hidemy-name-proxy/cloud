import json
from dataclasses import dataclass
from enum import Enum
from hashlib import sha3_224

from aws_lambda_powertools.utilities.data_classes import event_source
from aws_lambda_powertools.utilities.data_classes.sqs_event import SQSEvent
from boto3.dynamodb.conditions import Key
from common.aws import create_client, create_resource
from common.dataclasses import load_environment
from common.logger import create_logger, logging_function, logging_handler
from mypy_boto3_dynamodb.service_resource import DynamoDBServiceResource, Table
from mypy_boto3_dynamodb.type_defs import QueryInputTableQueryTypeDef
from mypy_boto3_s3 import S3Client
from mypy_boto3_sqs import SQSClient


@dataclass(frozen=True)
class EnvironmentVariables:
    s3_bucket: str
    s3_key: str
    dynamodb_table: str
    sqs_queue_url: str


@dataclass
class Item:
    host: str
    checked: bool
    available: bool
    force_check: bool


class ProcessType(Enum):
    Uncompleted = 1
    ForceCheck = 2
    Completed = 3


@dataclass
class ProcessInfo:
    type: ProcessType
    hosts: set[str]


logger = create_logger(__name__)


@logging_handler(logger)
@event_source(data_class=SQSEvent)
def handler(
    event: SQSEvent,
    context,
    resource_dynamodb: DynamoDBServiceResource = create_resource("dynamodb"),
    client_sqs: SQSClient = create_client("sqs"),
    client_s3: S3Client = create_client("s3"),
):
    env = load_environment(class_dataclass=EnvironmentVariables)
    pe = parse_event(event=event)
    table = resource_dynamodb.Table(env.dynamodb_table)
    for uuid, hosts in pe.items():
        process(
            uuid=uuid,
            data_inputs=hosts,
            env=env,
            table=table,
            client_sqs=client_sqs,
            client_s3=client_s3,
        )


@logging_function(logger)
def parse_event(*, event: SQSEvent) -> dict[str, dict[str, str]]:
    result = {}

    for record in event.records:
        data = record.json_body
        uuid = data["dynamodb"]["Keys"]["uuid"]["S"]
        host = data["dynamodb"]["Keys"]["host"]["S"]
        node = result.get(uuid, {})
        node[host] = record.body
        result[uuid] = node

    return result


@logging_function(logger)
def query(*, uuid: str, table: Table) -> list[Item]:
    result = []
    is_first = True
    token = None
    while token is not None or is_first:
        if is_first:
            is_first = False
        option: QueryInputTableQueryTypeDef = {
            "KeyConditionExpression": Key("uuid").eq(uuid),
            "ProjectionExpression": "#host, #checked, #available, #force_check",
            "ExpressionAttributeNames": {
                "#host": "host",
                "#checked": "checked",
                "#available": "available",
                "#force_check": "force_check",
            },
        }
        if token is not None:
            option["ExclusiveStartKey"] = token
        resp = table.query(**option)
        result += [Item(**x) for x in resp.get("Items", [])]
        token = resp.get("LastEvaluatedKey")

    return result


@logging_function(logger)
def analyze(*, items: list[Item]) -> ProcessInfo:
    hosts_available = set()
    hosts_force_check = set()
    flag_completed = True

    for item in items:
        if item.available:
            hosts_available.add(item.host)
        if item.force_check:
            hosts_force_check.add(item.host)
        if not item.checked:
            flag_completed = False

    if len(hosts_force_check) > 0:
        return ProcessInfo(type=ProcessType.ForceCheck, hosts=hosts_force_check)
    elif flag_completed:
        return ProcessInfo(type=ProcessType.Completed, hosts=hosts_available)
    else:
        return ProcessInfo(type=ProcessType.Uncompleted, hosts=set())


@logging_function(logger)
def send_messages(*, queue_url: str, data_inputs: dict[str, str], client: SQSClient):
    length = len(data_inputs)
    mapping_inputs = {sha3_224(k.encode()): v for k, v in data_inputs.items()}
    union_succeeded = set()
    while len(union_succeeded) != length:
        entries = []
        for k, v in mapping_inputs.items():
            if len(entries) == 10:
                break
            if k in union_succeeded:
                continue
            entries.append({"Id": k, "MessageBody": v})
        resp = client.send_message_batch(QueueUrl=queue_url, Entries=entries)
        union_succeeded |= set([x["Id"] for x in resp.get("Successful", [])])


@logging_function(logger)
def put_available_hosts(*, bucket: str, key: str, hosts: list[str], client: S3Client):
    client.put_object(
        Bucket=bucket, Key=key, Body=json.dumps(hosts, ensure_ascii=False)
    )


@logging_function(logger)
def process(
    *,
    uuid: str,
    data_inputs: dict[str, str],
    env: EnvironmentVariables,
    table: Table,
    client_sqs: SQSClient,
    client_s3: S3Client
):
    items = query(uuid=uuid, table=table)
    process_info = analyze(items=items)
    if process_info.type == ProcessType.ForceCheck:
        send_messages(
            queue_url=env.sqs_queue_url,
            data_inputs={
                k: v for k, v in data_inputs.items() if k in process_info.hosts
            },
            client=client_sqs,
        )
    elif process_info.type == ProcessType.Completed:
        put_available_hosts(
            bucket=env.s3_bucket,
            key=env.s3_key,
            hosts=list(process_info.hosts),
            client=client_s3,
        )
