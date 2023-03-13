variable "tenant_id" {}
variable "subscription_id" {}
variable "environment" {}
variable "primary_location" {
  type    = object({ name = string, prefix = string })
}