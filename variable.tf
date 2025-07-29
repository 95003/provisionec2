variable "region" {
  description = "AWS region"
  type        = string
}

variable "key_name" {
  description = "Base name for the key pair"
  type        = string
}

variable "instance_count" {
  description = "Number of EC2 instances to launch"
  type        = number
  default     = 1
}

variable "install_splunk" {
  description = "Whether to install Splunk (true/false as string from CodeBuild)"
  type        = string
  default     = "false"
}

variable "s3_bucket_name" {
  description = "S3 bucket name where private key will be stored"
  type        = string
}

variable "instance_name" {
  description = "Base name for the EC2 instance(s)"
  type        = string
  default     = "my-ec2"
}

# ✅ Convert string → bool for use in resources
locals {
  install_splunk_bool = lower(var.install_splunk) == "true"
}
