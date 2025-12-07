output "vpc_id" {
  value = aws_vpc.main.id
}

output "vpc_name" {
  value = var.vpc_name
}

output "vpc_cidr_block" {
  value = aws_vpc.main.cidr_block
}

output "ipv6_cidr_block" {
  description = "The IPv6 CIDR block associated with the VPC."
  value       = aws_vpc.main.ipv6_cidr_block
}

// A VPC automatically comes with a default security group. If you don't
// specify a different security group when you launch an instance, AWS
// associates the default security group with your instance. You can't
// delete a default security group.
output "default_security_group_id" {
  value = aws_vpc.main.default_security_group_id
}

output "public_subnets" {
  description = "A map of all public subnets, with the subnet ID as the key, and all `aws-subnet` properties as the value."
  value = {
    for subnet in aws_subnet.public :
    subnet.id => subnet
  }
}

output "private_app_subnets" {
  description = "A map of all private-app subnets, with the subnet ID as the key, and all `aws-subnet` properties as the value."
  value = {
    for subnet in aws_subnet.private-app :
    subnet.id => subnet
  }
}

output "private_persistence_subnets" {
  description = "A map of all private-persistence subnets, with the subnet ID as the key, and all `aws-subnet` properties as the value."
  value = {
    for subnet in aws_subnet.private-persistence :
    subnet.id => subnet
  }
}

output "inspection_subnets" {
  description = "A map of all inspection subnets, with the subnet ID as the key, and all `aws-subnet` properties as the value."
  value = {
    for subnet in aws_subnet.inspection :
    subnet.id => subnet
  }
}

output "transit_subnets" {
  description = "A map of all transit subnets, with the subnet ID as the key, and all `aws-subnet` properties as the value."
  value = {
    for subnet in aws_subnet.transit :
    subnet.id => subnet
  }
}

output "public_subnet_cidr_blocks" {
  value = aws_subnet.public[*].cidr_block
}

output "public_subnet_ipv6_cidr_blocks" {
  value = aws_subnet.public[*].ipv6_cidr_block
}

output "private_app_subnet_cidr_blocks" {
  value = aws_subnet.private-app[*].cidr_block
}

output "private_persistence_subnet_cidr_blocks" {
  value = aws_subnet.private-persistence[*].cidr_block
}

output "inspection_subnet_cidr_blocks" {
  value = aws_subnet.inspection[*].cidr_block
}

output "transit_subnet_cidr_blocks" {
  value = aws_subnet.transit[*].cidr_block
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_app_subnet_ids" {
  value = aws_subnet.private-app[*].id
}

output "private_persistence_subnet_ids" {
  value = aws_subnet.private-persistence[*].id
}

output "inspection_subnet_ids" {
  value = aws_subnet.inspection[*].id
}

output "transit_subnet_ids" {
  value = aws_subnet.transit[*].id
}

output "public_subnet_arns" {
  value = aws_subnet.public[*].arn
}

output "private_app_subnet_arns" {
  value = aws_subnet.private-app[*].arn
}

output "private_persistence_subnet_arns" {
  value = aws_subnet.private-persistence[*].arn
}

output "inspection_subnet_arns" {
  value = aws_subnet.inspection[*].arn
}

output "transit_subnet_arns" {
  value = aws_subnet.transit[*].arn
}

output "default_route_table_id" {
  value = aws_default_route_table.default.id
}

output "public_subnet_route_table_id" {
  value = var.create_public_subnets ? aws_route_table.public[0].id : null
}

// A VPC can be created with one Route Table for all public subnets; or one route table per public subnet. This output
// prints out all the created route tables for public subnets, no matter how many have been created.
// The output `public_subnet_route_table_id` prints out only the first one (if it exists).
output "public_subnet_route_table_ids" {
  value = var.create_public_subnets ? aws_route_table.public[*].id : null
}

output "private_app_subnet_route_table_ids" {
  value = aws_route_table.private-app[*].id
}

// This output is identical to the private_app_subnet_route_table_ids output above. This one follows the naming
// conventions we use for the other outputs.
output "private_subnet_route_table_ids" {
  value = aws_route_table.private-app[*].id
}

// This output is identical to the private_persistence_subnet_route_table_ids output below. This one does not follow
// our naming conventions, but we keep it around to maintain backwards compatibility.
output "private_persistence_route_table_ids" {
  value = aws_route_table.private-persistence[*].id
}

output "inspection_route_table_ids" {
  value = aws_route_table.inspection[*].id
}

output "private_persistence_subnet_route_table_ids" {
  value = aws_route_table.private-persistence[*].id
}

output "inspection_subnet_route_table_ids" {
  value = aws_route_table.inspection[*].id
}

output "transit_subnet_route_table_ids" {
  value = aws_route_table.transit[*].id
}

output "internet_gateway_id" {
  value = aws_internet_gateway.main[*].id
}

output "nat_gateway_ids" {
  value = aws_nat_gateway.nat[*].id
}

output "nat_gateway_public_ips" {
  value = aws_eip.nat[*].public_ip
}

output "private_nat_gateway_ids" {
  value = aws_nat_gateway.private_nat[*].id
}

output "num_availability_zones" {
  value = local.num_availability_zones
}

output "availability_zones" {
  value = slice(data.aws_availability_zones.all.names, 0, local.num_availability_zones)
}

output "vpc_ready" {
  value = null_resource.vpc_ready.id
}


output "s3_vpc_endpoint_id" {
  value = var.create_vpc_endpoints ? aws_vpc_endpoint.s3[0].id : null
}

output "dynamodb_vpc_endpoint_id" {
  value = var.create_vpc_endpoints ? aws_vpc_endpoint.dynamodb[0].id : null
}

output "secondary_cidr_block_ids" {
  description = "Map of the secondary CIDR block associations with the VPC."
  value = {
    for association in aws_vpc_ipv4_cidr_block_association.secondary_cidr_block :
    association.cidr_block => association.id
  }
}

# Outputs for Network Firewall
output "subnets_attr_for_network_firewall" {
  description = "A map of subnet IDs to various attributes used for routing establishment purposes."
  value = merge(
    local.num_public_subnets > 0 ? {
      for item in aws_subnet.public : item.id =>
    { type = "public", cidr = item.cidr_block, az = item.availability_zone } } : {},

    local.num_private_app_subnets > 0 ? {
      for item in aws_subnet.private-app : item.id =>
    { type = "private", cidr = item.cidr_block, az = item.availability_zone } } : {},

    local.num_private_persistence_subnets > 0 ? {
      for item in aws_subnet.private-persistence : item.id =>
    { type = "persistence", cidr = item.cidr_block, az = item.availability_zone } } : {},

    local.num_inspection_subnets > 0 ? {
      for item in aws_subnet.inspection : item.id =>
    { type = "inspection", cidr = item.cidr_block, az = item.availability_zone } } : {},

    local.num_transit_subnets > 0 ? {
      for item in aws_subnet.transit : item.id =>
    { type = "transit", cidr = item.cidr_block, az = item.availability_zone } } : {}
  )
}

output "route_tables_for_network_firewall" {
  description = "A map of subnet IDs to routing tables IDs used for routing establishment purposes."
  value = merge(
    local.num_public_subnets > 0 ?
    { for item in aws_route_table_association.public : item.subnet_id => { rt = item.route_table_id } } : {},

    local.num_private_app_subnets > 0 ?
    { for item in aws_route_table_association.private-app : item.subnet_id => { rt = item.route_table_id } } : {},

    local.num_private_persistence_subnets > 0 ?
    { for item in aws_route_table_association.private-persistence : item.subnet_id => { rt = item.route_table_id } } : {},

    local.num_inspection_subnets > 0 ?
    { for item in aws_route_table_association.inspection : item.subnet_id => { rt = item.route_table_id } } : {},

    local.num_transit_subnets > 0 ?
    { for item in aws_route_table_association.transit : item.subnet_id => { rt = item.route_table_id } } : {},
  )
}

# Deprecated outputs
output "private_persistence_subnet_arn" {
  description = "DEPRECATED. Use `private_persistence_subnet_arns` instead."
  value       = aws_subnet.private-persistence[*].arn
}