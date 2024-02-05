from functools import wraps
from sys import version
from typing import Callable

import boto3
import botocore
from aws_lambda_powertools import Logger


def logging_handler(logger: Logger, *, with_return: bool = False) -> Callable:
    def wrapper(handler: Callable) -> Callable:
        @wraps(handler)
        @logger.inject_lambda_context()
        def process(event, context, *args, **kwargs):
            try:
                logger.debug(
                    "event, python/boto3/botocore version, environment variables",
                    data={
                        "python": version,
                        "boto3": boto3.__version__,
                        "botocore": botocore.__version__,
                    },
                )
            except Exception as e:
                logger.warning(
                    f"error occurred in logging event and version and environment variables: {e}",
                    exc_info=True,
                )

            try:
                result = handler(event, context, *args, **kwargs)
                if with_return:
                    logger.debug("handler return", data={"return": result})
                return result
            except Exception as e:
                logger.error(f"error occurred in handler: {e}", exc_info=True)
                raise

        return process

    return wrapper
