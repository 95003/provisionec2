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

# Create key pair locally (optional: assume key already exists)
resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

data "aws_key_pair" "existing" {
  key_name = var.key_name
}


# Upload key pair to S3
resource "aws_s3_object" "private_key" {
  bucket  = var.s3_bucket_name
  key     = "${var.key_name}.pem"
  content = tls_private_key.ec2_key.private_key_pem
}

resource "aws_s3_object" "public_key" {
  bucket  = var.s3_bucket_name
  key     = "${var.key_name}.pub"
  content = tls_private_key.ec2_key.public_key_openssh
}

# Launch EC2 instances
resource "aws_instance" "ec2" {
  count         = var.instance_count
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  key_name      = data.aws_key_pair.existing.key_name

  user_data = var.install_splunk == "yes" ? file("${path.module}/install_splunk.sh") : ""

  tags = {
    Name = "ec2-instance-${count.index + 1}"
  }
}
