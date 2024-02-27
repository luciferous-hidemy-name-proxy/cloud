variable "api_id" {
  type     = string
  nullable = false
}

variable "lambda_arn" {
  type     = string
  nullable = false
}

variable "http_method" {
  type     = string
  nullable = false
}

variable "path" {
  type     = string
  nullable = false
}