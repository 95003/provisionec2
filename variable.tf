variable "region" {
  description = "AWS region to deploy instances"
  type        = string
}

variable "instance_count" {
  description = "Number of EC2 instances to launch"
  type        = number
}

variable "key_name" {
  description = "Name of the key pair"
  type        = string
}

variable "install_splunk" {
  description = "Whether to install Splunk (yes/no)"
  type        = string
}
