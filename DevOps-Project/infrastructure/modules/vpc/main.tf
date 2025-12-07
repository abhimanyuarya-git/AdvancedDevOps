# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CREATE A VPC
# This Terraform template creates a full VPC meant to run apps. The VPC includes 3 types of subnets:
# - Public (one per AZ)
# - Private-App (one per AZ)
# - Private-Peristence (one per AZ)
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ---------------------------------------------------------------------------------------------------------------------
# SET TERRAFORM RUNTIME REQUIREMENTS
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  required_version = "~> 1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.1.0"
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# LOOKUP THE IPv4 and IPv6 IPAM POOLS
# If the user has provided a list of IPv4 or IPv6 IPAM pools, then we will use those. Otherwise, we will use the var.cidr_block
# ---------------------------------------------------------------------------------------------------------------------

locals {
  ipv4_ipam_pool_id = length(data.aws_vpc_ipam_pool.ipv4) > 0 ? data.aws_vpc_ipam_pool.ipv4[0].id : var.ipv4_ipam_pool_id
  ipv6_ipam_pool_id = length(data.aws_vpc_ipam_pool.ipv6) > 0 ? data.aws_vpc_ipam_pool.ipv6[0].id : var.ipv6_ipam_pool_id
}

data "aws_vpc_ipam_pool" "ipv4" {
  # Why do we use try here? The length function gives an error if you pass it null. So why not do:
  #   var.ipam_pool_filters != null && length(var.ipv4_ipam_pool_filters)
  # Because && is NOT short circuiting: https://github.com/hashicorp/terraform/issues/24128
  count = try(length(var.ipv4_ipam_pool_filters), 0) > 0 ? 1 : 0

  dynamic "filter" {
    for_each = var.ipv4_ipam_pool_filters
    content {
      name   = filter.value.name
      values = filter.value.values
    }
  }
}

data "aws_vpc_ipam_pool" "ipv6" {
  # Why do we use try here? The length function gives an error if you pass it null. So why not do:
  #   var.ipam_pool_filters != null && length(var.ipv6_ipam_pool_filters)
  # Because && is NOT short circuiting: https://github.com/hashicorp/terraform/issues/24128
  count = try(length(var.ipv6_ipam_pool_filters), 0) > 0 ? 1 : 0

  dynamic "filter" {
    for_each = var.ipv6_ipam_pool_filters
    content {
      name   = filter.value.name
      values = filter.value.values
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE VPC AND INTERNET GATEWAY
# ---------------------------------------------------------------------------------------------------------------------

# Create the VPC
resource "aws_vpc" "main" {
  #ts:skip=AC_AWS_0369 Flog logs can be configured using the vpc-flow-logs module in this repository
  cidr_block                           = var.cidr_block
  instance_tenancy                     = var.tenancy
  ipv4_ipam_pool_id                    = local.ipv4_ipam_pool_id
  ipv4_netmask_length                  = var.ipv4_netmask_length
  ipv6_cidr_block                      = var.ipv6_cidr_block
  ipv6_ipam_pool_id                    = local.ipv6_ipam_pool_id
  ipv6_netmask_length                  = var.ipv6_netmask_length
  ipv6_cidr_block_network_border_group = var.ipv6_cidr_block_network_border_group
  assign_generated_ipv6_cidr_block     = var.assign_generated_ipv6_cidr_block
  enable_dns_support                   = var.enable_dns_support
  enable_dns_hostnames                 = var.enable_dns_hostnames
  enable_network_address_usage_metrics = var.enable_network_address_usage_metrics
  tags = merge(
    { Name = var.vpc_name },
    var.custom_tags,
    var.vpc_custom_tags,
  )
}

# Create secondary CIDR blocks if set
resource "aws_vpc_ipv4_cidr_block_association" "secondary_cidr_block" {
  for_each = var.secondary_cidr_blocks

  cidr_block = each.key
  # TODO - Future feature add IPAM
  # ipv4_ipam_pool_id = var.ipv4_ipam_pool_id
  # ipv4_netmask_length = var.ipv4_netmask_length
  vpc_id = aws_vpc.main.id
}

# Assign DHCP Options if dhcp_options_id is set
resource "aws_vpc_dhcp_options_association" "dhcp_option_set" {
  count           = var.dhcp_options_id == null ? 0 : 1
  vpc_id          = aws_vpc.main.id
  dhcp_options_id = var.dhcp_options_id
}

# Create an Internet Gateway for our VPC
# The creation of the Internet Gateway is controlled
# by the variable create_igw
resource "aws_internet_gateway" "main" {
  count = var.create_public_subnets && var.create_igw ? 1 : 0

  vpc_id = aws_vpc.main.id
  tags = merge(
    { Name = "${var.vpc_name}-igw" },
    var.custom_tags,
  )
}

# Get a list of Availability Zones in the current region
data "aws_availability_zones" "all" {
  state            = var.availability_zone_state
  exclude_names    = var.availability_zone_exclude_names
  exclude_zone_ids = var.availability_zone_exclude_ids
}

# Get the current region
data "aws_region" "current" {}

# ---------------------------------------------------------------------------------------------------------------------
# CONFIGURE THE DEFAULT SECURITY GROUP, NETWORK ACLS, AND ROUTE TABLE
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_default_route_table" "default" {
  default_route_table_id = aws_vpc.main.default_route_table_id
  tags = merge(
    { Name = var.vpc_name },
    var.custom_tags
  )
}

# It's important that we add the outbound internet rule for the default route table, otherwise, it will not create it since
# we are explicitly creating the default route table:
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_route_table
resource "aws_route" "default_internet" {
  count = var.create_default_route_table_route && var.create_public_subnets && var.create_igw ? 1 : 0

  route_table_id         = aws_default_route_table.default.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main[0].id

  # A workaround for a series of eventual consistency bugs in Terraform. For a list of the errors, see the related
  # bugs described in this issue: https://github.com/hashicorp/terraform/issues/8542. The workaround is based on:
  # https://github.com/hashicorp/terraform/issues/5335 and https://charity.wtf/2016/04/14/scrapbag-of-useful-terraform-tips/
  depends_on = [
    aws_internet_gateway.main,
    aws_default_route_table.default,
  ]
}

resource "aws_route" "default_ipv6_internet" {
  count = var.create_default_route_table_route && var.create_public_subnets && var.create_igw && var.enable_ipv6 ? 1 : 0

  route_table_id              = aws_default_route_table.default.id
  destination_ipv6_cidr_block = "::/0"
  gateway_id                  = aws_internet_gateway.main[0].id

  # A workaround for a series of eventual consistency bugs in Terraform. For a list of the errors, see the related
  # bugs described in this issue: https://github.com/hashicorp/terraform/issues/8542. The workaround is based on:
  # https://github.com/hashicorp/terraform/issues/5335 and https://charity.wtf/2016/04/14/scrapbag-of-useful-terraform-tips/
  depends_on = [
    aws_internet_gateway.main,
    aws_default_route_table.default,
  ]
}

resource "aws_default_security_group" "default" {
  count = var.enable_default_security_group ? 1 : 0

  vpc_id = aws_vpc.main.id

  dynamic "ingress" {
    for_each = var.default_security_group_ingress_rules
    content {
      from_port        = ingress.value["from_port"]
      to_port          = ingress.value["to_port"]
      protocol         = ingress.value["protocol"]
      cidr_blocks      = lookup(ingress.value, "cidr_blocks", null)
      ipv6_cidr_blocks = lookup(ingress.value, "ipv6_cidr_blocks", null)
      security_groups  = lookup(ingress.value, "security_groups", null)
      self             = lookup(ingress.value, "self", null)
      prefix_list_ids  = lookup(ingress.value, "prefix_list_ids", null)
      description      = lookup(ingress.value, "description", null)
    }
  }

  dynamic "egress" {
    for_each = var.default_security_group_egress_rules
    content {
      from_port        = egress.value["from_port"]
      to_port          = egress.value["to_port"]
      protocol         = egress.value["protocol"]
      cidr_blocks      = lookup(egress.value, "cidr_blocks", null)
      ipv6_cidr_blocks = lookup(egress.value, "ipv6_cidr_blocks", null)
      security_groups  = lookup(egress.value, "security_groups", null)
      self             = lookup(egress.value, "self", null)
      prefix_list_ids  = lookup(egress.value, "prefix_list_ids", null)
      description      = lookup(egress.value, "description", null)
    }
  }

  tags = merge(
    { Name = var.vpc_name },
    var.custom_tags,
    var.security_group_tags,
  )
}

resource "aws_default_network_acl" "default" {
  count = var.apply_default_nacl_rules ? 1 : 0

  default_network_acl_id = aws_vpc.main.default_network_acl_id
  subnet_ids = (
    var.associate_default_nacl_to_subnets
    ? sort(concat(
      aws_subnet.public[*].id,
      aws_subnet.private-app[*].id,
      aws_subnet.private-persistence[*].id
    ))
    : []
  )

  dynamic "ingress" {
    for_each = var.default_nacl_ingress_rules
    content {
      from_port       = ingress.value["from_port"]
      to_port         = ingress.value["to_port"]
      protocol        = ingress.value["protocol"]
      action          = ingress.value["action"]
      rule_no         = ingress.value["rule_no"]
      cidr_block      = lookup(ingress.value, "cidr_block", null)
      ipv6_cidr_block = lookup(ingress.value, "ipv6_cidr_block", null)
      icmp_type       = lookup(ingress.value, "icmp_type", null)
      icmp_code       = lookup(ingress.value, "icmp_code", null)
    }
  }

  dynamic "egress" {
    for_each = var.default_nacl_egress_rules
    content {
      from_port       = egress.value["from_port"]
      to_port         = egress.value["to_port"]
      protocol        = egress.value["protocol"]
      action          = egress.value["action"]
      rule_no         = egress.value["rule_no"]
      cidr_block      = lookup(egress.value, "cidr_block", null)
      ipv6_cidr_block = lookup(egress.value, "ipv6_cidr_block", null)
      icmp_type       = lookup(egress.value, "icmp_type", null)
      icmp_code       = lookup(egress.value, "icmp_code", null)
    }
  }

  tags = merge(
    { Name = var.vpc_name },
    var.custom_tags,
  )
}


# ---------------------------------------------------------------------------------------------------------------------
# CREATE PUBLIC SUBNETS
# Any resource that must be addressable from the public Internet should be placed in a Public Subnet.  E.g. ELB's, web
# servers, etc.
# ---------------------------------------------------------------------------------------------------------------------

locals {
  num_public_subnets = var.create_public_subnets ? local.num_availability_zones : 0
}

# Create public subnets, one per Availability Zone
resource "aws_subnet" "public" {
  count = local.num_public_subnets

  vpc_id = aws_vpc.main.id

  # Depending on if user has requested specific availability_zone_ids, use those.
  # Note that we use element instead of [] here for wrap around behavior
  availability_zone    = var.availability_zone_ids == null ? element(data.aws_availability_zones.all.names, count.index) : null
  availability_zone_id = var.availability_zone_ids == null ? null : element(var.availability_zone_ids, count.index)

  cidr_block = try(
    var.public_subnet_cidr_blocks["AZ-${count.index}"],
    cidrsubnet(aws_vpc.main.cidr_block, var.public_subnet_bits, count.index),
  )
  map_public_ip_on_launch = var.map_public_ip_on_launch

  # IPv6 configuration
  assign_ipv6_address_on_creation = var.assign_ipv6_address_on_creation
  ipv6_cidr_block = var.enable_ipv6 ? try(
    var.public_subnet_ipv6_cidr_blocks["AZ-${count.index}"],
    cidrsubnet(aws_vpc.main.ipv6_cidr_block, var.ipv6_subnet_bits, count.index),
  ) : null

  tags = merge(
    { Name = "${var.vpc_name}-${var.public_subnet_name}-${count.index}" },
    var.custom_tags,
    var.public_subnet_custom_tags,
  )

  depends_on = [aws_vpc_ipv4_cidr_block_association.secondary_cidr_block]
}

# Create a Route Table for public subnets
# - This routes all public traffic through the Internet gateway
# - Depending on the var.one_route_table_public_subnets, it will create one table for all subnets, or one table per subnet
# - All traffic to endpoints within the VPC is by default routed w/o going through the dirty Internet
# - If Virtual Private Gateways are provided, traffic destined for VPN routes associated with the gateway are routed through the
#   Virtual Private Gateway rather than the public internet.
resource "aws_route_table" "public" {
  count = (
    var.create_public_subnets
    ? (var.one_route_table_public_subnets ? 1 : local.num_availability_zones)
    : 0
  )

  vpc_id = aws_vpc.main.id

  propagating_vgws = var.public_propagating_vgws

  tags = merge(
    { Name = (
      var.one_route_table_public_subnets
      ? "${var.vpc_name}-${var.public_subnet_name}"
      : "${var.vpc_name}-${var.public_subnet_name}-${count.index}")
    },
    var.custom_tags,
    var.public_route_table_custom_tags,
  )

  timeouts {
    create = var.route_table_creation_timeout
    update = var.route_table_update_timeout
    delete = var.route_table_deletion_timeout
  }
}

# It's important that we define this route as a separate terraform resource and not inline in aws_route_table.public because
# otherwise Terraform will not function correctly, per the note at https://www.terraform.io/docs/providers/aws/r/route.html.
resource "aws_route" "internet" {
  count = (
    var.create_public_subnets && var.create_igw
    ? (var.one_route_table_public_subnets ? 1 : local.num_availability_zones)
    : 0
  )

  route_table_id         = aws_route_table.public[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main[0].id

  # A workaround for a series of eventual consistency bugs in Terraform. For a list of the errors, see the related
  # bugs described in this issue: https://github.com/hashicorp/terraform/issues/8542. The workaround is based on:
  # https://github.com/hashicorp/terraform/issues/5335 and https://charity.wtf/2016/04/14/scrapbag-of-useful-terraform-tips/
  depends_on = [
    aws_internet_gateway.main,
    aws_route_table.public,
  ]

  # Workaround for https://github.com/terraform-providers/terraform-provider-aws/issues/338
  timeouts {
    create = "5m"
  }
}

resource "aws_route" "ipv6_default_gateway" {
  count = (
    var.create_public_subnets && var.create_igw
    ? (var.one_route_table_public_subnets ? 1 : local.num_availability_zones)
    : 0
  )

  route_table_id              = aws_route_table.public[count.index].id
  destination_ipv6_cidr_block = "::/0"
  gateway_id                  = aws_internet_gateway.main[0].id

  # A workaround for a series of eventual consistency bugs in Terraform. For a list of the errors, see the related
  # bugs described in this issue: https://github.com/hashicorp/terraform/issues/8542. The workaround is based on:
  # https://github.com/hashicorp/terraform/issues/5335 and https://charity.wtf/2016/04/14/scrapbag-of-useful-terraform-tips/
  depends_on = [
    aws_internet_gateway.main,
    aws_route_table.public,
  ]

  # Workaround for https://github.com/terraform-providers/terraform-provider-aws/issues/338
  timeouts {
    create = "5m"
  }
}

# Associate each public subnet with a public route table
# In case of creating only one route table, all subnets will be associated with it
# In case of creating one route table per public subnet, each subnet will be associated
# with its respective route table
resource "aws_route_table_association" "public" {
  count = local.num_public_subnets

  subnet_id = aws_subnet.public[count.index].id
  route_table_id = (
    var.one_route_table_public_subnets
    ? aws_route_table.public[0].id
    : aws_route_table.public[count.index].id
  )
}

# ---------------------------------------------------------------------------------------------------------------------
# LAUNCH THE NAT GATEWAYS
# A NAT Gateway enables instances in the private subnet to connect to the Internet or other AWS services, but prevents
# the Internet from initiating a connection to those instances.
#
# When launching a development VPC, route all traffic through a single NAT Gateway in one Availability Zone to save
# money.  When launching a production VPC, route traffic through one NAT Gateway per Availability Zone for maximum
# availability.
#
# See http://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/vpc-nat-gateway.html
# ---------------------------------------------------------------------------------------------------------------------

locals {
  create_nat_eips   = var.create_public_subnets && var.use_custom_nat_eips == false ? var.num_nat_gateways : 0
  count_public_nat  = var.create_public_subnets && var.enable_private_nat != true ? var.num_nat_gateways : 0
  count_private_nat = var.enable_private_nat == true ? var.num_nat_gateways : 0
}

# A NAT Gateway must be associated with an Elastic IP Address
resource "aws_eip" "nat" {
  count      = local.create_nat_eips
  domain     = "vpc"
  tags       = var.custom_tags
  depends_on = [aws_internet_gateway.main]
}
resource "aws_eip" "nat_secondary_eip" {
  count      = var.create_nat_secondary_eip ? local.count_public_nat : 0
  domain     = "vpc"
  tags       = var.custom_tags
  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "nat" {
  count = local.count_public_nat

  # Use element instead of [] due to wrap around behavior (E.g., there may be more nat gateways than availability zones requested)
  allocation_id            = element(local.nat_eips, count.index)
  private_ip               = var.nat_private_ip_host_num == null ? null : cidrhost(aws_subnet.public[count.index].cidr_block, var.nat_private_ip_host_num)
  subnet_id                = element(aws_subnet.public.*.id, count.index)
  secondary_allocation_ids = var.create_nat_secondary_eip ? [element(aws_eip.nat_secondary_eip.*.id, count.index)] : []

  tags = merge(
    { Name = "${var.vpc_name}-nat-gateway-${count.index}" },
    var.custom_tags,
    var.nat_gateway_custom_tags,
  )

  # As recommended by the Terraform docs: https://www.terraform.io/docs/providers/aws/r/nat_gateway.html
  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "private_nat" {
  count = local.count_private_nat

  connectivity_type                  = "private"
  private_ip                         = var.nat_private_ip_host_num == null ? null : cidrhost(aws_subnet.transit[count.index].cidr_block, var.nat_private_ip_host_num)
  secondary_private_ip_address_count = var.nat_secondary_private_ip_address_count
  subnet_id                          = element(aws_subnet.transit.*.id, count.index)

  tags = merge(
    { Name = "${var.vpc_name}-private-nat-gateway-${count.index}" },
    var.custom_tags,
    var.nat_gateway_custom_tags,
  )

  lifecycle {
    precondition {
      condition     = var.create_transit_subnets == true
      error_message = "Cannot create a private NAT gateway without enabling transit subnets. Set 'var.create_transit_subnets = true' to enable transit subnets."
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE PRIVATE SUBNETS AT THE "APP" TIER
# These subnets are private and meant to house any application/service that does not require direct connectivity from
# users.  Includes app servers, queue processors, reporting systems, etc.
# ---------------------------------------------------------------------------------------------------------------------

locals {
  num_private_app_subnets = var.create_private_app_subnets ? local.num_availability_zones : 0
  count_private_nat_route = (
    var.create_private_app_subnets && var.create_public_subnets && var.allow_private_app_internet_access && var.num_nat_gateways > 0 && !var.enable_private_nat && !var.create_inspection_subnets
    ? local.num_availability_zones
    : 0
  )
}

# Create a private subnets per AZ for our "App" tier
resource "aws_subnet" "private-app" {
  count = local.num_private_app_subnets

  vpc_id = aws_vpc.main.id

  # Depending on if user has requested specific availability_zone_ids, use those.
  # Note that we use element instead of [] here for wrap around behavior
  availability_zone    = var.availability_zone_ids == null ? element(data.aws_availability_zones.all.names, count.index) : null
  availability_zone_id = var.availability_zone_ids == null ? null : element(var.availability_zone_ids, count.index)

  cidr_block = try(
    var.private_app_subnet_cidr_blocks["AZ-${count.index}"],
    cidrsubnet(aws_vpc.main.cidr_block, var.private_subnet_bits, count.index + local.private_spacing),
  )

  tags = merge(
    { Name = "${var.vpc_name}-${var.private_subnet_name}-${count.index}" },
    var.custom_tags,
    var.private_app_subnet_custom_tags,
  )

  depends_on = [aws_vpc_ipv4_cidr_block_association.secondary_cidr_block]
}

# Create a Route Table for each private app subnet
# - All traffic to endpoints within the subnet to which this is attached will be enabled by default
# - For all non-VPC traffic (i.e. public Internet) traffic, we'll route this to the NAT instance for this Availability
#   Zone.
# - If Virtual Private Gateways are provided, traffic destined for VPN routes associated with the gateway are routed through the
#   Virtual Private Gateway.
# Note that we need not specify any routing rules for this here because our HA NAT Instance will automatically update
# the Route Table upon booting.
resource "aws_route_table" "private-app" {
  count = local.num_private_app_subnets

  vpc_id = aws_vpc.main.id

  propagating_vgws = var.private_propagating_vgws

  tags = merge(
    { Name = "${var.vpc_name}-${var.private_subnet_name}-${count.index}" },
    var.custom_tags,
    var.private_app_route_table_custom_tags,
  )

  timeouts {
    create = var.route_table_creation_timeout
    update = var.route_table_update_timeout
    delete = var.route_table_deletion_timeout
  }
}

# Create a route for outbound Internet traffic.
resource "aws_route" "nat" {
  count = local.count_private_nat_route

  route_table_id         = aws_route_table.private-app[count.index].id
  destination_cidr_block = "0.0.0.0/0"

  # We use element instead of [] for the wraparound behavior, since there may be less NAT gateways than there are
  # availability zones.
  nat_gateway_id = element(aws_nat_gateway.nat.*.id, count.index)

  # A workaround for a series of eventual consistency bugs in Terraform. For a list of the errors, see the related
  # bugs described in this issue: https://github.com/hashicorp/terraform/issues/8542. The workaround is based on:
  # https://github.com/hashicorp/terraform/issues/5335 and https://charity.wtf/2016/04/14/scrapbag-of-useful-terraform-tips/
  depends_on = [
    aws_internet_gateway.main,
    aws_route_table.private-app,
  ]

  # Workaround for https://github.com/terraform-providers/terraform-provider-aws/issues/338
  timeouts {
    create = "5m"
  }
}

resource "aws_route" "private_nat" {
  count = local.count_private_nat

  route_table_id         = aws_route_table.private-app[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.private_nat.*.id, count.index)
}

# Associate each private-app subnet with its respective route table
resource "aws_route_table_association" "private-app" {
  count = local.num_private_app_subnets

  subnet_id      = aws_subnet.private-app[count.index].id
  route_table_id = aws_route_table.private-app[count.index].id
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE PRIVATE SUBNETS AT THE "PERSISTENCE" TIER
# These subnets are private and meant to house any persistence resources. This includes Relational Databases, Cache,
# NoSQL Databases, etc.
# ---------------------------------------------------------------------------------------------------------------------

locals {
  num_private_persistence_subnets = var.create_private_persistence_subnets ? local.num_availability_zones : 0
  count_private_persistence_nat_route = (
    var.create_private_persistence_subnets && var.create_public_subnets && var.allow_private_persistence_internet_access && var.num_nat_gateways > 0 && !var.enable_private_nat && !var.create_inspection_subnets
    ? local.num_availability_zones
    : 0
  )
}

# Create one private subnet per AZ for our "Persistence" tier
resource "aws_subnet" "private-persistence" {
  depends_on = [aws_vpc_ipv4_cidr_block_association.secondary_cidr_block]
  count      = local.num_private_persistence_subnets

  vpc_id = aws_vpc.main.id

  # Depending on if user has requested specific availability_zone_ids, use those.
  # Note that we use element instead of [] here for wrap around behavior
  availability_zone    = var.availability_zone_ids == null ? element(data.aws_availability_zones.all.names, count.index) : null
  availability_zone_id = var.availability_zone_ids == null ? null : element(var.availability_zone_ids, count.index)

  cidr_block = try(
    var.private_persistence_subnet_cidr_blocks["AZ-${count.index}"],
    cidrsubnet(aws_vpc.main.cidr_block, var.persistence_subnet_bits, count.index + local.persistence_spacing),
  )

  tags = merge(
    { Name = "${var.vpc_name}-${var.private_persistence_subnet_name}-${count.index}" },
    var.custom_tags,
    var.private_persistence_subnet_custom_tags,
  )
}

# Create a Route Table for each private persistence subnet
# - All traffic to endpoints within the subnet to which this is attached will be enabled by default
# - No public Internet traffic is permitted, in or out.
# - If Virtual Private Gateways are provided, traffic destined for VPN routes associated with the gateway are routed through the
#   Virtual Private Gateway.
resource "aws_route_table" "private-persistence" {
  count = local.num_private_persistence_subnets

  vpc_id = aws_vpc.main.id

  propagating_vgws = var.persistence_propagating_vgws

  tags = merge(
    { Name = "${var.vpc_name}-${var.private_persistence_subnet_name}-${count.index}" },
    var.custom_tags,
    var.private_persistence_route_table_custom_tags,
  )

  timeouts {
    create = var.route_table_creation_timeout
    update = var.route_table_update_timeout
    delete = var.route_table_deletion_timeout
  }
}

# Create a route for outbound Internet traffic.
resource "aws_route" "private_persistence_nat" {
  count = local.count_private_persistence_nat_route

  route_table_id         = element(aws_route_table.private-persistence.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.nat.*.id, count.index)

  # A workaround for a series of eventual consistency bugs in Terraform. For a list of the errors, see the related
  # bugs described in this issue: https://github.com/hashicorp/terraform/issues/8542. The workaround is based on:
  # https://github.com/hashicorp/terraform/issues/5335 and https://charity.wtf/2016/04/14/scrapbag-of-useful-terraform-tips/
  depends_on = [
    aws_internet_gateway.main,
    aws_route_table.private-persistence,
  ]

  # Workaround for https://github.com/terraform-providers/terraform-provider-aws/issues/338
  timeouts {
    create = "5m"
  }
}

resource "aws_route" "private_persistence_private_nat" {
  count = local.count_private_nat

  route_table_id         = aws_route_table.private-persistence[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.private_nat.*.id, count.index)
}

# Associate each private-persistence subnet with its respective route table
resource "aws_route_table_association" "private-persistence" {
  count = local.num_private_persistence_subnets

  subnet_id      = aws_subnet.private-persistence[count.index].id
  route_table_id = aws_route_table.private-persistence[count.index].id
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE INSPECTION SUBNETS
# These subnets are meant to house any inspection endpoints. This includes Network Firewall, WAF, etc.
# - Create one inspection subnet per AZ
# - Create a Route Table for each inspection subnet
# - Associate each inspection subnet with its respective route table
# - Create a route for outbound Internet traffic
# ---------------------------------------------------------------------------------------------------------------------
locals {
  num_inspection_subnets = var.create_inspection_subnets ? local.num_availability_zones : 0
  count_inspection_nat_route = (
    var.create_inspection_subnets && var.create_public_subnets && var.allow_inspection_internet_access && var.num_nat_gateways > 0
    ? local.num_availability_zones
    : 0
  )
}

resource "aws_subnet" "inspection" {
  count = local.num_inspection_subnets

  vpc_id = aws_vpc.main.id

  # Depending on if user has requested specific availability_zone_ids, use those.
  # Note that we use element instead of [] here for wrap around behavior
  availability_zone    = var.availability_zone_ids == null ? element(data.aws_availability_zones.all.names, count.index) : null
  availability_zone_id = var.availability_zone_ids == null ? null : element(var.availability_zone_ids, count.index)

  cidr_block = try(
    var.inspection_subnet_cidr_blocks["AZ-${count.index}"],
    cidrsubnet(aws_vpc.main.cidr_block, var.inspection_subnet_bits, count.index + local.inspection_spacing),
  )

  tags = merge(
    { Name = "${var.vpc_name}-${var.inspection_subnet_name}-${count.index}" },
    var.custom_tags,
    var.inspection_subnet_custom_tags,
  )
}

resource "aws_route_table" "inspection" {
  count = local.num_inspection_subnets

  vpc_id = aws_vpc.main.id

  propagating_vgws = var.inspection_propagating_vgws

  tags = merge(
    { Name = "${var.vpc_name}-${var.inspection_subnet_name}-${count.index}" },
    var.custom_tags,
    var.inspection_route_table_custom_tags,
  )

  timeouts {
    create = var.route_table_creation_timeout
    update = var.route_table_update_timeout
    delete = var.route_table_deletion_timeout
  }
}

resource "aws_route_table_association" "inspection" {
  count          = local.num_inspection_subnets
  subnet_id      = aws_subnet.inspection[count.index].id
  route_table_id = aws_route_table.inspection[count.index].id
}

resource "aws_route" "inspection_nat" {
  count = local.count_inspection_nat_route

  route_table_id         = element(aws_route_table.inspection[*].id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.nat[*].id, count.index)

  # A workaround for a series of eventual consistency bugs in Terraform. For a list of the errors, see the related
  # bugs described in this issue: https://github.com/hashicorp/terraform/issues/8542. The workaround is based on:
  # https://github.com/hashicorp/terraform/issues/5335 and https://charity.wtf/2016/04/14/scrapbag-of-useful-terraform-tips/
  depends_on = [
    aws_internet_gateway.main,
    aws_route_table.inspection,
  ]

  # Workaround for https://github.com/terraform-providers/terraform-provider-aws/issues/338
  timeouts {
    create = "5m"
  }
}


# ---------------------------------------------------------------------------------------------------------------------
# CREATE TRANSIT SUBNETS
# These subnets are private and meant to house network transit resources. This includes transit gateways, private NAT gateways, or network appliances.
# ---------------------------------------------------------------------------------------------------------------------

locals {
  num_transit_subnets = var.create_transit_subnets ? local.num_availability_zones : 0
}

# Create one transit subnet per AZ for our "Transit" tier
resource "aws_subnet" "transit" {

  count = local.num_transit_subnets

  vpc_id = aws_vpc.main.id

  # Depending on if user has requested specific availability_zone_ids, use those.
  # Note that we use element instead of [] here for wrap around behavior
  availability_zone    = var.availability_zone_ids == null ? element(data.aws_availability_zones.all.names, count.index) : null
  availability_zone_id = var.availability_zone_ids == null ? null : element(var.availability_zone_ids, count.index)

  cidr_block = try(
    var.transit_subnet_cidr_blocks["AZ-${count.index}"],
    cidrsubnet(aws_vpc.main.cidr_block, var.transit_subnet_bits, count.index + local.transit_spacing),
  )

  tags = merge(
    { Name = "${var.vpc_name}-${var.transit_subnet_name}-${count.index}" },
    var.custom_tags,
    var.transit_subnet_custom_tags,
  )

  depends_on = [aws_vpc_ipv4_cidr_block_association.secondary_cidr_block]
}

# Create a Route Table for each transit subnet
# - All traffic to endpoints within the subnet to which this is attached will be enabled by default
# - No public internet traffic is permitted in.
# - If Virtual Private Gateways are provided, traffic destined for VPN routes associated with the gateway are routed through the
#   Virtual Private Gateway.
resource "aws_route_table" "transit" {
  count = local.num_transit_subnets

  vpc_id = aws_vpc.main.id

  propagating_vgws = var.transit_propagating_vgws

  tags = merge(
    { Name = "${var.vpc_name}-${var.transit_subnet_name}-${count.index}" },
    var.custom_tags,
    var.transit_route_table_custom_tags,
  )

  timeouts {
    create = var.route_table_creation_timeout
    update = var.route_table_update_timeout
    delete = var.route_table_deletion_timeout
  }
}

# Create a route for outbound Internet traffic.
resource "aws_route" "transit_nat" {
  count = (
    var.create_transit_subnets && var.create_public_subnets && var.allow_transit_internet_access && var.num_nat_gateways > 0
    ? local.num_availability_zones
    : 0
  )

  route_table_id         = element(aws_route_table.transit.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.nat.*.id, count.index)

  # A workaround for a series of eventual consistency bugs in Terraform. For a list of the errors, see the related
  # bugs described in this issue: https://github.com/hashicorp/terraform/issues/8542. The workaround is based on:
  # https://github.com/hashicorp/terraform/issues/5335 and https://charity.wtf/2016/04/14/scrapbag-of-useful-terraform-tips/
  depends_on = [
    aws_internet_gateway.main,
    aws_route_table.transit,
  ]

  # Workaround for https://github.com/terraform-providers/terraform-provider-aws/issues/338
  timeouts {
    create = "5m"
  }
}

# Associate each transit subnet with its respective route table
resource "aws_route_table_association" "transit" {
  count = local.num_transit_subnets

  subnet_id      = aws_subnet.transit[count.index].id
  route_table_id = aws_route_table.transit[count.index].id
}

# ---------------------------------------------------------------------------------------------------------------------
# SETUP VPC ENDPOINTS
# This ensures that all requests to the AWS API for S3 and DynamoDB are routed through the VPC instead of the Public
# Internet. We use aws_vpc_endpoint_route_table_association resources rather than associating route tables directly
# in the aws_vpc_endpoint resource to avoid dependency errors when modifying route tables.
# See: https://github.com/gruntwork-io/terraform-aws-vpc/pull/89
#      https://github.com/gruntwork-io/terraform-aws-vpc/issues/49
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_vpc_endpoint" "s3" {
  count = var.create_vpc_endpoints ? 1 : 0

  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.s3"
  policy       = var.s3_endpoint_policy
  tags         = merge({ Name = "${aws_vpc.main.id}-s3-endpoint" }, var.custom_tags)
}

resource "aws_vpc_endpoint_route_table_association" "s3_public" {
  count = var.create_vpc_endpoints && var.create_public_subnets ? 1 : 0

  vpc_endpoint_id = aws_vpc_endpoint.s3[0].id
  route_table_id  = aws_route_table.public[0].id
}

resource "aws_vpc_endpoint_route_table_association" "s3_private" {
  count = var.create_vpc_endpoints ? local.num_private_app_subnets : 0

  vpc_endpoint_id = aws_vpc_endpoint.s3[0].id
  route_table_id  = aws_route_table.private-app[count.index].id
}

resource "aws_vpc_endpoint_route_table_association" "s3_persistence" {
  count = var.create_vpc_endpoints ? local.num_private_persistence_subnets : 0

  vpc_endpoint_id = aws_vpc_endpoint.s3[0].id
  route_table_id  = aws_route_table.private-persistence[count.index].id
}

resource "aws_vpc_endpoint_route_table_association" "s3_inspection" {
  count = var.create_vpc_endpoints ? local.num_inspection_subnets : 0

  vpc_endpoint_id = aws_vpc_endpoint.s3[0].id
  route_table_id  = aws_route_table.inspection[count.index].id
}

resource "aws_vpc_endpoint_route_table_association" "s3_transit" {
  count = var.create_vpc_endpoints ? local.num_transit_subnets : 0

  vpc_endpoint_id = aws_vpc_endpoint.s3[0].id
  route_table_id  = aws_route_table.transit[count.index].id
}

resource "aws_vpc_endpoint" "dynamodb" {
  count = var.create_vpc_endpoints ? 1 : 0

  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.dynamodb"
  policy       = var.dynamodb_endpoint_policy
  tags         = merge({ Name = "${aws_vpc.main.id}-dynamodb-endpoint" }, var.custom_tags)
}

resource "aws_vpc_endpoint_route_table_association" "dynamodb_public" {
  count = var.create_vpc_endpoints && var.create_public_subnets ? 1 : 0

  vpc_endpoint_id = aws_vpc_endpoint.dynamodb[0].id
  route_table_id  = aws_route_table.public[0].id
}

resource "aws_vpc_endpoint_route_table_association" "dynamodb_private" {
  count = var.create_vpc_endpoints ? local.num_private_app_subnets : 0

  vpc_endpoint_id = aws_vpc_endpoint.dynamodb[0].id
  route_table_id  = aws_route_table.private-app[count.index].id
}

resource "aws_vpc_endpoint_route_table_association" "dynamodb_persistence" {
  count = var.create_vpc_endpoints ? local.num_private_persistence_subnets : 0

  vpc_endpoint_id = aws_vpc_endpoint.dynamodb[0].id
  route_table_id  = aws_route_table.private-persistence[count.index].id
}

resource "aws_vpc_endpoint_route_table_association" "dynamodb_inspection" {
  count = var.create_vpc_endpoints ? local.num_inspection_subnets : 0

  vpc_endpoint_id = aws_vpc_endpoint.dynamodb[0].id
  route_table_id  = aws_route_table.inspection[count.index].id
}

resource "aws_vpc_endpoint_route_table_association" "dynamodb_transit" {
  count = var.create_vpc_endpoints ? local.num_transit_subnets : 0

  vpc_endpoint_id = aws_vpc_endpoint.dynamodb[0].id
  route_table_id  = aws_route_table.transit[count.index].id
}

# ---------------------------------------------------------------------------------------------------------------------
# USE A NULL RESOURCE TO INDICATE THAT THE VPC HAS FINISHED CREATING
# Other resources can depend on this one to make sure they don't create anything in the VPC before it's ready. This
# can help to work around a Terraform or AWS issue where trying to create certain resources, such as Network ACLs,
# before the VPC's Gateway and NATs are ready, leads to a huge variety of eventual consistency bugs.
# ---------------------------------------------------------------------------------------------------------------------

resource "null_resource" "vpc_ready" {
  depends_on = [
    aws_internet_gateway.main,
    aws_vpc_ipv4_cidr_block_association.secondary_cidr_block,
    aws_nat_gateway.nat,
    aws_route.internet,
    aws_route.nat,
  ]
}

# ---------------------------------------------------------------------------------------------------------------------
# CONVENIENCE VARIABLES
# ---------------------------------------------------------------------------------------------------------------------

locals {
  # We will use the num_availability_zones variable input if it is set. Otherwise, check if availability_zone_ids is set
  # by the user, and if it is, use that. Finally, fall back to checking all the availability zones that AWS has for the
  # configured region.
  num_availability_zones = (
    var.num_availability_zones == null
    ? (
      var.availability_zone_ids == null
      ? length(data.aws_availability_zones.all.names)
      : length(var.availability_zone_ids)
    )
    : min(var.num_availability_zones, length(data.aws_availability_zones.all.names))
  )

  # This local variable is used to determine if we should use the global subnet spacing or the previous default subnet spacing.
  # Using additional subnets requires shifting the spacing down to the maximum quantity of availability zones, six.
  subnet_spacing_selector = var.create_transit_subnets || var.create_inspection_subnets ? var.global_subnet_spacing : var.subnet_spacing
  private_spacing         = var.private_subnet_spacing != null ? var.private_subnet_spacing : local.subnet_spacing_selector
  persistence_spacing     = var.persistence_subnet_spacing != null ? var.persistence_subnet_spacing : 2 * local.subnet_spacing_selector
  transit_spacing         = var.transit_subnet_spacing != null ? var.transit_subnet_spacing : 3 * local.subnet_spacing_selector
  inspection_spacing      = var.inspection_subnet_spacing != null ? var.inspection_subnet_spacing : 4 * local.subnet_spacing_selector
  nat_eips                = var.use_custom_nat_eips ? var.custom_nat_eips : aws_eip.nat[*].id
}