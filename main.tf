terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  required_version = ">= 1.0.0"
}

provider "aws" {
  region = var.region
}

# vars
variable "region" {
  type    = string
  default = "eu-central-1"
}

# If you have multiple subnets, specify one in the same VPC (vpc-0f58585ee0776273f).
variable "subnet_id" {
  type    = string
  default = "subnet-002831f6079855201"
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "key_pair_name" {
  type    = string
  default = "finalkey"
}

# Data sources

data "aws_ami" "amazon_linux2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

# Resources
resource "aws_security_group" "ssh_http" {
  name        = "allow-ssh-http"
  description = "Allow inbound SSH (22) and HTTP (80)"
  vpc_id      = "vpc-0f58585ee0776273f"

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "al2023_instance" {
  ami                         = data.aws_ami.amazon_linux2023.id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.ssh_http.id]
  associate_public_ip_address = true
  key_name                    = var.key_pair_name

  # Minimal user_data script (optional). Add any bootstrapping commands if needed.
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
  EOF

  tags = {
    Name = "AmazonLinux2023-Terraform"
  }
}
