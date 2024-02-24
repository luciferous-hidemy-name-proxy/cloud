import json
from dataclasses import asdict, dataclass
from datetime import datetime, timedelta, timezone
from urllib.request import urlopen
from uuid import uuid4

from common.aws import create_client, create_resource
from common.dataclasses import load_environment
from common.logger import create_logger, logging_function, logging_handler
from common.models import DynamoDBTempData
from mypy_boto3_dynamodb import DynamoDBServiceResource
from mypy_boto3_dynamodb.service_resource import Table
from mypy_boto3_ssm import SSMClient


@dataclass
class EnvironmentVariables:
    ssm_parameter_name_code_hidemy_name: str
    table_name_temp_store: str


logger = create_logger(__name__)


@logging_handler(logger)
def handler(
    event,
    context,
    client_ssm: SSMClient = create_client("ssm"),
    resource_dynamodb: DynamoDBServiceResource = create_resource("dynamodb"),
):
    env = load_environment(class_dataclass=EnvironmentVariables)
    code = get_code(name=env.ssm_parameter_name_code_hidemy_name, client=client_ssm)
    resp = call_api(code=code)
    hosts = convert_response(resp=resp)
    put_items(
        items=hosts, table_name=env.table_name_temp_store, resource=resource_dynamodb
    )


@logging_function(logger)
def get_code(*, name: str, client: SSMClient) -> str:
    resp = client.get_parameter(Name=name, WithDecryption=True)
    return resp["Parameter"]["Value"]


@logging_function(logger)
def call_api(*, code: str) -> list[dict]:
    resp = urlopen(
        f"http://proxylist.justapi.info/api/proxylist.php?code={code}&out=js&type=5&anon=4"
    )
    return json.load(resp)


@logging_function(logger)
def convert_response(*, resp: list[dict]) -> list[str]:
    return [f"{x['host']}:{x['port']}" for x in resp]


@logging_function(logger)
def put_items(*, items: list[str], table_name: str, resource: DynamoDBServiceResource):
    table: Table = resource.Table(table_name)

    dt_ttl = datetime.now(tz=timezone.utc) + timedelta(days=3)
    ttl = int(dt_ttl.timestamp())

    v_uuid = str(uuid4())

    converted_items = [
        DynamoDBTempData(
            uuid=v_uuid, host=host, ttl=ttl, checked=False, force_check=False
        )
        for host in set(items)
    ]

    with table.batch_writer() as batch:
        for x in converted_items:
            batch.put_item(Item=asdict(x))
