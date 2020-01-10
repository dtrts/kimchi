variable "localstack" {
  description = "A variable to determine if architecture is in localstack or not. The test will be on true, all other values imply not localstack."
  type        = string
  default     = "false"
}
