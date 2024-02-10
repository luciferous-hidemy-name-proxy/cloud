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
# tmp lambda role
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
  role       = aws_iam_role.call_hidemy_name.arn
}

# ================================================================
# Role invoke_api_destination
# ================================================================

resource "aws_iam_role" "invoke_api_destination" {
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy_event_bridge.json
}

resource "aws_iam_role_policy_attachment" "invoke_api_destination" {
  for_each   = toset([aws_iam_policy.invoke_api_destination.arn])
  policy_arn = each.value
  role       = aws_iam_role.invoke_api_destination.name
}
