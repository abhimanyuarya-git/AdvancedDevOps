data "aws_availability_zones" "all" {
  state            = var.availability_zone_state
  exclude_names    = var.availability_zone_exclude_names
  exclude_zone_ids = var.availability_zone_exclude_ids
}

data "aws_region" "current" {}

data "aws_vpc_ipam_pool" "ipv4" {
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
  count = try(length(var.ipv6_ipam_pool_filters), 0) > 0 ? 1 : 0

  dynamic "filter" {
    for_each = var.ipv6_ipam_pool_filters
    content {
      name   = filter.value.name
      values = filter.value.values
    }
  }
}
