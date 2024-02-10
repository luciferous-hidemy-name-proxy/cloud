resource "aws_cloudwatch_event_bus" "slack_incoming_webhooks" {
  name = "slack_incoming_webhooks"
}

resource "aws_cloudwatch_event_rule" "slack_incoming_webhooks" {
  event_bus_name = aws_cloudwatch_event_bus.slack_incoming_webhooks.name
  event_pattern = jsonencode({
    account = ["${data.aws_caller_identity.current.account_id}"]
  })
  state = "ENABLED"
}

resource "aws_cloudwatch_event_connection" "dummy" {
  authorization_type = "API_KEY"
  name               = "dummy"

  auth_parameters {
    api_key {
      key   = "DUMMY"
      value = "dummy"
    }
  }
}

resource "aws_cloudwatch_event_api_destination" "slack_incoming_webhooks" {
  for_each            = toset(var.slack_incoming_webhooks)
  connection_arn      = aws_cloudwatch_event_connection.dummy.arn
  http_method         = "POST"
  invocation_endpoint = each.value
  name                = sha256(each.value)
}

resource "aws_cloudwatch_event_target" "slack_incoming_webhooks" {
  for_each = aws_cloudwatch_event_api_destination.slack_incoming_webhooks
  arn      = each.value.arn
  rule     = aws_cloudwatch_event_rule.slack_incoming_webhooks.name
  role_arn = aws_iam_role.invoke_api_destination.arn

  input_transformer {
    input_template = "{\"blocks\": <blocks>}"
    input_paths = {
      blocks = "$.detail.blocks"
    }
  }
}
