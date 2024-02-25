from dataclasses import asdict

import check_proxy_checker.check_proxy_checker as index
import pytest
from aws_lambda_powertools.utilities.data_classes import SQSEvent
from common.models import DynamoDBTempData


class TestParseEvent:
    @pytest.mark.parametrize(
        "json_inputs, expected",
        [
            (
                ["sqs_event_sample_001.json"],
                index.ParsedEvent(
                    uuid="6d2f525b-40f2-4b90-8018-1c064a123027",
                    host="184.178.172.18:15280",
                    table_name="temp_store",
                ),
            ),
            (
                ["sqs_event_sample_002.json"],
                index.ParsedEvent(
                    uuid="6d2f525b-40f2-4b90-8018-1c064a123027",
                    host="176.99.2.43:1080",
                    table_name="temp_store",
                ),
            ),
        ],
        indirect=["json_inputs"],
    )
    def test_normal(self, json_inputs, expected):
        event = SQSEvent(json_inputs[0])
        actual = index.parse_event(event=event)
        assert actual == expected


class TestUpdateItem:
    @pytest.mark.parametrize(
        "dynamodb, option, expected",
        [
            (
                [
                    {
                        "name": "temp_store",
                        "items": [
                            asdict(
                                DynamoDBTempData(
                                    uuid="temp",
                                    host="192,168.0.1",
                                    ttl=1223334444,
                                    checked=False,
                                    available=False,
                                    force_check=True,
                                )
                            )
                        ],
                    }
                ],
                {
                    "pe": index.ParsedEvent(
                        uuid="temp", host="192,168.0.1", table_name="temp_store"
                    ),
                    "flag": False,
                },
                asdict(
                    DynamoDBTempData(
                        uuid="temp",
                        host="192,168.0.1",
                        ttl=1223334444,
                        checked=True,
                        available=False,
                        force_check=False,
                    )
                ),
            ),
            (
                [
                    {
                        "name": "temp_store",
                        "items": [
                            asdict(
                                DynamoDBTempData(
                                    uuid="temp",
                                    host="192,168.0.1",
                                    ttl=1223334444,
                                    checked=False,
                                    available=False,
                                    force_check=False,
                                )
                            )
                        ],
                    }
                ],
                {
                    "pe": index.ParsedEvent(
                        uuid="temp", host="192,168.0.1", table_name="temp_store"
                    ),
                    "flag": True,
                },
                asdict(
                    DynamoDBTempData(
                        uuid="temp",
                        host="192,168.0.1",
                        ttl=1223334444,
                        checked=True,
                        available=True,
                        force_check=False,
                    )
                ),
            ),
        ],
        indirect=["dynamodb"],
    )
    def test_normal(self, dynamodb, option, expected):
        actual = index.update_item(resource=dynamodb, **option)
        assert actual["Attributes"] == expected


class TestHandler:
    @pytest.mark.parametrize(
        "json_inputs",
        [(["sqs_event_sample_001.json"]), (["sqs_event_sample_001.json"])],
        indirect=["json_inputs"],
    )
    def _test_normal(self, dummy_lambda_context, json_inputs: list):
        event = index.handler(json_inputs[0], dummy_lambda_context)
        assert str(type(event)) == ""
