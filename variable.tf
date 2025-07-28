variable "region" {}
variable "key_name" {}
variable "instance_count" {}
variable "install_splunk" {}
variable "s3_bucket_name" {
  default = "ec2-keypair-storage"
}
