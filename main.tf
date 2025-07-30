terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# Get the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Get all existing key pairs
data "aws_key_pairs" "all" {}

# Check if the user-supplied key already exists
locals {
  key_exists = contains([for k in data.aws_key_pairs.all.key_names : k], var.key_name)
}

# If key exists, generate a random suffix
resource "random_id" "suffix" {
  byte_length = 2
  count       = local.key_exists ? 1 : 0
}

# Final key name (base or base + suffix)
locals {
  final_key_name = local.key_exists ? "${var.key_name}-${random_id.suffix[0].hex}" : var.key_name
}

# Generate a new key pair
resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "ec2_key" {
  key_name   = local.final_key_name
  public_key = tls_private_key.ec2_key.public_key_openssh
}

# Store private key in S3
resource "aws_s3_object" "private_key" {
  bucket  = var.s3_bucket_name
  key     = "${local.final_key_name}.pem"
  content = tls_private_key.ec2_key.private_key_pem
}

# Store public key in S3
resource "aws_s3_object" "public_key" {
  bucket  = var.s3_bucket_name
  key     = "${local.final_key_name}.pub"
  content = tls_private_key.ec2_key.public_key_openssh
}

# EC2 instance(s)
resource "aws_instance" "ec2" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.ec2_key.key_name
  count         = var.instance_count

  tags = {
    Name = "${var.instance_name}-${count.index}"
  }

  user_data = var.install_splunk ? <<-EOT
              #!/bin/bash
              echo "Installing Splunk..."
              # your Splunk install script here
              EOT : null
}
