locals {
  # IPAM Pool IDs
  ipv4_ipam_pool_id = length(data.aws_vpc_ipam_pool.ipv4) > 0 ? data.aws_vpc_ipam_pool.ipv4[0].id : var.ipv4_ipam_pool_id
  ipv6_ipam_pool_id = length(data.aws_vpc_ipam_pool.ipv6) > 0 ? data.aws_vpc_ipam_pool.ipv6[0].id : var.ipv6_ipam_pool_id

  # Availability Zones
  num_availability_zones = (
    var.num_availability_zones == null
    ? (var.availability_zone_ids == null ? length(data.aws_availability_zones.all.names) : length(var.availability_zone_ids))
    : min(var.num_availability_zones, length(data.aws_availability_zones.all.names))
  )

  # Subnet Counts
  num_public_subnets              = var.create_public_subnets ? local.num_availability_zones : 0
  num_private_app_subnets         = var.create_private_app_subnets ? local.num_availability_zones : 0
  num_private_persistence_subnets = var.create_private_persistence_subnets ? local.num_availability_zones : 0
  num_inspection_subnets          = var.create_inspection_subnets ? local.num_availability_zones : 0
  num_transit_subnets             = var.create_transit_subnets ? local.num_availability_zones : 0

  # Subnet Spacing
  subnet_spacing_selector = var.create_transit_subnets || var.create_inspection_subnets ? var.global_subnet_spacing : var.subnet_spacing
  private_spacing         = var.private_subnet_spacing != null ? var.private_subnet_spacing : local.subnet_spacing_selector
  persistence_spacing     = var.persistence_subnet_spacing != null ? var.persistence_subnet_spacing : 2 * local.subnet_spacing_selector
  transit_spacing         = var.transit_subnet_spacing != null ? var.transit_subnet_spacing : 3 * local.subnet_spacing_selector
  inspection_spacing      = var.inspection_subnet_spacing != null ? var.inspection_subnet_spacing : 4 * local.subnet_spacing_selector

  # NAT Gateway Configuration
  create_nat_eips   = var.create_public_subnets && var.use_custom_nat_eips == false ? var.num_nat_gateways : 0
  count_public_nat  = var.create_public_subnets && var.enable_private_nat != true ? var.num_nat_gateways : 0
  count_private_nat = var.enable_private_nat == true ? var.num_nat_gateways : 0
  nat_eips          = var.use_custom_nat_eips ? var.custom_nat_eips : aws_eip.nat[*].id

  # Route Counts
  count_private_nat_route = (
    var.create_private_app_subnets && var.create_public_subnets && var.allow_private_app_internet_access && var.num_nat_gateways > 0 && !var.enable_private_nat && !var.create_inspection_subnets
    ? local.num_availability_zones
    : 0
  )

  count_private_persistence_nat_route = (
    var.create_private_persistence_subnets && var.create_public_subnets && var.allow_private_persistence_internet_access && var.num_nat_gateways > 0 && !var.enable_private_nat && !var.create_inspection_subnets
    ? local.num_availability_zones
    : 0
  )

  count_inspection_nat_route = (
    var.create_inspection_subnets && var.create_public_subnets && var.allow_inspection_internet_access && var.num_nat_gateways > 0
    ? local.num_availability_zones
    : 0
  )
}
