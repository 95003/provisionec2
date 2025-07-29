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
  description = "Whether to install Splunk"
  type        = bool
  default     = false
}

variable "s3_bucket_name" {
  description = "S3 bucket name to store keys"
  type        = string
}
