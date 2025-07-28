provider "aws" {
  region = var.region
}

# Generate RSA Key Pair
resource "tls_private_key" "generated_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Register Public Key in EC2
resource "aws_key_pair" "ec2_key" {
  key_name   = var.key_name
  public_key = tls_private_key.generated_key.public_key_openssh
}

# Store Private Key in S3
resource "aws_s3_bucket_object" "private_key" {
  bucket       = var.s3_bucket_name
  key          = "${var.key_name}.pem"
  content      = tls_private_key.generated_key.private_key_pem
  content_type = "text/plain"
}

# Launch EC2 Instances
resource "aws_instance" "ec2" {
  count         = var.instance_count
  ami           = "ami-0fc5d935ebf8bc3bc" # Ubuntu 22.04 in ap-southeast-2
  instance_type = "t2.micro"
  key_name      = aws_key_pair.ec2_key.key_name

  user_data = var.install_splunk == "yes" ? file("${path.module}/install_splunk.sh") : ""

  tags = {
    Name        = "splunk-ec2-${count.index}"
    environment = "auto-deploy"
  }
}
