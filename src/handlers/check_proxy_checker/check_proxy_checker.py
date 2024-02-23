from common.logger import create_logger, logging_handler

logger = create_logger(__name__)


@logging_handler(logger)
def handler(event: dict, context):
    pass
