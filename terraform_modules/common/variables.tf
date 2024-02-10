variable "system_name" {
  type     = string
  nullable = false
}

variable "region" {
  type     = string
  nullable = false
}

variable "code_hidemy_name_proxy" {
  type      = string
  nullable  = false
  sensitive = true
}

variable "slack_incoming_webhooks" {
  type      = list(string)
  nullable  = false
}