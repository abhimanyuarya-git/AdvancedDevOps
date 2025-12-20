# Example: How to use the VPC module
# This file demonstrates how to call the VPC module from a root module

# ---------------------------------------------------------------------------------------------------------------------
# EXAMPLE 1: Using the module with tfvars
# ---------------------------------------------------------------------------------------------------------------------

module "vpc" {
  source = "./modules/vpc"

  # Required variables
  vpc_name         = var.vpc_name
  cidr_block       = var.cidr_block
  num_nat_gateways = var.num_nat_gateways

  # Availability Zones
  num_availability_zones = var.num_availability_zones

  # Subnet Configuration
  create_public_subnets              = var.create_public_subnets
  create_private_app_subnets         = var.create_private_app_subnets
  create_private_persistence_subnets = var.create_private_persistence_subnets
  create_inspection_subnets          = var.create_inspection_subnets
  create_transit_subnets             = var.create_transit_subnets

  # Internet Access
  allow_private_app_internet_access         = var.allow_private_app_internet_access
  allow_private_persistence_internet_access = var.allow_private_persistence_internet_access

  # DNS
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  # VPC Endpoints
  create_vpc_endpoints = var.create_vpc_endpoints

  # Tags
  custom_tags = var.custom_tags
}

# ---------------------------------------------------------------------------------------------------------------------
# EXAMPLE 2: Direct usage without variables (hardcoded values)
# ---------------------------------------------------------------------------------------------------------------------

# module "vpc_direct" {
#   source = "./modules/vpc"
#
#   vpc_name         = "my-vpc"
#   cidr_block       = "10.0.0.0/16"
#   num_nat_gateways = 3
#
#   num_availability_zones = 3
#
#   create_public_subnets              = true
#   create_private_app_subnets         = true
#   create_private_persistence_subnets = true
#
#   custom_tags = {
#     Environment = "production"
#     ManagedBy   = "terraform"
#   }
# }

# ---------------------------------------------------------------------------------------------------------------------
# EXAMPLE 3: Multiple VPCs (e.g., for different environments)
# ---------------------------------------------------------------------------------------------------------------------

# module "vpc_prod" {
#   source = "./modules/vpc"
#
#   vpc_name         = "prod-vpc"
#   cidr_block       = "10.0.0.0/16"
#   num_nat_gateways = 3
#
#   custom_tags = {
#     Environment = "production"
#   }
# }
#
# module "vpc_dev" {
#   source = "./modules/vpc"
#
#   vpc_name         = "dev-vpc"
#   cidr_block       = "10.1.0.0/16"
#   num_nat_gateways = 1
#
#   custom_tags = {
#     Environment = "development"
#   }
# }



# ---------------------------------------------------------------------------------------------------------------------
# SECURITY GROUPS
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "ansible_controller_sg" {
  name        = "ansible-controller-sg"
  description = "Security group for Ansible Controller"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.custom_tags, {
    Name = "ansible-controller-sg"
  })
}

resource "aws_security_group" "jenkins_master_sg" {
  name        = "jenkins-master-sg"
  description = "Security group for Jenkins Master"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Jenkins web UI"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Jenkins agent communication"
    from_port   = 50000
    to_port     = 50000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.custom_tags, {
    Name = "jenkins-master-sg"
  })
}

resource "aws_security_group" "jenkins_agent_sg" {
  name        = "jenkins-agent-sg"
  description = "Security group for Jenkins Agent"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "SSH access"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  ingress {
    description     = "Communication from Jenkins Master"
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.jenkins_master_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.custom_tags, {
    Name = "jenkins-agent-sg"
  })
}

# ---------------------------------------------------------------------------------------------------------------------
# EC2 INSTANCES
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_instance" "ansible_controller" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = module.vpc.public_subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.ansible_controller_sg.id]
  key_name               = var.key_name

  tags = merge(var.custom_tags, {
    Name = "ansible-controller"
    Role = "automation"
  })
}

resource "aws_instance" "jenkins_master" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = module.vpc.public_subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.jenkins_master_sg.id]
  key_name               = var.key_name

  tags = merge(var.custom_tags, {
    Name = "jenkins-master"
    Role = "ci-cd"
  })
}

resource "aws_instance" "jenkins_agent" {
  count                  = var.jenkins_agent_count
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = module.vpc.public_subnet_ids[count.index % length(module.vpc.public_subnet_ids)]
  vpc_security_group_ids = [aws_security_group.jenkins_agent_sg.id]
  key_name               = var.key_name

  tags = merge(var.custom_tags, {
    Name = "jenkins-agent-${count.index + 1}"
    Role = "ci-cd-worker"
  })
}

# ---------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ---------------------------------------------------------------------------------------------------------------------

output "ansible_controller_public_ip" {
  description = "Public IP of Ansible Controller"
  value       = aws_instance.ansible_controller.public_ip
}

output "jenkins_master_public_ip" {
  description = "Public IP of Jenkins Master"
  value       = aws_instance.jenkins_master.public_ip
}

output "jenkins_master_url" {
  description = "Jenkins Master URL"
  value       = "http://${aws_instance.jenkins_master.public_ip}:8080"
}

output "jenkins_agent_public_ips" {
  description = "Public IPs of Jenkins Agents"
  value       = aws_instance.jenkins_agent[*].public_ip
}
