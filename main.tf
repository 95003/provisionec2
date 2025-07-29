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

# Get latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["137112412989"] # Amazon

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# Generate random suffix for unique key names
resource "random_id" "suffix" {
  byte_length = 2
}

# Generate SSH private key
resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Create AWS Key Pair with random suffix to avoid duplicate error
resource "aws_key_pair" "ec2_key" {
  key_name   = "${var.key_name}-${random_id.suffix.hex}"
  public_key = tls_private_key.ec2_key.public_key_openssh
}

# Upload private key to S3 (so you can download the .pem)
resource "aws_s3_object" "private_key" {
  bucket  = var.s3_bucket_name
  key     = "${aws_key_pair.ec2_key.key_name}.pem"
  content = tls_private_key.ec2_key.private_key_pem
}

# Upload public key to S3 (optional, for reference)
resource "aws_s3_object" "public_key" {
  bucket  = var.s3_bucket_name
  key     = "${aws_key_pair.ec2_key.key_name}.pub"
  content = tls_private_key.ec2_key.public_key_openssh
}

# Launch EC2 Instances
resource "aws_instance" "ec2" {
  count         = var.instance_count
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.medium"
  key_name      = aws_key_pair.ec2_key.key_name

  user_data = var.install_splunk == "yes" ? file("${path.module}/install_splunk.sh") : ""

  tags = {
    Name = "${var.instance_name}-${count.index + 1}"
  }
}
