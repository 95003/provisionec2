provider "aws" {
  region = var.region
}

resource "aws_key_pair" "default" {
  key_name   = var.key_name
  public_key = file("${path.module}/public_keys/${var.key_name}.pub")
}

resource "aws_instance" "ec2" {
  count         = var.instance_count
  ami           = "ami-0fc5d935ebf8bc3bc"  # Ubuntu 22.04 (adjust for your region)
  instance_type = "t2.micro"
  key_name      = aws_key_pair.default.key_name

  tags = {
    Name        = "ec2-${count.index}"
    environment = "splunk-deploy"
  }

  user_data = var.install_splunk == "yes" ? file("${path.module}/install_splunk.sh") : ""
}
