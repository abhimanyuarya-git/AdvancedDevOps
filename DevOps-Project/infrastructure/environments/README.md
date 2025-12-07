# VPC Module - Environment Configurations

This directory contains environment-specific tfvars files for the VPC module.

## Available Configurations

### 1. Development (`dev.tfvars`)
**Cost-optimized setup for development environments**

- Single NAT Gateway (cost savings)
- 2 Availability Zones
- Public and Private-App subnets only
- No persistence tier (use RDS in public subnet or external DB)

**Usage:**
```bash
terraform plan -var-file="environments/dev.tfvars"
terraform apply -var-file="environments/dev.tfvars"
```

**Estimated Monthly Cost:** ~$35-45 (1 NAT Gateway)

---

### 2. Staging (`staging.tfvars`)
**Balanced setup for staging/QA environments**

- 2 NAT Gateways (moderate availability)
- 2 Availability Zones
- Public, Private-App, and Private-Persistence subnets
- VPC Endpoints enabled

**Usage:**
```bash
terraform plan -var-file="environments/staging.tfvars"
terraform apply -var-file="environments/staging.tfvars"
```

**Estimated Monthly Cost:** ~$70-90 (2 NAT Gateways)

---

### 3. Production (`prod.tfvars`)
**High availability setup for production workloads**

- 3 NAT Gateways (one per AZ for HA)
- 3 Availability Zones
- All subnet tiers (Public, Private-App, Private-Persistence)
- Separate route table per public subnet
- Network address usage metrics enabled
- Enhanced tagging for compliance

**Usage:**
```bash
terraform plan -var-file="environments/prod.tfvars"
terraform apply -var-file="environments/prod.tfvars"
```

**Estimated Monthly Cost:** ~$105-135 (3 NAT Gateways)

---

### 4. Production with Inspection (`prod-with-inspection.tfvars`)
**Enterprise-grade setup with network security**

- 3 NAT Gateways
- 3 Availability Zones
- All 5 subnet tiers (Public, Private-App, Private-Persistence, Inspection, Transit)
- Designed for AWS Network Firewall integration
- Transit Gateway ready
- Enhanced security and compliance tags

**Usage:**
```bash
terraform plan -var-file="environments/prod-with-inspection.tfvars"
terraform apply -var-file="environments/prod-with-inspection.tfvars"
```

**Estimated Monthly Cost:** ~$105-135 (3 NAT Gateways) + Network Firewall costs

---

## Quick Start

### Step 1: Choose Your Environment
Select the appropriate tfvars file based on your needs.

### Step 2: Customize (Optional)
Copy the tfvars file and modify values:
```bash
cp environments/prod.tfvars terraform.tfvars
# Edit terraform.tfvars with your values
```

### Step 3: Initialize Terraform
```bash
terraform init
```

### Step 4: Plan and Apply
```bash
# Using var-file
terraform plan -var-file="environments/prod.tfvars"
terraform apply -var-file="environments/prod.tfvars"

# Or using terraform.tfvars (auto-loaded)
terraform plan
terraform apply
```

## CIDR Block Recommendations

| Environment | CIDR Block | Usable IPs | Use Case |
|-------------|------------|------------|----------|
| Dev | 10.1.0.0/16 | 65,536 | Small dev workloads |
| Staging | 10.2.0.0/16 | 65,536 | Pre-production testing |
| Production | 10.0.0.0/16 | 65,536 | Production workloads |
| DR/Backup | 10.3.0.0/16 | 65,536 | Disaster recovery |

## Subnet Sizing Guide

Default configuration uses /24 subnets (251 usable IPs per subnet):

```
10.0.0.0/16 VPC
├── 10.0.0.0/24   - Public Subnet AZ-1
├── 10.0.1.0/24   - Public Subnet AZ-2
├── 10.0.2.0/24   - Public Subnet AZ-3
├── 10.0.10.0/24  - Private-App Subnet AZ-1
├── 10.0.11.0/24  - Private-App Subnet AZ-2
├── 10.0.12.0/24  - Private-App Subnet AZ-3
├── 10.0.20.0/24  - Private-Persistence Subnet AZ-1
├── 10.0.21.0/24  - Private-Persistence Subnet AZ-2
└── 10.0.22.0/24  - Private-Persistence Subnet AZ-3
```

## Custom CIDR Blocks

To specify custom CIDR blocks, add to your tfvars:

```hcl
public_subnet_cidr_blocks = {
  "AZ-0" = "10.0.0.0/24"
  "AZ-1" = "10.0.1.0/24"
  "AZ-2" = "10.0.2.0/24"
}

private_app_subnet_cidr_blocks = {
  "AZ-0" = "10.0.10.0/24"
  "AZ-1" = "10.0.11.0/24"
  "AZ-2" = "10.0.12.0/24"
}
```

## Tagging Strategy

All configurations include standard tags:
- `Environment`: dev/staging/production
- `ManagedBy`: terraform
- `Project`: devops-project

Production adds compliance tags:
- `Compliance`: required/pci-dss
- `Backup`: daily
- `Criticality`: high/critical

## Cost Optimization Tips

1. **Development**: Use 1 NAT Gateway
2. **Staging**: Use 2 NAT Gateways
3. **Production**: Use 3 NAT Gateways (one per AZ)
4. **Off-hours**: Consider stopping NAT Gateways in dev/staging during off-hours
5. **VPC Endpoints**: Enable to reduce NAT Gateway data transfer costs

## Security Best Practices

1. **Network Segmentation**: Use all subnet tiers in production
2. **Least Privilege**: Disable internet access for persistence tier
3. **Inspection**: Use inspection subnets for Network Firewall
4. **Monitoring**: Enable network address usage metrics in production
5. **Compliance**: Use appropriate tags for audit trails

## Troubleshooting

### Issue: "Error creating NAT Gateway"
**Solution**: Ensure you have available Elastic IPs in your account

### Issue: "Insufficient subnet space"
**Solution**: Adjust `subnet_bits` or use custom CIDR blocks

### Issue: "Route table conflicts"
**Solution**: Set `one_route_table_public_subnets = true` for simpler routing

## Next Steps

After VPC creation:
1. Configure VPC Flow Logs
2. Set up Network ACLs
3. Deploy AWS Network Firewall (if using inspection subnets)
4. Configure Transit Gateway (if using transit subnets)
5. Deploy application resources
