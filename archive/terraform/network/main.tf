terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }
}

provider "aws" {
  region  = var.aws_region
}

resource "aws_vpc" "cloud_vpc" {
  # This is a large vpc, 256 x 256 IPs available
   cidr_block = "100.0.0.0/16"
   enable_dns_support = true
   enable_dns_hostnames = true
   tags = {
      Name = "${var.name_tag} VPC"
      Project = var.project_tag
    }
}

resource "aws_subnet" "main" {
  vpc_id   = aws_vpc.cloud_vpc.id
  # This subnet will allow 256 IPs
  cidr_block = "100.0.1.0/24"
  availability_zone = var.availability_zone
   tags = {
      Name = "${var.name_tag} Subnet"
      Project = var.project_tag
    }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.cloud_vpc.id
   tags = {
      Name = "${var.name_tag} Internet Gateway"
      Project = var.project_tag
    }
}

resource "aws_route_table" "default" {
    vpc_id = aws_vpc.cloud_vpc.id

    route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.gw.id
    }
   tags = {
      Name = "${var.name_tag} Route Table"
      Project = var.project_tag
    }
}

resource "aws_route_table_association" "main" {
  subnet_id = aws_subnet.main.id
  route_table_id = aws_route_table.default.id
}

# base sg
resource "aws_security_group" "default_sg" {
   vpc_id = aws_vpc.cloud_vpc.id
   tags = {
      Name = "${var.name_tag} Base SG"
      Project = var.project_tag
    }
}

resource "aws_security_group" "efs_sg" {
   vpc_id = aws_vpc.cloud_vpc.id
   ingress {
     self = true
     from_port = 2049
     to_port = 2049
     protocol = "tcp"
   }
   # allow all outgoing from NFS
   egress {
      from_port = 0
      to_port = 0
      protocol = -1
      cidr_blocks = ["0.0.0.0/0"]
   }
   tags = {
      Name = "${var.name_tag} EFS SG"
      Project = var.project_tag
   }
}

resource "aws_security_group" "ssh_ingress" {
  vpc_id = aws_vpc.cloud_vpc.id
  ingress {
          description = "Allow SSH from approved IP addresses"
          from_port = 22
          to_port   = 22
          protocol = "tcp"
          cidr_blocks = [var.allowed_ssh_cidr]
  }
  tags = {
      Name = "${var.name_tag} SSH SG"
      Project = var.project_tag
   }
}