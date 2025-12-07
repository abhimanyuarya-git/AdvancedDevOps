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


