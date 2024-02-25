import json
from dataclasses import dataclass, field
from pathlib import Path
from typing import TypedDict
from uuid import uuid4

import boto3
import pytest
from mypy_boto3_dynamodb import DynamoDBClient, DynamoDBServiceResource
from pytest import MonkeyPatch


@dataclass(frozen=True)
class DummyLambdaContext:
    aws_request_id: str = field(default_factory=lambda: str(uuid4()))
    function_name: str = field(default_factory=lambda: str(uuid4()))
    memory_limit_in_mb: int = field(default=128)
    invoked_function_arn: str = field(default_factory=lambda: str(uuid4()))


class FixtureOptionDynamoDB(TypedDict):
    name: str
    items: list[dict]


LOCAL_STACK_ENDPOINT_URL = "http://localhost:4566"


@pytest.fixture(scope="session")
def dummy_lambda_context():
    return DummyLambdaContext()


@pytest.fixture(scope="session")
def resource_ddb() -> DynamoDBServiceResource:
    return boto3.resource("dynamodb", endpoint_url=LOCAL_STACK_ENDPOINT_URL)


@pytest.fixture(scope="session")
def client_ddb() -> DynamoDBClient:
    return boto3.client("dynamodb", endpoint_url=LOCAL_STACK_ENDPOINT_URL)


@pytest.fixture(scope="session")
def path_test_root() -> Path:
    return Path(__file__).parent


@pytest.fixture(scope="function")
def set_environ(request, monkeypatch: MonkeyPatch):
    param: dict = request.param

    for k, v in param.items():
        monkeypatch.setenv(k, v)


@pytest.fixture(scope="function")
def json_inputs(request, path_test_root) -> list:
    def load_file(file_name: str):
        with open(path_test_root.joinpath(f"fixtures/json_inputs/{file_name}")) as f:
            return json.load(f)

    names: list[str] = request.param
    return [load_file(x) for x in names]


@pytest.fixture(scope="function")
def dynamodb(
    request, path_test_root, client_ddb, resource_ddb
) -> DynamoDBServiceResource:
    def load_definition(name: str) -> dict:
        with open(
            path_test_root.joinpath(f"fixtures/dynamodb/{name}/definition.json")
        ) as f:
            return json.load(f)

    param: list[FixtureOptionDynamoDB] = request.param

    for option in param:
        definition = load_definition(option["name"])
        client_ddb.create_table(**definition)
        items = option.get("items")
        if items is None:
            items = []
        table = resource_ddb.Table(option["name"])
        with table.batch_writer() as batch:
            for x in items:
                batch.put_item(Item=x)

    yield resource_ddb

    for option in param:
        client_ddb.delete_table(TableName=option["name"])
