# Simple EC2 instance with Terraform
provider "aws" {
  region = "us-east-2"
}

# Generate a private key
resource "tls_private_key" "my_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Create a key pair in AWS
resource "aws_key_pair" "my_key" {
  key_name   = "my-terraform-key"
  public_key = tls_private_key.my_key.public_key_openssh
}

# Save private key to a file
resource "local_file" "private_key" {
  filename        = "nsikak-key.pem"
  content         = tls_private_key.my_key.private_key_pem
  file_permission = "0600"
}

# Create an EC2 instance
resource "aws_instance" "my_server" {
  ami           = "ami-0d1b5a8c13042c939" # Ubuntu 24.04 LTS
  instance_type = "t3.micro"
  key_name      = aws_key_pair.my_key.key_name

  tags = {
    Name = "my-ubuntu-server"
  }
}

# Output the public IP
output "public_ip" {
  value = aws_instance.my_server.public_ip
}
