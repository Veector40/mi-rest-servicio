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

variable "region" {
  type    = string
  default = "us-east-1"
}

# Find Amazon linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm-*-x86_64-gp2"]
  }
}

# Security group for HTTP ingress
resource "aws_security_group" "http_sg" {
  name        = "allow-http-traffic"
  description = "Allow inbound HTTP"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Outbound to anywhere"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

variable "GHCR_PAT" {
  description = "GitHub Container Registry Personal Access Token"
  type        = string
  sensitive   = true
}

# EC2 instance
resource "aws_instance" "my_ec2" {
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = "t2.micro"
  vpc_security_group_ids      = [aws_security_group.http_sg.id]
  associate_public_ip_address = true

  # Install Docker and run said container
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install docker -y
    service docker start
    usermod -aG docker ec2-user

    docker login ghcr.io -u veector40 -p ${var.GHCR_PAT}
    docker pull ghcr.io/veector40/mi-rest-servicio:latest
    docker run -d -p 80:80 ghcr.io/veector40/mi-rest-servicio:latest
  EOF

  tags = {
    Name = "my-simple-rest-service"
  }
}

# Provide a default VPC id
variable "vpc_id" {
  type    = string
  default = "vpc-xxxxxxxx"
}
