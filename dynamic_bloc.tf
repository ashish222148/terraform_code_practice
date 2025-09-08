terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>6.11.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1" # Change to your region
}

# 1. Create a VPC
resource "aws_vpc" "my_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "my-vpc"
  }
}

# 2. Create a Subnet
resource "aws_subnet" "my_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true # Auto-assign public IPs

  tags = {
    Name = "my-subnet"
  }
}

# 3. Create an Internet Gateway and attach with VPC
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "my-igw"
  }
}

# 4. Create a Route Table & Route
resource "aws_route_table" "my_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }

  tags = {
    Name = "my-route-table"
  }
}

# 5. Associate Route Table with Subnet
resource "aws_route_table_association" "my_rta" {
  subnet_id      = aws_subnet.my_subnet.id
  route_table_id = aws_route_table.my_route_table.id
}

//cretae local block to use ingress dynamically
locals {
  ing_val = {
    ssh = {
      port_from  = 22
      port_to    = 22
      cidr_block = ["0.0.0.0/0"]
    },
    http = {
      port_from  = 80
      port_to    = 80
      cidr_block = ["0.0.0.0/0"]
    },
    https = {
      port_from  = 443
      port_to    = 443
      cidr_block = ["0.0.0.0/0"]
    },
    rdp = {
      port_from  = 3389
      port_to    = 3389
      cidr_block = ["0.0.0.0/0"]
    }
  }
}
# 6. Create a Security Group
resource "aws_security_group" "my_sg" {
  name        = "allow_ssh_http"
  description = "Allow SSH and HTTP"
  vpc_id      = aws_vpc.my_vpc.id

  dynamic "ingress" {
    for_each = local.ing_val
    content {
      from_port   = ingress.value.port_from
      to_port     = ingress.value.port_to
      protocol    = "tcp"
      cidr_blocks = ingress.value.cidr_block
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "my-sg"
  }
}
resource "aws_key_pair" "keypass" {
  key_name   = "clould-key"
  public_key = file("./new.pub")
}
# 7. Launch an EC2 Instance
resource "aws_instance" "my_instance" {
  ami                    = "ami-0dee22c13ea7a9a67" # Ubuntu 22.04 in ap-south-1 (Mumbai). Change per region
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.my_subnet.id
  vpc_security_group_ids = [aws_security_group.my_sg.id]
  key_name               = aws_key_pair.keypass.key_name
  tags = {
    Name = "my-instance"
  }
}