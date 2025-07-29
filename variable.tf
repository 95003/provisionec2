variable "region" {
  description = "AWS region"
  type        = string
}

variable "key_name" {
  description = "Base name of EC2 key pair (random suffix will be added)"
  type        = string
}

variable "instance_count" {
  description = "Number of EC2 instances"
  type        = string
  default     = 1
  validation {
    condition     = var.instance_count >= 1
    error_message = "Instance count must be >= 1."
  }
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
  description = "Name prefix for EC2 instance"
  type        = string
  default     = "ec2-instance"
}
