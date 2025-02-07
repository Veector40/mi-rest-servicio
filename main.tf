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

data "aws_security_group" "ssh_http" {
  filter {
    name   = "group-name"
    values = ["allow-ssh-http"]
  }
  filter {
    name   = "vpc-id"
    values = ["vpc-0f58585ee0776273f"]
  }
}

resource "aws_instance" "al2023_instance" {
  ami                         = data.aws_ami.amazon_linux2023.id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [data.aws_security_group.ssh_http.id]
  associate_public_ip_address = true
  key_name                    = var.key_pair_name

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
  EOF

  tags = {
    Name = "AmazonLinux2023-Terraform"
  }
}
