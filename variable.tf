variable "region" {
  description = "AWS region"
  type        = string
}

variable "key_name" {
  description = "Base name for EC2 key pair"
  type        = string
}

variable "instance_count" {
  description = "Number of EC2 instances"
  type        = number
  default     = 1
}

variable "install_splunk" {
  description = "Install Splunk (yes or no)"
  type        = string
  default     = "no"
}

variable "s3_bucket_name" {
  description = "Name of S3 bucket to store keys"
  type        = string
}

variable "instance_name" {
  description = "Name tag for EC2 instance"
  type        = string
  default     = "ec2-instance"
}
