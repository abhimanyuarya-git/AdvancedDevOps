# VPC Terraform Module

Production-ready AWS VPC module with support for multiple subnet tiers and advanced networking features.

## Features

- **Multi-tier subnet architecture**: Public, Private-App, Private-Persistence, Inspection, and Transit subnets
- **High availability**: Subnets across multiple availability zones
- **IPv6 support**: Optional IPv6 CIDR blocks
- **NAT Gateway options**: Public or private NAT gateways with configurable count
- **VPC Endpoints**: S3 and DynamoDB gateway endpoints
- **IPAM integration**: Support for AWS IPAM pools
- **Flexible routing**: Customizable route tables per subnet tier
- **Secondary CIDR blocks**: Support for additional CIDR ranges

## Usage

```hcl
module "vpc" {
  source = "./modules/vpc"

  vpc_name         = "production"
  cidr_block       = "10.0.0.0/16"
  num_nat_gateways = 3

  num_availability_zones = 3
  
  create_public_subnets              = true
  create_private_app_subnets         = true
  create_private_persistence_subnets = true
  
  custom_tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

## Subnet Architecture

| Tier | Purpose | Internet Access |
|------|---------|----------------|
| Public | Load balancers, bastion hosts | Direct via IGW |
| Private-App | Application servers | Via NAT Gateway |
| Private-Persistence | Databases, caches | Optional via NAT |
| Inspection | Network firewall endpoints | Optional via NAT |
| Transit | Transit Gateway, Private NAT | Optional via NAT |

## Requirements

- Terraform >= 1.3
- AWS Provider >= 5.0.0

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| vpc_name | Name of the VPC | `string` | n/a | yes |
| cidr_block | VPC CIDR block | `string` | n/a | yes |
| num_nat_gateways | Number of NAT Gateways | `number` | n/a | yes |
| num_availability_zones | Number of AZs to use | `number` | `null` | no |
| create_vpc_endpoints | Create S3 and DynamoDB endpoints | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | VPC ID |
| vpc_cidr_block | VPC CIDR block |
| public_subnet_ids | List of public subnet IDs |
| private_app_subnet_ids | List of private app subnet IDs |
| private_persistence_subnet_ids | List of private persistence subnet IDs |
| nat_gateway_ids | List of NAT Gateway IDs |

## Examples

### Development VPC (Single NAT Gateway)

```hcl
module "dev_vpc" {
  source = "./modules/vpc"

  vpc_name         = "dev"
  cidr_block       = "10.1.0.0/16"
  num_nat_gateways = 1

  create_private_persistence_subnets = false
}
```

### Production VPC (High Availability)

```hcl
module "prod_vpc" {
  source = "./modules/vpc"

  vpc_name         = "prod"
  cidr_block       = "10.0.0.0/16"
  num_nat_gateways = 3

  num_availability_zones = 3
  
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  create_vpc_endpoints = true
}
```

## License

Apache 2.0
