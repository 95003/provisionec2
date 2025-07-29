provider "aws" {
  region = var.region
}

# Generate a new private key
resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Check if key already exists
data "aws_key_pair" "existing" {
  key_name = var.key_name
  depends_on = []
  # If it doesn’t exist, terraform will create new one below
  # Wrap in try() so terraform won’t fail
}

# Generate unique key name if duplicate exists
locals {
  final_key_name = try(data.aws_key_pair.existing.key_name, "") != "" ?
    "${var.key_name}-${substr(uuid(), 0, 4)}" : var.key_name
}

# Create new AWS Key Pair
resource "aws_key_pair" "ec2_key" {
  key_name   = local.final_key_name
  public_key = tls_private_key.ec2_key.public_key_openssh
}

# Upload keys to S3
resource "aws_s3_object" "private_key" {
  bucket  = var.s3_bucket_name
  key     = "${local.final_key_name}.pem"
  content = tls_private_key.ec2_key.private_key_pem
}

resource "aws_s3_object" "public_key" {
  bucket  = var.s3_bucket_name
  key     = "${local.final_key_name}.pub"
  content = tls_private_key.ec2_key.public_key_openssh
}

# Get Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["137112412989"]

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

# Launch EC2
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
