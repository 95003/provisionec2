provider "aws" {
  region = var.region
}

# Generate random suffix to avoid duplicate resource names
resource "random_integer" "suffix" {
  min = 1000
  max = 9999
}

# Generate private key
resource "tls_private_key" "generated" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Register key pair in AWS with unique name
resource "aws_key_pair" "generated" {
  key_name   = "${var.key_name}-${random_integer.suffix.result}"
  public_key = tls_private_key.generated.public_key_openssh
}

# Save private key to S3 bucket with unique suffix
resource "aws_s3_object" "private_key" {
  bucket  = "keypair-provision"
  key     = "${var.key_name}-${random_integer.suffix.result}.pem"
  content = tls_private_key.generated.private_key_pem
}

# Get the latest RHEL AMI
data "aws_ami" "rhel" {
  most_recent = true
  owners      = ["309956199498"] # Red Hat official account

  filter {
    name   = "name"
    values = ["RHEL-9.*-x86_64-*"]
  }
}

# Security group with random suffix (avoids duplicates)
resource "aws_security_group" "allow" {
  name        = "allow_splunk_${random_integer.suffix.result}"
  description = "Allow SSH and Splunk"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8000
    to_port     = 9999
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 instances
resource "aws_instance" "splunk" {
  count         = var.instance_count
  ami           = data.aws_ami.rhel.id
  instance_type = "t2.medium"
  key_name      = aws_key_pair.generated.key_name

  vpc_security_group_ids = [aws_security_group.allow.id]

  # 30 GiB root storage
  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  # Instance naming
  tags = {
    Name = var.instance_count == 1 ? "splunk" : "splunk-${count.index + 1}"
  }

  # Install Splunk only if user sets install_splunk = "yes"
  user_data = var.install_splunk == "yes" ? file("${path.module}/splunk-setup.sh") : null
}
