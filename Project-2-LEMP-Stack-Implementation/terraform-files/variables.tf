variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "instance_type" {
  description = "Size of the EC2 instance"
  type        = string
  default     = "t3.micro"
}

variable "instance_name" {
  description = "Name of instance"
  type        = string
  default     = "Ubuntu-server"
}

variable "ami_id" {
  description = "The AMI ID you want to use"
  type        = string
  default     = "ami-0d1b5a8c13042c939" # Ubuntu 24.04 LTS
}

variable "key_name" {
  description = "Name of your SSH key pair"
  type        = string
  default     = "my-terraform-key"
}
