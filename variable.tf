variable "region" {
  description = "AWS region"
  type        = string
}

variable "key_name" {
  description = "EC2 key pair name"
  type        = string
}

variable "instance_count" {
  description = "Number of instances"
  type        = number
  default     = 1
}

variable "install_splunk" {
  description = "Whether to install Splunk on the EC2 instances"
  type        = string
  default     = "false"
}

locals {
  install_splunk_bool = lower(var.install_splunk) == "true"
}

variable "s3_bucket_name" {
  description = "S3 bucket name to store keys"
  type        = string
}
