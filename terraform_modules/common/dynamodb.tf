resource "aws_dynamodb_table" "temp_store" {
  attribute {
    name = "uuid"
    type = "S"
  }

  attribute {
    name = "host"
    type = "S"
  }

  attribute {
    name = "ttl"
    type = "N"
  }

  name             = "temp_store"
  billing_mode     = "PAY_PER_REQUEST"
  stream_enabled   = true
  stream_view_type = "NEW_IMAGE"

  hash_key  = "uuid"
  range_key = "host"

  ttl {
    attribute_name = "ttl"
  }
}