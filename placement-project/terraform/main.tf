terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.5.0"
}

provider "aws" {
  region = "ap-south-1"
}

# VPC module (create this first)
module "vpc" {
  source = "./vpc"
}

# EC2 master instance (create before EKS)
module "ec2" {
  source = "./ec2"
  vpc_id = module.vpc.vpc_id
  public_subnet_id = module.vpc.public_subnet_id
  depends_on = [module.vpc]
}

# EKS module
module "eks" {
  source = "./eks"
  vpc_id = module.vpc.vpc_id
  subnet_ids = concat([module.vpc.public_subnet_id], module.vpc.private_subnet_ids)
  depends_on = [module.ec2, module.vpc]
}

# RDS instance
module "rds" {
  source = "./rds"
  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids
  db_subnet_group_name = module.vpc.db_subnet_group_name
  depends_on = [module.vpc]
}

# Set ansible master public ip dynamically
resource "local_file" "ansible_inventory" {
  filename = "${path.module}/ansible/inventory.ini"
  content  = <<-EOT
[master]
${module.ec2.master_instance_ip} ansible_user=ubuntu ansible_ssh_private_key_file=/home/ubuntu/placement-project/terraform/main-key

[master:vars]
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
  EOT

  depends_on = [module.ec2]
}

# Run Ansible Automatically - SIMPLIFIED VERSION
resource "null_resource" "run_ansible" {
  depends_on = [
    module.ec2,
    local_file.ansible_inventory,
    module.eks,
    module.rds
  ]

  triggers = {
    instance_ip = module.ec2.master_instance_ip
    timestamp   = timestamp()
  }

  provisioner "local-exec" {
    command = "cd ${path.module}/ansible && ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory.ini playbook.yml"
  }
}

# Output useful information
output "master_instance_ip" {
  value = module.ec2.master_instance_ip
}

output "ansible_completion" {
  value = "Ansible provisioning completed for ${module.ec2.master_instance_ip}"
}

output "rds_endpoint" {
  value = module.rds.rds_endpoint
}

output "eks_cluster_name" {
  value = module.eks.eks_cluster_name
}

output "eks_cluster_endpoint" {
  value = module.eks.eks_cluster_endpoint
}


