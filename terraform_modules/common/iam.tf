# ================================================================
# Assume Role Policy Document
# ================================================================
data "aws_iam_policy_document" "assume_role_policy_lambda" {
  policy_id = "assume_role_policy_lambda"
  statement {
    sid     = "LambdaAssumeRolePolicy"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }
  }
}

data "aws_iam_policy_document" "assume_role_policy_pipe" {
  policy_id = "assume_role_policy_pipe"
  statement {
    sid     = "PipeAssumeRolePolicy"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["pipes.amazonaws.com"]
      type        = "Service"
    }
  }
}

data "aws_iam_policy_document" "assume_role_policy_event_bridge" {
  policy_id = "assume_role_policy_event_bridge"
  statement {
    sid     = "EventBridgeAssumeRolePolicy"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["events.amazonaws.com"]
      type        = "Service"
    }
  }
}

# ================================================================
# Policy KMS Decrypt
# ================================================================

data "aws_iam_policy_document" "policy_kms_decrypt" {
  policy_id = "policy_kms_decrypt"
  statement {
    sid       = "AllowKmsDecrypt"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "kms_decrypt" {
  policy = data.aws_iam_policy_document.policy_kms_decrypt.json
}

# ================================================================
# Policy Invoke API Destination (EventBridge)
# ================================================================

data "aws_iam_policy_document" "policy_invoke_api_destination" {
  policy_id = "policy_invoke_api_destination"
  statement {
    sid       = "AllowInvokeApiDestination"
    effect    = "Allow"
    actions   = ["events:InvokeApiDestination"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "invoke_api_destination" {
  policy = data.aws_iam_policy_document.policy_invoke_api_destination.json
}

# ================================================================
# Policy Put Events (EventBridge)
# ================================================================

data "aws_iam_policy_document" "policy_put_events" {
  policy_id = "policy_put_events"
  statement {
    sid       = "AllowPutEvents"
    effect    = "Allow"
    actions   = ["events:PutEvents"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "put_events" {
  policy = data.aws_iam_policy_document.policy_put_events.json
}

# ================================================================
# Policy Send Message (SQS)
# ================================================================

data "aws_iam_policy_document" "policy_sqs_send_message" {
  policy_id = "policy_sqs_send_message"
  statement {
    sid       = "AllowSQSSendMessage"
    effect    = "Allow"
    actions   = ["sqs:SendMessage"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "sqs_send_message" {
  policy = data.aws_iam_policy_document.policy_sqs_send_message.json
}

# ================================================================
# tmp lambda role
# ================================================================

resource "aws_iam_role" "tmp" {
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy_lambda.json
}

resource "aws_iam_role_policy_attachment" "tmp_basic" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.tmp.name
}

# ================================================================
# Role Pipe for Check
# ================================================================

resource "aws_iam_role" "pipe_for_check" {
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy_pipe.json
}

resource "aws_iam_role_policy_attachment" "pipe_for_process" {
  for_each = toset([
    "arn:aws:iam::aws:policy/service-role/AWSLambdaDynamoDBExecutionRole",
    "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
  ])
  policy_arn = each.value
  role       = aws_iam_role.pipe_for_check.name
}

# ================================================================
# Role call_hidemy_name
# ================================================================

resource "aws_iam_role" "call_hidemy_name" {
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy_lambda.json
}

resource "aws_iam_role_policy_attachment" "call_hidemy_name" {
  for_each = {
    a = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    b = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess",
    c = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess",
    d = aws_iam_policy.kms_decrypt.arn,
  }
  policy_arn = each.value
  role       = aws_iam_role.call_hidemy_name.name
}

# ================================================================
# Role invoke_api_destination
# ================================================================

resource "aws_iam_role" "invoke_api_destination" {
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy_event_bridge.json
}

resource "aws_iam_role_policy_attachment" "invoke_api_destination" {
  for_each = {
    a = aws_iam_policy.invoke_api_destination.arn
  }
  policy_arn = each.value
  role       = aws_iam_role.invoke_api_destination.name
}

# ================================================================
# Role error_notificator
# ================================================================

resource "aws_iam_role" "error_notificator" {
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy_lambda.json
}

resource "aws_iam_role_policy_attachment" "error_notificator" {
  for_each = {
    a = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    b = aws_iam_policy.put_events.arn
  }
  policy_arn = each.value
  role       = aws_iam_role.error_notificator.name
}

# ================================================================
# Role error_notificator
# ================================================================

resource "aws_iam_role" "check_proxy" {
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy_lambda.json
}

resource "aws_iam_role_policy_attachment" "check_proxy" {
  for_each = {
    a = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    b = "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
    c = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
    d = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
    e = aws_iam_policy.sqs_send_message.arn
  }
  policy_arn = each.value
  role       = aws_iam_role.check_proxy.name
}
