# ----------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These variables are expected to be passed in by the operator when calling this
# terraform module.
# ----------------------------------------------------------------------------------------------------------------------

variable "vpc_name" {
  description = "Name of the VPC. Examples include 'prod', 'dev', 'mgmt', etc."
  type        = string
}

variable "cidr_block" {
  description = "The IP address range of the VPC in CIDR notation. A prefix of /16 is recommended. Do not use a prefix higher than /27. Examples include '10.100.0.0/16', '10.200.0.0/16', etc."
  type        = string
}

variable "num_nat_gateways" {
  description = "The number of NAT Gateways to launch for this VPC. For production VPCs, a NAT Gateway should be placed in each Availability Zone (so likely 3 total), whereas for non-prod VPCs, just one Availability Zone (and hence 1 NAT Gateway) will suffice."
  type        = number
}

# ----------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters are useful for additional customization of the VPC. Otherwise, they default to sane values.
# ----------------------------------------------------------------------------------------------------------------------

variable "num_availability_zones" {
  description = "How many AWS Availability Zones (AZs) to use. One subnet of each type (public, private app, private persistence) will be created in each AZ. All AZs will be used if you provide a value that is more than the number of AZs in a region. A value of null means all AZs should be used. For example, if you specify 3 in a region with 5 AZs, subnets will be created in just 3 AZs instead of all 5. On the other hand, if you specify 6 in the same region, all 5 AZs will be used with no duplicates (same as setting this to 5)."
  type        = number
  default     = null
}

variable "availability_zone_exclude_names" {
  description = "List of excluded Availability Zone names."
  type        = list(string)
  default     = []
}

variable "availability_zone_exclude_ids" {
  description = "List of excluded Availability Zone IDs."
  type        = list(string)
  default     = []
}

variable "availability_zone_state" {
  description = "Allows to filter list of Availability Zones based on their current state. Can be either \"available\", \"information\", \"impaired\" or \"unavailable\". By default the list includes a complete set of Availability Zones to which the underlying AWS account has access, regardless of their state."
  type        = string
  default     = null
}

variable "availability_zone_ids" {
  description = "List of specific Availability Zone IDs to use. If null (default), all availability zones in the configured AWS region will be used."
  type        = list(string)
  default     = null
  validation {
    # We have to use a conditional here because binary operators are not short circuited in terraform. This is the
    # equivalent of (var.availability_zone_ids == null || length(var.availablity_zone_ids) > 0)
    condition = (
      var.availability_zone_ids == null
      ? true
      : length(var.availability_zone_ids) > 0
    )
    error_message = "The variable availability_zone_ids must be null or a list containing at least one Availability Zone."
  }
}

variable "allow_private_app_internet_access" {
  description = "Should the private app subnet be allowed outbound access to the internet?"
  type        = bool
  default     = true
}

variable "allow_private_persistence_internet_access" {
  description = "Should the private persistence subnet be allowed outbound access to the internet?"
  type        = bool
  default     = false
}

variable "allow_inspection_internet_access" {
  description = "Should the inspection subnet be allowed outbound access to the internet?"
  type        = bool
  default     = false
}

variable "allow_transit_internet_access" {
  description = "Should the transit subnet be allowed outbound access to the internet?"
  type        = bool
  default     = false
}

variable "use_custom_nat_eips" {
  description = "Set to true to use existing EIPs, passed in via var.custom_nat_eips, for the NAT gateway(s), instead of creating new ones."
  type        = bool
  default     = false
}

variable "custom_nat_eips" {
  description = "The list of EIPs (allocation ids) to use for the NAT gateways. Their number has to match the one given in 'num_nat_gateways'. Must be set if var.use_custom_nat_eips us true."
  type        = list(string)
  default     = []
}

variable "enable_dns_hostnames" {
  description = "(Optional) A boolean flag to enable/disable DNS hostnames in the VPC. Defaults true."
  type        = bool
  default     = true
  validation {
    condition     = var.enable_dns_hostnames == true || var.enable_dns_hostnames == false
    error_message = "The variable enable_dns_hostnames must be set to true or false."
  }
}

variable "enable_dns_support" {
  description = "(Optional) A boolean flag to enable/disable DNS support in the VPC. Defaults true."
  type        = bool
  default     = true
  validation {
    condition     = var.enable_dns_support == true || var.enable_dns_support == false
    error_message = "The variable enable_dns_hostnames must be set to true or false."
  }
}

variable "enable_private_nat" {
  description = "(Optional) A boolean flag to enable/disable a private NAT gateway. If this is set to true, it will disable public NAT gateways. Private NAT gateways are deployed into transit subnets and require setting 'var.create_transit_subnets = true'. Defaults false."
  type        = bool
  default     = false
}

variable "enable_network_address_usage_metrics" {
  description = "(Optional) A boolean flag to enable/disable network address usage metrics in the VPC. Defaults false."
  type        = bool
  default     = false
  validation {
    condition     = var.enable_network_address_usage_metrics == true || var.enable_network_address_usage_metrics == false
    error_message = "The variable enable_network_address_usage_metrics must be set to true or false."
  }
}

variable "ipv4_netmask_length" {
  description = "(Optional) The length of the IPv4 CIDR netmask. Requires utilizing an ipv4_ipam_pool_id. Defaults to null."
  type        = number
  default     = null
  validation {
    condition     = var.ipv4_netmask_length == null ? true : (var.ipv4_netmask_length >= 16 && var.ipv4_netmask_length <= 28)
    error_message = "The variable ipv4_netmask_length must be null or equal to or between 16 and 28."
  }
}

variable "nat_private_ip_host_num" {
  description = "The host number in the IP address of the NAT Gateway. You would only use this if you want the NAT Gateway to always have the same host number within your subnet's CIDR range: e.g., it's always x.x.x.4. For IPv4, this is the fourth octet in the IP address."
  type        = number
  default     = null
  validation {
    condition     = var.nat_private_ip_host_num == null ? true : (var.nat_private_ip_host_num >= 0 && var.nat_private_ip_host_num <= 255)
    error_message = "The variable nat_private_ip_host_num must be null or equal to or between 0 and 255."
  }
}

variable "nat_secondary_private_ip_address_count" {
  description = "(Optional) The number of secondary private IP addresses to assign to each NAT gateway. These IP addresses are used for source NAT (SNAT) for the instances in the private subnets. Defaults to 0."
  type        = number
  default     = 0
  validation {
    condition     = var.nat_secondary_private_ip_address_count >= 0
    error_message = "The variable nat_secondary_private_ip_address_count must be greater than or equal to 0."
  }
}

variable "create_nat_secondary_eip" {
  description = "Flag that controls attachment of secondary EIP to NAT gateway."
  type        = bool
  default     = false
}

variable "public_subnet_cidr_blocks" {
  description = "A map listing the specific CIDR blocks desired for each public subnet. The key must be in the form AZ-0, AZ-1, ... AZ-n where n is the number of Availability Zones. If left blank, we will compute a reasonable CIDR block for each subnet."
  type        = map(string)
  default     = {}
  # Example:
  # default = {
  #    AZ-0 = "10.226.20.0/24"
  #    AZ-1 = "10.226.21.0/24"
  #    AZ-2 = "10.226.22.0/24"
  # }
}

variable "public_subnet_ipv6_cidr_blocks" {
  description = "(Optional) A map listing the specific IPv6 CIDR blocks desired for each public subnet. The key must be in the form AZ-0, AZ-1, ... AZ-n where n is the number of Availability Zones. If left blank, we will compute a reasonable CIDR block for each subnet."
  type        = map(string)
  default     = {}
  # Example:
  # default = {
  #    AZ-0 = "fd00:10:226:20::/64"
  #    AZ-1 = "fd00:10:226:21::/64"
  #    AZ-2 = "fd00:10:226:22::/64"
  # }
}

variable "public_subnet_name" {
  description = "The name of the public subnet tier. This is used to tag the subnet and its resources."
  type        = string
  default     = "public"
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.public_subnet_name))
    error_message = "The variable public_subnet_name must be a string containing only alphanumeric characters and hyphens."
  }
}

variable "private_app_subnet_cidr_blocks" {
  description = "A map listing the specific CIDR blocks desired for each private-app subnet. The key must be in the form AZ-0, AZ-1, ... AZ-n where n is the number of Availability Zones. If left blank, we will compute a reasonable CIDR block for each subnet."
  type        = map(string)
  default     = {}
  # Example:
  # default = {
  #    AZ-0 = "10.226.30.0/24"
  #    AZ-1 = "10.226.31.0/24"
  #    AZ-2 = "10.226.32.0/24"
  # }
}

variable "private_subnet_name" {
  description = "The name of the private subnet tier. This is used to tag the subnet and its resources."
  type        = string
  default     = "private-app"
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.private_subnet_name))
    error_message = "The variable private_subnet_name must be a string containing only alphanumeric characters and hyphens."
  }
}

variable "private_persistence_subnet_cidr_blocks" {
  description = "A map listing the specific CIDR blocks desired for each private-persistence subnet. The key must be in the form AZ-0, AZ-1, ... AZ-n where n is the number of Availability Zones. If left blank, we will compute a reasonable CIDR block for each subnet."
  type        = map(string)
  default     = {}
  # Example:
  # default = {
  #    AZ-0 = "10.226.40.0/24"
  #    AZ-1 = "10.226.41.0/24"
  #    AZ-2 = "10.226.42.0/24"
  # }
}

variable "inspection_subnet_cidr_blocks" {
  description = "A map listing the specific CIDR blocks desired for each private-persistence subnet. The key must be in the form AZ-0, AZ-1, ... AZ-n where n is the number of Availability Zones. If left blank, we will compute a reasonable CIDR block for each subnet."
  type        = map(string)
  default     = {}
  # Example:
  # default = {
  #    AZ-0 = "10.226.40.0/24"
  #    AZ-1 = "10.226.41.0/24"
  #    AZ-2 = "10.226.42.0/24"
  # }
}

variable "private_persistence_subnet_name" {
  description = "The name of the private persistence subnet tier. This is used to tag the subnet and its resources."
  type        = string
  default     = "private-persistence"
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.private_persistence_subnet_name))
    error_message = "The variable private_persistence_subnet_name must be a string containing only alphanumeric characters and hyphens."
  }
}

variable "inspection_subnet_name" {
  description = "The name of the inspection subnet tier. This is used to tag the subnet and its resources."
  type        = string
  default     = "inspection"
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.inspection_subnet_name))
    error_message = "The variable inspection_subnet_name must be a string containing only alphanumeric characters and hyphens."
  }
}

variable "transit_subnet_cidr_blocks" {
  description = "A map listing the specific CIDR blocks desired for each transit subnet. The key must be in the form AZ-0, AZ-1, ... AZ-n where n is the number of Availability Zones. If left blank, we will compute a reasonable CIDR block for each subnet."
  type        = map(string)
  default     = {}
  # Example:
  # default = {
  #    AZ-0 = "10.226.50.0/24"
  #    AZ-1 = "10.226.51.0/24"
  #    AZ-2 = "10.226.52.0/24"
  # }
}

variable "transit_subnet_name" {
  description = "The name of the transit subnet tier. This is used to tag the subnet and its resources."
  type        = string
  default     = "transit"
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.transit_subnet_name))
    error_message = "The variable transit_subnet_name must be a string containing only alphanumeric characters and hyphens."
  }
}

variable "public_propagating_vgws" {
  description = "A list of Virtual Private Gateways that will propagate routes to public subnets. All routes from VPN connections that use Virtual Private Gateways listed here will appear in route tables of public subnets. If left empty, no routes will be propagated."
  type        = list(string)
  default     = []
  # Example:
  #  default = ["vgw-07bf8d1a"]
}

variable "private_propagating_vgws" {
  description = "A list of Virtual Private Gateways that will propagate routes to private subnets. All routes from VPN connections that use Virtual Private Gateways listed here will appear in route tables of private subnets. If left empty, no routes will be propagated."
  type        = list(string)
  default     = []
  # Example:
  #  default = ["vgw-07bf8d1a"]
}

variable "persistence_propagating_vgws" {
  description = "A list of Virtual Private Gateways that will propagate routes to persistence subnets. All routes from VPN connections that use Virtual Private Gateways listed here will appear in route tables of persistence subnets. If left empty, no routes will be propagated."
  type        = list(string)
  default     = []
}

variable "inspection_propagating_vgws" {
  description = "A list of Virtual Private Gateways that will propagate routes to inspection subnets. All routes from VPN connections that use Virtual Private Gateways listed here will appear in route tables of persistence subnets. If left empty, no routes will be propagated."
  type        = list(string)
  default     = []
}

variable "transit_propagating_vgws" {
  description = "A list of Virtual Private Gateways that will propagate routes to transit subnets. All routes from VPN connections that use Virtual Private Gateways listed here will appear in route tables of transit subnets. If left empty, no routes will be propagated."
  type        = list(string)
  default     = []
}

variable "tenancy" {
  description = "The allowed tenancy of instances launched into the selected VPC. Must be one of: default, dedicated, or host."
  type        = string
  default     = "default"
}

##########
# IPv6
##########

variable "ipv6_cidr_block" {
  description = "(Optional) IPv6 CIDR block to request from an IPAM Pool. Can be set explicitly or derived from IPAM using ipv6_netmask_length. If not provided, no IPv6 CIDR block will be allocated."
  type        = string
  default     = null
}

variable "ipv6_ipam_pool_id" {
  description = "(Optional) IPAM Pool ID for a IPv6 pool. Conflicts with assign_generated_ipv6_cidr_block."
  type        = string
  default     = null
}

variable "ipv6_ipam_pool_filters" {
  description = "Filters to select the IPv6 IPAM pool to use for allocated this VPCs"
  type = list(object({
    name   = string
    values = list(string)
  }))
  default = null
}

variable "ipv6_netmask_length" {
  description = "(Optional) Netmask length to request from IPAM Pool. Conflicts with ipv6_cidr_block. This can be omitted if IPAM pool as a allocation_default_netmask_length set. Valid values: 56."
  type        = number
  default     = null
  validation {
    condition     = var.ipv6_netmask_length == null ? true : (var.ipv6_netmask_length == 56)
    error_message = "The variable ipv6_netmask_length can either be set to null or 56."
  }
}

variable "ipv6_cidr_block_network_border_group" {
  description = "(Optional) By default when an IPv6 CIDR is assigned to a VPC a default ipv6_cidr_block_network_border_group will be set to the region of the VPC. This can be changed to restrict advertisement of public addresses to specific Network Border Groups such as LocalZones."
  type        = string
  default     = null
}

variable "assign_generated_ipv6_cidr_block" {
  description = "(Optional) Requests an Amazon-provided IPv6 CIDR block with a /56 prefix length for the VPC. You cannot specify the range of IP addresses, or the size of the CIDR block. Conflicts with ipv6_ipam_pool_id"
  type        = bool
  default     = null
  validation {
    condition     = var.assign_generated_ipv6_cidr_block == null ? true : can(regex("true|false", var.assign_generated_ipv6_cidr_block))
    error_message = "The variable assign_generated_ipv6_cidr_block can either be set to null, true, or false."
  }
}

variable "enable_ipv6" {
  description = "(Optional) Enables IPv6 resources for the VPC. Defaults to false."
  type        = bool
  default     = false
  validation {
    condition     = can(regex("true|false", var.enable_ipv6))
    error_message = "The variable enable_ipv6 can either be set to true or false."
  }
}

variable "assign_ipv6_address_on_creation" {
  description = "(Optional) Specify true to indicate that network interfaces created in the specified subnet should be assigned an IPv6 address. Default is false"
  type        = bool
  default     = false
  validation {
    condition     = can(regex("true|false", var.assign_ipv6_address_on_creation))
    error_message = "The variable assign_ipv6_address_on_creation can either be set to true or false."
  }
}

variable "ipv6_subnet_bits" {
  description = "(Optional) The number of additional bits to use in the VPC IPv6 CIDR block. The end result must be between a /56 netmask and /64 netmask. These bits are added to the VPC CIDR block bits. Example: /56 + 8 bits = /64 Defaults to 8 bits for a /64."
  type        = number
  default     = 8
  validation {
    condition     = var.ipv6_subnet_bits == null ? true : (var.ipv6_subnet_bits >= 0 && var.ipv6_subnet_bits <= 8)
    error_message = "The variable ipv6_subnet_bits can either be set to null or a value between 0 and 8."
  }
}

########

variable "custom_tags" {
  description = "A map of tags to apply to the VPC, Subnets, Route Tables, Internet Gateway, default security group, and default NACLs. The key is the tag name and the value is the tag value. Note that the tag 'Name' is automatically added by this module but may be optionally overwritten by this variable."
  type        = map(string)
  default     = {}
}

variable "vpc_custom_tags" {
  description = "A map of tags to apply just to the VPC itself, but not any of the other resources. The key is the tag name and the value is the tag value. Note that tags defined here will override tags defined as custom_tags in case of conflict."
  type        = map(string)
  default     = {}
}

variable "public_subnet_custom_tags" {
  description = "A map of tags to apply to the public Subnet, on top of the custom_tags. The key is the tag name and the value is the tag value. Note that tags defined here will override tags defined as custom_tags in case of conflict."
  type        = map(string)
  default     = {}
}

variable "private_app_subnet_custom_tags" {
  description = "A map of tags to apply to the private-app Subnet, on top of the custom_tags. The key is the tag name and the value is the tag value. Note that tags defined here will override tags defined as custom_tags in case of conflict."
  type        = map(string)
  default     = {}
}

variable "private_persistence_subnet_custom_tags" {
  description = "A map of tags to apply to the private-persistence Subnet, on top of the custom_tags. The key is the tag name and the value is the tag value. Note that tags defined here will override tags defined as custom_tags in case of conflict."
  type        = map(string)
  default     = {}
}

variable "inspection_subnet_custom_tags" {
  description = "A map of tags to apply to the inspection subnets, on top of the custom_tags. The key is the tag name and the value is the tag value. Note that tags defined here will override tags defined as custom_tags in case of conflict."
  type        = map(string)
  default     = {}
}

variable "transit_subnet_custom_tags" {
  description = "A map of tags to apply to the transit Subnet, on top of the custom_tags. The key is the tag name and the value is the tag value. Note that tags defined here will override tags defined as custom_tags in case of conflict."
  type        = map(string)
  default     = {}
}

variable "nat_gateway_custom_tags" {
  description = "A map of tags to apply to the NAT gateways, on top of the custom_tags. The key is the tag name and the value is the tag value. Note that tags defined here will override tags defined as custom_tags in case of conflict."
  type        = map(string)
  default     = {}
}

variable "security_group_tags" {
  description = "A map of tags to apply to the default Security Group, on top of the custom_tags. The key is the tag name and the value is the tag value. Note that tags defined here will override tags defined as custom_tags in case of conflict."
  type        = map(string)
  default     = {}
}

variable "global_subnet_spacing" {
  description = "The amount of spacing between the different subnet types when all subnets are present, such as the transit subnets."
  type        = number
  default     = 6
}

variable "subnet_spacing" {
  description = "The amount of spacing between the different subnet types"
  type        = number
  default     = 10
}

variable "private_subnet_spacing" {
  description = "The amount of spacing between private app subnets."
  type        = number
  default     = null
}

variable "persistence_subnet_spacing" {
  description = "The amount of spacing between the private persistence subnets."
  type        = number
  default     = null
}

variable "inspection_subnet_spacing" {
  description = "The amount of spacing between the inspection subnets."
  type        = number
  default     = null
}

variable "transit_subnet_spacing" {
  description = "The amount of spacing between the transit subnets."
  type        = number
  default     = null
}

variable "public_subnet_bits" {
  description = "Takes the CIDR prefix and adds these many bits to it for calculating subnet ranges.  MAKE SURE if you change this you also change the CIDR spacing or you may hit errors.  See cidrsubnet interpolation in terraform config for more information."
  type        = number
  default     = 5
}

variable "private_subnet_bits" {
  description = "Takes the CIDR prefix and adds these many bits to it for calculating subnet ranges.  MAKE SURE if you change this you also change the CIDR spacing or you may hit errors.  See cidrsubnet interpolation in terraform config for more information."
  type        = number
  default     = 5
}

variable "persistence_subnet_bits" {
  description = "Takes the CIDR prefix and adds these many bits to it for calculating subnet ranges.  MAKE SURE if you change this you also change the CIDR spacing or you may hit errors.  See cidrsubnet interpolation in terraform config for more information."
  type        = number
  default     = 5
}

variable "inspection_subnet_bits" {
  description = "Takes the CIDR prefix and adds these many bits to it for calculating subnet ranges. MAKE SURE if you change this you also change the CIDR spacing or you may hit errors. See cidrsubnet interpolation in terraform config for more information."
  type        = number
  default     = 5
}

variable "transit_subnet_bits" {
  description = "Takes the CIDR prefix and adds these many bits to it for calculating subnet ranges.  MAKE SURE if you change this you also change the CIDR spacing or you may hit errors.  See cidrsubnet interpolation in terraform config for more information."
  type        = number
  default     = 5
}

variable "map_public_ip_on_launch" {
  description = "Specify true to indicate that instances launched into the public subnet should be assigned a public IP address (versus a private IP address)"
  type        = bool
  default     = false
}

variable "create_default_route_table_route" {
  description = "If set to true, this module will create a default route table route to the Internet Gateway. If set to false, this module will NOT create a default route table route to the Internet Gateway. This is useful if you have subnets which utilize the default route table. Defaults to true."
  type        = bool
  default     = true
}

variable "create_vpc_endpoints" {
  description = "Create VPC endpoints for S3 and DynamoDB."
  type        = bool
  default     = true
}

variable "s3_endpoint_policy" {
  description = "IAM policy to restrict what resources can call this endpoint. For example, you can add an IAM policy that allows EC2 instances to talk to this endpoint but no other types of resources. If not specified, all resources will be allowed to call this endpoint."
  type        = string
  default     = null
}

variable "dynamodb_endpoint_policy" {
  description = "IAM policy to restrict what resources can call this endpoint. For example, you can add an IAM policy that allows EC2 instances to talk to this endpoint but no other types of resources. If not specified, all resources will be allowed to call this endpoint."
  type        = string
  default     = null
}

variable "create_public_subnets" {
  description = "If set to false, this module will NOT create the public subnet tier. This is useful for VPCs that only need private subnets. Note that setting this to false also means the module will NOT create an Internet Gateway or the NAT gateways, so if you want any public Internet access in the VPC (even outbound access—e.g., to run apt get), you'll need to provide it yourself via some other mechanism (e.g., via VPC peering, a Transit Gateway, Direct Connect, etc). Defaults to true."
  type        = bool
  default     = true
}

variable "create_igw" {
  description = "If the VPC will create an Internet Gateway. There are use cases when the VPC is desired to not be routable from the internet, and hence, they should not have an Internet Gateway. For example, when it is desired that public subnets exist but they are not directly public facing, since they can be routed from other VPC hosting the IGW."
  type        = bool
  default     = true
}

variable "create_private_app_subnets" {
  description = "If set to false, this module will NOT create the private app subnet tier."
  type        = bool
  default     = true
}

variable "create_private_persistence_subnets" {
  description = "If set to false, this module will NOT create the private persistence subnet tier."
  type        = bool
  default     = true
}

variable "create_inspection_subnets" {
  description = "If set to false, this module will NOT create the inspection subnets."
  type        = bool
  default     = false
}

variable "create_transit_subnets" {
  description = "If set to false, this module will NOT create the transit subnet tier."
  type        = bool
  default     = false
}

variable "enable_default_security_group" {
  description = "If set to false, the default security groups will NOT be created. This variable is a workaround to a terraform limitation where overriding var.default_security_group_ingress_rules = {} and var.default_security_group_egress_rules = {} does not remove the rules. More information at: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_security_group#removing-aws_default_security_group-from-your-configuration"
  type        = bool
  default     = true
}

variable "default_security_group_ingress_rules" {
  description = "The ingress rules to apply to the default security group in the VPC. This is the security group that is used by any resource that doesn't have its own security group attached. The value for this variable must be a map where the keys are a unique name for each rule and the values are objects with the same fields as the ingress block in the aws_default_security_group resource: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_security_group#ingress-block."
  # Ideally, we'd have a more specific type here, but neither the 'map' nor 'object' type has support for optional
  # fields, and we need optional fields when defining security group rules.
  type = any
  default = {
    # The default AWS configures:
    # https://docs.aws.amazon.com/vpc/latest/userguide/VPC_SecurityGroups.html#DefaultSecurityGroup
    AllowAllFromSelf = {
      from_port = 0
      to_port   = 0
      protocol  = "-1"
      self      = true
    }
  }
}

variable "default_security_group_egress_rules" {
  description = "The egress rules to apply to the default security group in the VPC. This is the security group that is used by any resource that doesn't have its own security group attached. The value for this variable must be a map where the keys are a unique name for each rule and the values are objects with the same fields as the egress block in the aws_default_security_group resource: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_security_group#egress-block."
  # Ideally, we'd have a more specific type here, but neither the 'map' nor 'object' type has support for optional
  # fields, and we need optional fields when defining security group rules.
  type = any
  default = {
    # The default AWS configures:
    # https://docs.aws.amazon.com/vpc/latest/userguide/VPC_SecurityGroups.html#DefaultSecurityGroup
    AllowAllOutbound = {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }
}

variable "apply_default_nacl_rules" {
  description = "If true, will apply the default NACL rules in var.default_nacl_ingress_rules and var.default_nacl_egress_rules on the default NACL of the VPC. Note that every VPC must have a default NACL - when this is false, the original default NACL rules managed by AWS will be used."
  type        = bool
  default     = false
}

variable "associate_default_nacl_to_subnets" {
  description = "If true, will associate the default NACL to the public, private, and persistence subnets created by this module. Only used if var.apply_default_nacl_rules is true. Note that this does not guarantee that the subnets are associated with the default NACL. Subnets can only be associated with a single NACL. The default NACL association will be dropped if the subnets are associated with a custom NACL later."
  type        = bool
  default     = true
}

variable "default_nacl_ingress_rules" {
  description = "The ingress rules to apply to the default NACL in the VPC. This is the NACL that is used by any subnet that doesn't have its own NACL attached. The value for this variable must be a map where the keys are a unique name for each rule and the values are objects with the same fields as the ingress block in the aws_default_network_acl resource: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_network_acl."
  # Ideally, we'd have a more specific type here, but neither the 'map' nor 'object' type has support for optional
  # fields, and we need optional fields when defining security group rules.
  type = any
  default = {
    # The default AWS configures:
    # https://docs.aws.amazon.com/vpc/latest/userguide/vpc-network-acls.html#default-network-acl
    AllowAllIPv4 = {
      from_port  = 0
      to_port    = 0
      action     = "allow"
      protocol   = "-1"
      cidr_block = "0.0.0.0/0"
      rule_no    = 100
    }
    AllowAllIPv6 = {
      from_port       = 0
      to_port         = 0
      action          = "allow"
      protocol        = "-1"
      ipv6_cidr_block = "::/0"
      rule_no         = 101
    }
  }
}

variable "default_nacl_egress_rules" {
  description = "The egress rules to apply to the default NACL in the VPC. This is the security group that is used by any subnet that doesn't have its own NACL attached. The value for this variable must be a map where the keys are a unique name for each rule and the values are objects with the same fields as the egress block in the aws_default_network_acl resource: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_network_acl."
  # Ideally, we'd have a more specific type here, but neither the 'map' nor 'object' type has support for optional
  # fields, and we need optional fields when defining security group rules.
  type = any
  default = {
    # The default AWS configures:
    # https://docs.aws.amazon.com/vpc/latest/userguide/vpc-network-acls.html#default-network-acl
    AllowAllIPv4 = {
      from_port  = 0
      to_port    = 0
      action     = "allow"
      protocol   = "-1"
      cidr_block = "0.0.0.0/0"
      rule_no    = 100
    }
    AllowAllIPv6 = {
      from_port       = 0
      to_port         = 0
      action          = "allow"
      protocol        = "-1"
      ipv6_cidr_block = "::/0"
      rule_no         = 101
    }
  }
}

variable "one_route_table_public_subnets" {
  description = "If set to true, create one route table shared amongst all the public subnets; if set to false, create a separate route table per public subnet. Historically, we created one route table for all the public subnets, as they all routed through the Internet Gateway anyway, but in certain use cases (e.g., for use with Network Firewall), you may want to have separate route tables for each public subnet."
  type        = bool
  default     = true
}

variable "route_table_creation_timeout" {
  description = "The timeout for the creation of the Route Tables. It defines how long to wait for a route table to be created before considering the operation failed. Ref: https://www.terraform.io/language/resources/syntax#operation-timeouts"
  type        = string
  default     = "5m"
}

variable "route_table_update_timeout" {
  description = "The timeout for the update of the Route Tables. It defines how long to wait for a route table to be updated before considering the operation failed. Ref: https://www.terraform.io/language/resources/syntax#operation-timeouts"
  type        = string
  default     = "2m"
}

variable "route_table_deletion_timeout" {
  description = "The timeout for the deletion of the Route Tables. It defines how long to wait for a route table to be deleted before considering the operation failed. Ref: https://www.terraform.io/language/resources/syntax#operation-timeouts"
  type        = string
  default     = "5m"
}

variable "public_route_table_custom_tags" {
  description = "A map of tags to apply to the public route table(s), on top of the custom_tags. The key is the tag name and the value is the tag value. Note that tags defined here will override tags defined as custom_tags in case of conflict."
  type        = map(string)
  default     = {}
}

variable "private_app_route_table_custom_tags" {
  description = "A map of tags to apply to the private-app route table(s), on top of the custom_tags. The key is the tag name and the value is the tag value. Note that tags defined here will override tags defined as custom_tags in case of conflict."
  type        = map(string)
  default     = {}
}

variable "private_persistence_route_table_custom_tags" {
  description = "A map of tags to apply to the private-persistence route tables(s), on top of the custom_tags. The key is the tag name and the value is the tag value. Note that tags defined here will override tags defined as custom_tags in case of conflict."
  type        = map(string)
  default     = {}
}

variable "inspection_route_table_custom_tags" {
  description = "A map of tags to apply to the inspection route tables(s), on top of the custom_tags. The key is the tag name and the value is the tag value. Note that tags defined here will override tags defined as custom_tags in case of conflict."
  type        = map(string)
  default     = {}
}

variable "transit_route_table_custom_tags" {
  description = "A map of tags to apply to the transit route table(s), on top of the custom_tags. The key is the tag name and the value is the tag value. Note that tags defined here will override tags defined as custom_tags in case of conflict."
  type        = map(string)
  default     = {}
}

variable "ipv4_ipam_pool_id" {
  description = "The ID of an IPv4 IPAM pool you want to use for allocating this VPC's CIDR."
  type        = string
  default     = null
}

variable "ipv4_ipam_pool_filters" {
  description = "Filters to select the IPv4 IPAM pool to use for allocated this VPCs"
  type = list(object({
    name   = string
    values = list(string)
  }))
  default = null
}

variable "secondary_cidr_blocks" {
  description = "A list of secondary CIDR blocks to associate with the VPC."
  type        = set(string)
  default     = []
  # Example:
  # default = [
  #   "10.250.0.0/16",
  #   "10.251.0.0/16",
  #   "10.252.0.0/16"
  # ]
}

variable "dhcp_options_id" {
  description = "The DHCP Options Set ID to associate with the VPC. After specifying this attribute, removing it will delete the DHCP option assignment, leaving the VPC without any DHCP option set, rather than reverting to the one set by default."
  type        = string
  default     = null
}

# ----------------------------------------------------------------------------------------------------------------------
# DEPRECATED PARAMETERS
# ----------------------------------------------------------------------------------------------------------------------

variable "aws_region" {
  description = "DEPRECATED. The AWS Region where this VPC will exist. This variable is no longer used and only kept around for backwards compatibility. We now automatically fetch the region using a data source."
  type        = string
  default     = ""
}

# ----------------------------------------------------------------------------------------------------------------------
# EC2 INSTANCE PARAMETERS
# ----------------------------------------------------------------------------------------------------------------------

variable "ami_id" {
  description = "The AMI ID to use for EC2 instances (Ansible Controller, Jenkins Master, Jenkins Agent)"
  type        = string
}

variable "instance_type" {
  description = "The instance type for EC2 instances"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "The name of the EC2 Key Pair to use for SSH access"
  type        = string
}

variable "jenkins_agent_count" {
  description = "Number of Jenkins Agent instances to create"
  type        = number
  default     = 2
}
