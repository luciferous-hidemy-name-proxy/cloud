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

resource "aws_iam_role" "tmp" {
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy_lambda.json
}

resource "aws_iam_role_policy_attachment" "tmp_basic" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.tmp.name
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

resource "aws_iam_role" "pipe_for_check" {
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy_pipe.json
}

resource "aws_iam_role_policy_attachment" "pipe_for_process" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonDynamoDBReadOnlyAccess",
    "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
  ])
  policy_arn = each.value
  role       = aws_iam_role.pipe_for_check.name
}
