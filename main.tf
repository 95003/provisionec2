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

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "random_id" "suffix" {
  byte_length = 2
}

resource "aws_key_pair" "ec2_key" {
  key_name   = "${var.key_name}-${random_id.suffix.hex}"
  public_key = tls_private_key.ec2_key.public_key_openssh
}

resource "aws_s3_object" "private_key" {
  bucket  = var.s3_bucket_name
  key     = "${var.key_name}-${random_id.suffix.hex}.pem"
  content = tls_private_key.ec2_key.private_key_pem
}

resource "aws_s3_object" "public_key" {
  bucket  = var.s3_bucket_name
  key     = "${var.key_name}-${random_id.suffix.hex}.pub"
  content = tls_private_key.ec2_key.public_key_openssh
}

resource "aws_instance" "ec2" {
  count         = var.instance_count
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.ec2_key.key_name

  tags = {
    Name = "terraform-ec2-${count.index}"
  }
}
