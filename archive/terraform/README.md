# CIROH Cloud Terraform Configuration

This Terraform configuration is used to build and manage resources on the AWI CIROH cloud. Use below instructions to run NextGen In A Box in your AWS account.

## Clone Repo

`git clone https://github.com/AlabamaWaterInstitute/CloudInfra.git`

## Pre-requisite steps:

1. create a key-pair in AWS EC2 console, and place the key under user directory.

## Terraform validate

- GitHub Actions will automatically run `terraform init` and `terraform validate` every time a pull request is made to a branch - `main` and also on merge to main branch.

** the `terraform init` command initializes the Terraform working directory and downloads the necessary providers and modules. It is required before running terraform validate to ensure that all dependencies are available.

## Terraform Directory Structure:

Directories under terraform:

`network`: This directory will setup initial VPC and subnets, Administrator of the AWS account need to run this only once.

`user`: As a user, use this directory to run the terraform configuration.

## Terraform Usage steps: (as an Administrator):

$ cd network

$ terraform init

$ terraform plan -o plan.file

$ terraform apply plan.file


## Terraform Usage steps: (as a User):

$ cd user

$ terraform init

$ terraform plan -o plan.file

$ terraform apply plan.file


`terraform plan -o plan.file` - This command is used to generate a plan file.
`terraform apply plan.file` - This command is used to apply the plan file. It will prompt for the terraform variable values.

## Terraform Variables
The following variables can be customized:

`aws_region`: The preferred region in which to launch EC2 instances. Defaults to us-east-1.

`nameprefix`: Prefix to use for some resource names to avoid duplicates. Default value is "Cloud-Example".

`name_tag`: Value of the Name tag for the EC2 instance. Default value is "Cloud-Example-Terraform".

`project_tag`: Value of the Project tag for the EC2 instance. Default value is "Cloud-Example".

`availability_zone`: Availability zone to use. Default value is "us-east-1a".

`instance_type`: EC2 Instance Type. Larger instance is "c5n.18xlarge". Default value is "t3.medium".

`use_efa`: Attach EFA Network. Default value is "true".

`key_name`: The name of the ssh key-pair used to access the EC2 instances.

`container_name`: The name of the containerized model to run. Default value is "zwills/dmod_ngen_slim".

`ngen_catchment_file`: The path of the catchment file, /mnt is the S3 mount default; then path to examples in the ngen repo.

`ngen_nexus_file`: The path of the nexus file, /mnt is the S3 mount default; examples in the ngen repo.

`ngen_realization_file`: The path of the ngen realization file, /mnt is the S3 mount default; examples in the ngen repo.

`allowed_ssh_cidr`: Public IP address/range allowed for SSH access.

`bucket_name`: S3 Bucket Name for AWS bucket to mount (at /mnt) for data.

`managed_policies`: The attached IAM policies granting machine permissions. Default value is ["arn:aws:iam::aws:policy/AmazonEC2FullAccess", "arn:aws:iam::aws:policy/AmazonS3FullAccess", "arn:aws:iam::aws:policy/AmazonFSxFullAccess"].

`ami_id`: The random ID used for AMIs. Default value is "unknown value".
