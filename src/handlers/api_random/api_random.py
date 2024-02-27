import json
from dataclasses import dataclass
from random import sample

from common.aws import create_client
from common.dataclasses import load_environment
from common.logger import create_logger, logging_function, logging_handler
from mypy_boto3_s3 import S3Client


@dataclass
class EnvironmentVariables:
    s3_bucket: str
    s3_key: str


logger = create_logger(__name__)


@logging_handler(logger)
def handler(_event, _context, client_s3: S3Client = create_client("s3")):
    env = load_environment(class_dataclass=EnvironmentVariables)
    hosts = get_hosts(bucket=env.s3_bucket, key=env.s3_key, client=client_s3)
    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
        },
        "body": json.dumps({"host": sample(hosts, 1)[0]}),
    }


@logging_function(logger)
def get_hosts(*, bucket: str, key: str, client: S3Client) -> list[str]:
    resp = client.get_object(Bucket=bucket, Key=key)
    return json.load(resp["Body"])
