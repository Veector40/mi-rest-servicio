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
  default = "eu-central-1"
}

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

resource "aws_instance" "my_ec2" {
  ami                         = "ami-07eef52105e8a2059"
  instance_type               = "t2.micro"
  vpc_security_group_ids      = [aws_security_group.http_sg.id]
  associate_public_ip_address = true

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


variable "vpc_id" {
  type    = string
  default = "vpc-0f58585ee0776273f"
}
