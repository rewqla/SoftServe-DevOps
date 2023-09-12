terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.region
}

resource "aws_vpc" "my_vpc" {
  cidr_block = var.cidr
 
  tags = {
    Name = "my_vpc"
  }
}

resource "aws_subnet" "public_subnet" {
  cidr_block = var.publicCIDR
  vpc_id = aws_vpc.my_vpc.id
  availability_zone = var.availability_zone
}

resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
}

resource "aws_route_table" "public_route" {
  vpc_id = aws_vpc.my_vpc.id
  route {
    cidr_block= "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }
}

resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route.id
}

resource "aws_instance" "my_instance" {
  ami           = var.instance_AMI
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public_subnet.id

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install httpd -y
              systemctl start httpd
              systemctl enable httpd
              EOF
}

resource "aws_security_group" "my_security_group" {
  name        = "my-security-group"
  description = "Allow incoming traffic on specified ports"
  vpc_id      = aws_vpc.my_vpc.id

  dynamic "ingress" {
    for_each = var.allowed_ports
    content {
      protocol    = "tcp"
       from_port   = element(var.allowed_ports, ingress.key)
      to_port     = element(var.allowed_ports, ingress.key)
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}