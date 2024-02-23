resource "aws_pipes_pipe" "check_proxy_checker" {
  source   = aws_dynamodb_table.temp_store.stream_arn
  target   = aws_sqs_queue.check_proxy_checker.arn
  role_arn = aws_iam_role.pipe_for_check.arn

  source_parameters {
    dynamodb_stream_parameters {
      starting_position = "TRIM_HORIZON"
    }

    filter_criteria {
      filter {
        pattern = jsonencode({
          eventName = ["INSERT"]
        })
      }
    }
  }
}

resource "aws_pipes_pipe" "check_proxy_closer" {
  source   = aws_dynamodb_table.temp_store.stream_arn
  target   = aws_sqs_queue.check_proxy_closer.arn
  role_arn = aws_iam_role.pipe_for_check.arn

  source_parameters {
    dynamodb_stream_parameters {
      starting_position = "TRIM_HORIZON"
    }

    filter_criteria {
      filter {
        pattern = jsonencode({
          eventName = ["MODIFY"]
        })
      }
    }
  }
}
