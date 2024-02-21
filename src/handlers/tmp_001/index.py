from dataclasses import dataclass
from time import sleep

from common.dataclasses import load_environment
from common.http import HttpGetOption, http_sec3_client
from common.logger import create_logger, logging_function, logging_handler
from mypy_boto3_dynamodb import DynamoDBClient


@dataclass(frozen=True)
class EnvironmentVariables:
    proxy_host: str
    proxy_port: str


logger = create_logger(__name__)
url = "https://ifconfig.io/ip"


@logging_handler(logger)
def handler(event, context):
    sleep(30)
    env = load_environment(class_dataclass=EnvironmentVariables)
    ip_without_proxy = request_without_proxy()
    ip_with_proxy = request_with_proxy(env=env)
    logger.info(
        "result", data={"with_proxy": ip_with_proxy, "without_proxy": ip_without_proxy}
    )


@logging_function(logger, with_return=True)
def request_without_proxy() -> str:
    option = HttpGetOption(url=url)
    resp = http_sec3_client(option)
    return resp.text.strip()


@logging_function(logger, with_return=True)
def request_with_proxy(*, env: EnvironmentVariables) -> str:
    proxy = f"socks5h://{env.proxy_host}:{env.proxy_port}"
    option = HttpGetOption(url=url, kwargs={"proxies": {"http": proxy, "https": proxy}})
    resp = http_sec3_client(option)
    return resp.text.strip()


class UserNotFoundError(Exception):
    pass


def tmp(client: DynamoDBClient, table_name, serialized):
    try:
        client.put_item(
            TableName=table_name,
            Item=serialized,
            ConditionExpression="attribute_exists(#user_id)",
            ExpressionAttributeNames={"#user_id": "user_id"},
        )
    except client.exceptions.ConditionalCheckFailedException:
        raise UserNotFoundError()
