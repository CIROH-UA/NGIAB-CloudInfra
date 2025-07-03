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

data "aws_vpc" "cloud_vpc" {
   tags = {
      Name = "${var.name_tag} VPC"
      Project = var.project_tag
    }
}

data "aws_subnet" "main" {
   tags = {
      Name = "${var.name_tag} Subnet"
      Project = var.project_tag
    }
}

data "aws_internet_gateway" "gw" {
   tags = {
      Name = "${var.name_tag} Internet Gateway"
      Project = var.project_tag
    }
}

data "aws_route_table" "default" {
   tags = {
      Name = "${var.name_tag} Route Table"
      Project = var.project_tag
    }
}

# base sg
data "aws_security_group" "default_sg" {
   tags = {
      Name = "${var.name_tag} Base SG"
      Project = var.project_tag
    }
}

data "aws_security_group" "efs_sg" {
   tags = {
      Name = "${var.name_tag} EFS SG"
      Project = var.project_tag
   }
}

data "aws_security_group" "ssh_ingress" {
  tags = {
      Name = "${var.name_tag} SSH SG"
      Project = var.project_tag
   }
}

resource "aws_iam_role" "sandbox_iam_role" {
  name = "${var.nameprefix}_terraform_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
  tags = {
    Name = "${var.name_tag} IAM Role"
    Project = var.project_tag
  }
}

resource "aws_iam_role_policy_attachment" "example_role_policy_attach" {
   count = length(var.managed_policies)
   policy_arn = element(var.managed_policies, count.index)
   role = aws_iam_role.sandbox_iam_role.name
}

resource "aws_iam_instance_profile" "example_iam_instance_profile" {
    name = "${var.nameprefix}_terraform_role"
    role = aws_iam_role.sandbox_iam_role.name
}


data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
}

resource "aws_network_interface" "efa_network_adapter" {
  # Only create and attach this if EFA is supported by the node type
  # c5n.18xlarge supports EFA
  count = data.aws_ec2_instance_type.head_node.efa_supported == true ? 1 : 0
  subnet_id   = data.aws_subnet.main.id
  description = "The Elastic Fabric Adapter to attach to instance if supported"
  security_groups = [data.aws_security_group.default_sg.id,
                     data.aws_security_group.ssh_ingress.id,
                     data.aws_security_group.efs_sg.id]
  
  interface_type = "efa"
  attachment {
    instance     = aws_instance.head_node.id
    device_index = 1
  }
  tags = {
      Name = "${var.name_tag} EFA Network Adapter"
      Project = var.project_tag
  }
}

data "aws_ec2_instance_type" "head_node" {
  instance_type = var.instance_type
}

resource "aws_instance" "head_node" {
  # Base CentOS 7 AMI, can use either AWS's marketplace, or direct from CentOS
  # Choosing direct from CentOS as it is more recent
  ami = data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_type
  cpu_core_count = data.aws_ec2_instance_type.head_node.default_cores
  cpu_threads_per_core = 1
  root_block_device {
        delete_on_termination = true
        volume_size = 12
  }
  depends_on = [data.aws_internet_gateway.gw]
  key_name = var.key_name
  iam_instance_profile = aws_iam_instance_profile.example_iam_instance_profile.name
  user_data = templatefile("script.tftpl", { project_tag = var.project_tag, name_tag = var.name_tag, aws_region = var.aws_region, container_name = var.container_name, ngen_catchment_file = var.ngen_catchment_file, ngen_nexus_file = var.ngen_nexus_file, ngen_realization_file = var.ngen_realization_file, bucket_name = var.bucket_name })
  associate_public_ip_address = true
  subnet_id = data.aws_subnet.main.id
  vpc_security_group_ids = [
    data.aws_security_group.default_sg.id,
    data.aws_security_group.ssh_ingress.id,
    data.aws_security_group.efs_sg.id
  ]
  placement_group = data.aws_ec2_instance_type.head_node.ena_support == true ? aws_placement_group.example_placement_group.id : null
  tags = {
    Name = "${var.name_tag} EC2 Head Node"
    Project = var.project_tag
  }
}

resource "aws_placement_group" "example_placement_group" {
  name = "${var.nameprefix}_Terraform_Placement_Group"
  strategy = "cluster"
  tags = {
    project = var.project_tag
  }
}

resource "aws_efs_file_system" "main_efs" {
  # This is placeholder, and currently not being used
  encrypted = false
  availability_zone_name = var.availability_zone
  tags = {
     Name = "${var.name_tag} EFS"
     Project = var.project_tag
  }
}

resource "aws_efs_mount_target" "mount_target_main_efs" {
    subnet_id = data.aws_subnet.main.id
    security_groups = [data.aws_security_group.efs_sg.id]
    file_system_id = aws_efs_file_system.main_efs.id
}