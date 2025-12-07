# Production Environment with Network Firewall/Inspection
# High availability setup with inspection and transit subnets

vpc_name         = "prod-secure-vpc"
cidr_block       = "10.10.0.0/16"
num_nat_gateways = 3

num_availability_zones = 3

# Subnet Configuration
create_public_subnets              = true
create_private_app_subnets         = true
create_private_persistence_subnets = true
create_inspection_subnets          = true
create_transit_subnets             = true

# Internet Access
allow_private_app_internet_access         = true
allow_private_persistence_internet_access = false
allow_inspection_internet_access          = true
allow_transit_internet_access             = false

# DNS
enable_dns_hostnames = true
enable_dns_support   = true

# VPC Endpoints
create_vpc_endpoints = true

# Subnet Naming
public_subnet_name              = "public"
private_subnet_name             = "private-app"
private_persistence_subnet_name = "private-persistence"
inspection_subnet_name          = "inspection"
transit_subnet_name             = "transit"

# Route Tables
one_route_table_public_subnets = false

# Subnet Spacing (for inspection and transit subnets)
global_subnet_spacing = 6

# Advanced Configuration
tenancy                              = "default"
map_public_ip_on_launch              = false
create_igw                           = true
enable_network_address_usage_metrics = true

# Tags
custom_tags = {
  Environment = "production"
  ManagedBy   = "terraform"
  Project     = "devops-project"
  Security    = "enhanced"
  Compliance  = "pci-dss"
}

vpc_custom_tags = {
  Type        = "production-secure-vpc"
  Criticality = "critical"
  Firewall    = "enabled"
}

inspection_subnet_custom_tags = {
  Tier = "inspection"
  Type = "network-firewall"
}

transit_subnet_custom_tags = {
  Tier = "transit"
  Type = "transit-gateway"
}
