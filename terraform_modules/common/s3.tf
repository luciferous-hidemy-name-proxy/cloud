locals {
  s3 = {
    data_key = "available_hosts.json"
  }
}

resource "aws_s3_bucket" "data" {
  bucket_prefix = "data_"
}