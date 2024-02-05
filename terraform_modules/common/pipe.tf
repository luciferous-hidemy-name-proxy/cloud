resource "aws_pipes_pipe" "for_check" {
  source   = aws_dynamodb_table.temp_store.stream_arn
  target   = aws_sqs_queue.check_proxy.arn
  role_arn = aws_iam_role.pipe_for_check.arn

  source_parameters = {
    dynamodb_stream_parameters = {
      starting_position = "TRIM_HORIZON"
    }
  }
}