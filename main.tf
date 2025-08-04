provider "aws" {
  region = var.region
}

# ✅ Generate private key only
resource "tls_private_key" "generated" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "random_integer" "suffix" {
  min = 1
  max = 9999
}

resource "aws_key_pair" "generated" {
  key_name   = "${var.key_name}-${random_integer.suffix.result}"
  public_key = tls_private_key.generated.public_key_openssh
}

# ✅ Save only private key to your S3 bucket
resource "aws_s3_object" "private_key" {
  bucket  = "keypair-provision"
  key     = "${var.key_name}-${random_integer.suffix.result}.pem"
  content = tls_private_key.generated.private_key_pem
}

# ✅ Use RHEL instead of Amazon Linux
data "aws_ami" "rhel" {
  most_recent = true
  owners      = ["309956199498"] # Red Hat official account

  filter {
    name   = "name"
    values = ["RHEL-9.*-x86_64-*"]
  }
}

# ✅ EC2 instance creation
resource "aws_instance" "splunk" {
  count         = var.instance_count
  ami           = data.aws_ami.rhel.id
  instance_type = "t2.medium"
  key_name      = aws_key_pair.generated.key_name
  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  # ✅ Dynamic naming
  tags = {
    Name = var.instance_count == 1 ? "splunk" : "splunk-${count.index + 1}"
  }

  # ✅ Run Splunk setup only if install_splunk == "yes"
  user_data = var.install_splunk == "yes" ? file("${path.module}/splunk-setup.sh") : null
}

# 🔹 Keep your existing security group inbound rules unchanged!
resource "aws_security_group" "allow" {
  name        = "allow_splunk"
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

