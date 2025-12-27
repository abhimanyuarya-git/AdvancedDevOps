# Development Environment VPC Configuration
# Cost-optimized setup with single NAT Gateway

vpc_name         = "dev-vpc"
cidr_block       = "10.1.0.0/16"
num_nat_gateways = 1

num_availability_zones = 2

# Subnet Configuration
create_public_subnets              = true
create_private_app_subnets         = true
create_private_persistence_subnets = false
create_inspection_subnets          = false
create_transit_subnets             = false

# Internet Access
allow_private_app_internet_access         = true
allow_private_persistence_internet_access = false

# DNS
enable_dns_hostnames = true
enable_dns_support   = true

# VPC Endpoints
create_vpc_endpoints = true

# Route Tables
one_route_table_public_subnets = true

# Tags
custom_tags = {
  Environment = "development"
  ManagedBy   = "terraform"
  Project     = "devops-project"
  CostCenter  = "engineering"
}

# EC2 Instance Configuration
ami_id              = "ami-00ca570c1b6d79f36"  # Amazon Linux 2023 (update for your region)
instance_type       = "t3.micro"
key_name            = "abhimanyu-innovantra"     # Replace with your actual key pair name
jenkins_agent_count = 2
