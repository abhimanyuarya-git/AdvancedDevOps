# Staging Environment VPC Configuration
# Balanced setup with 2 NAT Gateways

vpc_name         = "staging-vpc"
cidr_block       = "10.2.0.0/16"
num_nat_gateways = 2

num_availability_zones = 2

# Subnet Configuration
create_public_subnets              = true
create_private_app_subnets         = true
create_private_persistence_subnets = true
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
  Environment = "staging"
  ManagedBy   = "terraform"
  Project     = "devops-project"
  CostCenter  = "engineering"
}

vpc_custom_tags = {
  Type = "staging-vpc"
}
