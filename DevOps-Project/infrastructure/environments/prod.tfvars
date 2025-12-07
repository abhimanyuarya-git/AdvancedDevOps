# Production Environment VPC Configuration
# High availability setup with NAT Gateway per AZ

vpc_name         = "prod-vpc"
cidr_block       = "10.0.0.0/16"
num_nat_gateways = 3

num_availability_zones = 3

# Subnet Configuration
create_public_subnets              = true
create_private_app_subnets         = true
create_private_persistence_subnets = true
create_inspection_subnets          = false
create_transit_subnets             = false

# Internet Access
allow_private_app_internet_access         = true
allow_private_persistence_internet_access = false
allow_inspection_internet_access          = false
allow_transit_internet_access             = false

# DNS
enable_dns_hostnames = true
enable_dns_support   = true

# VPC Endpoints
create_vpc_endpoints = true

# NAT Gateway
use_custom_nat_eips = false

# Subnet Naming
public_subnet_name              = "public"
private_subnet_name             = "private-app"
private_persistence_subnet_name = "private-persistence"

# Route Tables
one_route_table_public_subnets = false

# Advanced Configuration
tenancy                              = "default"
map_public_ip_on_launch              = false
create_igw                           = true
create_default_route_table_route     = true
enable_default_security_group        = true
enable_network_address_usage_metrics = true

# Tags
custom_tags = {
  Environment = "production"
  ManagedBy   = "terraform"
  Project     = "devops-project"
  CostCenter  = "platform"
  Compliance  = "required"
  Backup      = "daily"
}

vpc_custom_tags = {
  Type        = "production-vpc"
  Criticality = "high"
}

public_subnet_custom_tags = {
  Tier              = "public"
  Type              = "dmz"
  "kubernetes.io/role/elb" = "1"
}

private_app_subnet_custom_tags = {
  Tier                              = "private"
  Type                              = "application"
  "kubernetes.io/role/internal-elb" = "1"
}

private_persistence_subnet_custom_tags = {
  Tier = "private"
  Type = "database"
}

# Security Group Rules
default_security_group_ingress_rules = {
  AllowAllFromSelf = {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }
}

default_security_group_egress_rules = {
  AllowAllOutbound = {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

# Route Table Timeouts
route_table_creation_timeout = "5m"
route_table_update_timeout   = "2m"
route_table_deletion_timeout = "5m"
