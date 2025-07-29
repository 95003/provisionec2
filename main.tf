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

# Generate SSH key
resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Always create a unique key name
locals {
  final_key_name = "${var.key_name}-${substr(uuid(), 0, 4)}"
}

# Create AWS Key Pair
resource "aws_key_pair" "ec2_key" {
  key_name   = local.final_key_name
  public_key = tls_private_key.ec2_key.public_key_openssh
}

# Upload private key to S3
resource "aws_s3_object" "private_key" {
  bucket  = var.s3_bucket_name
  key     = "${local.final_key_name}.pem"
  content = tls_private_key.ec2_key.private_key_pem
}

# Upload public key to S3
resource "aws_s3_object" "public_key" {
  bucket  = var.s3_bucket_name
  key     = "${local.final_key_name}.pub"
  content = tls_private_key.ec2_key.public_key_openssh
}

# Launch EC2 instances
resource "aws_instance" "ec2" {
  count         = tonumber(var.instance_count)
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.medium"
  key_name      = aws_key_pair.generated_key.key_name

  user_data = var.install_splunk == "yes" ? file("${path.module}/install_splunk.sh") : ""

  tags = {
    Name = "${var.instance_name}-${count.index + 1}"
  }
}
