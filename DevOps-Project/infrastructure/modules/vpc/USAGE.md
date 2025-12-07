# VPC Module - Usage Guide

Complete guide for using the VPC module with tfvars files.

## Table of Contents
1. [Quick Start](#quick-start)
2. [Using tfvars Files](#using-tfvars-files)
3. [Environment-Specific Deployments](#environment-specific-deployments)
4. [Custom Configuration](#custom-configuration)
5. [Common Scenarios](#common-scenarios)

---

## Quick Start

### 1. Choose Your Configuration

```bash
cd /Users/abhi/codeclub/AdvancedDevOps/DevOps-Project/infrastructure/modules/vpc
```

Available configurations:
- `environments/dev.tfvars` - Development (1 NAT Gateway)
- `environments/staging.tfvars` - Staging (2 NAT Gateways)
- `environments/prod.tfvars` - Production (3 NAT Gateways)
- `environments/prod-with-inspection.tfvars` - Production with Network Firewall

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Deploy Using tfvars

```bash
# Plan
terraform plan -var-file="environments/prod.tfvars"

# Apply
terraform apply -var-file="environments/prod.tfvars"

# Destroy
terraform destroy -var-file="environments/prod.tfvars"
```

---

## Using tfvars Files

### Method 1: Using -var-file Flag (Recommended)

```bash
terraform plan -var-file="environments/prod.tfvars"
terraform apply -var-file="environments/prod.tfvars"
```

**Advantages:**
- Explicit environment selection
- Can use multiple var files
- Clear in CI/CD pipelines

### Method 2: Using terraform.tfvars (Auto-loaded)

```bash
# Copy environment file to terraform.tfvars
cp environments/prod.tfvars terraform.tfvars

# Terraform automatically loads terraform.tfvars
terraform plan
terraform apply
```

**Advantages:**
- No need to specify -var-file
- Simpler commands

### Method 3: Using Environment Variables

```bash
export TF_VAR_vpc_name="my-vpc"
export TF_VAR_cidr_block="10.0.0.0/16"
export TF_VAR_num_nat_gateways=3

terraform plan
terraform apply
```

### Method 4: Multiple var-files

```bash
# Combine base config with environment-specific overrides
terraform apply \
  -var-file="base.tfvars" \
  -var-file="environments/prod.tfvars"
```

---

## Environment-Specific Deployments

### Development Environment

```bash
# Deploy development VPC
terraform workspace new dev
terraform plan -var-file="environments/dev.tfvars"
terraform apply -var-file="environments/dev.tfvars"
```

**Configuration:**
- VPC: 10.1.0.0/16
- NAT Gateways: 1
- AZs: 2
- Cost: ~$35-45/month

### Staging Environment

```bash
# Deploy staging VPC
terraform workspace new staging
terraform plan -var-file="environments/staging.tfvars"
terraform apply -var-file="environments/staging.tfvars"
```

**Configuration:**
- VPC: 10.2.0.0/16
- NAT Gateways: 2
- AZs: 2
- Cost: ~$70-90/month

### Production Environment

```bash
# Deploy production VPC
terraform workspace new prod
terraform plan -var-file="environments/prod.tfvars"
terraform apply -var-file="environments/prod.tfvars"
```

**Configuration:**
- VPC: 10.0.0.0/16
- NAT Gateways: 3
- AZs: 3
- Cost: ~$105-135/month

---

## Custom Configuration

### Creating Your Own tfvars

1. **Copy the example:**
```bash
cp terraform.tfvars.example my-custom.tfvars
```

2. **Edit the file:**
```hcl
# my-custom.tfvars
vpc_name         = "my-custom-vpc"
cidr_block       = "10.5.0.0/16"
num_nat_gateways = 2

custom_tags = {
  Environment = "custom"
  Team        = "platform"
}
```

3. **Deploy:**
```bash
terraform apply -var-file="my-custom.tfvars"
```

### Overriding Specific Variables

```bash
# Use tfvars file but override specific values
terraform apply \
  -var-file="environments/prod.tfvars" \
  -var="vpc_name=prod-vpc-v2" \
  -var="num_nat_gateways=2"
```

---

## Common Scenarios

### Scenario 1: Cost-Optimized Development VPC

**File:** `environments/dev.tfvars`

```bash
terraform apply -var-file="environments/dev.tfvars"
```

**Features:**
- Single NAT Gateway (saves ~$70/month vs 3 NAT Gateways)
- 2 AZs only
- No persistence tier
- Perfect for development/testing

### Scenario 2: High-Availability Production VPC

**File:** `environments/prod.tfvars`

```bash
terraform apply -var-file="environments/prod.tfvars"
```

**Features:**
- 3 NAT Gateways (one per AZ)
- 3 AZs for high availability
- All subnet tiers
- Enhanced monitoring and tagging

### Scenario 3: Secure Production with Network Firewall

**File:** `environments/prod-with-inspection.tfvars`

```bash
terraform apply -var-file="environments/prod-with-inspection.tfvars"
```

**Features:**
- Inspection subnets for AWS Network Firewall
- Transit subnets for Transit Gateway
- Enhanced security posture
- Compliance-ready

### Scenario 4: Multi-Region Deployment

```bash
# US East 1
export AWS_REGION=us-east-1
terraform workspace new prod-us-east-1
terraform apply -var-file="environments/prod.tfvars"

# US West 2
export AWS_REGION=us-west-2
terraform workspace new prod-us-west-2
terraform apply -var-file="environments/prod.tfvars" \
  -var="cidr_block=10.20.0.0/16"
```

### Scenario 5: Custom Subnet CIDR Blocks

Create `custom-cidrs.tfvars`:

```hcl
vpc_name         = "custom-vpc"
cidr_block       = "10.100.0.0/16"
num_nat_gateways = 3

public_subnet_cidr_blocks = {
  "AZ-0" = "10.100.1.0/24"
  "AZ-1" = "10.100.2.0/24"
  "AZ-2" = "10.100.3.0/24"
}

private_app_subnet_cidr_blocks = {
  "AZ-0" = "10.100.11.0/24"
  "AZ-1" = "10.100.12.0/24"
  "AZ-2" = "10.100.13.0/24"
}

private_persistence_subnet_cidr_blocks = {
  "AZ-0" = "10.100.21.0/24"
  "AZ-1" = "10.100.22.0/24"
  "AZ-2" = "10.100.23.0/24"
}
```

Deploy:
```bash
terraform apply -var-file="custom-cidrs.tfvars"
```

---

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Deploy VPC

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
      
      - name: Terraform Init
        run: terraform init
        working-directory: ./infrastructure/modules/vpc
      
      - name: Terraform Plan
        run: terraform plan -var-file="environments/${{ github.event.inputs.environment }}.tfvars"
        working-directory: ./infrastructure/modules/vpc
      
      - name: Terraform Apply
        run: terraform apply -auto-approve -var-file="environments/${{ github.event.inputs.environment }}.tfvars"
        working-directory: ./infrastructure/modules/vpc
```

### GitLab CI Example

```yaml
stages:
  - plan
  - apply

variables:
  TF_ROOT: infrastructure/modules/vpc

plan:
  stage: plan
  script:
    - cd $TF_ROOT
    - terraform init
    - terraform plan -var-file="environments/${CI_ENVIRONMENT_NAME}.tfvars"

apply:
  stage: apply
  script:
    - cd $TF_ROOT
    - terraform init
    - terraform apply -auto-approve -var-file="environments/${CI_ENVIRONMENT_NAME}.tfvars"
  when: manual
```

---

## Validation and Testing

### Validate Configuration

```bash
# Validate syntax
terraform validate

# Format code
terraform fmt -recursive

# Check plan
terraform plan -var-file="environments/prod.tfvars"
```

### Test Different Configurations

```bash
# Test dev config
terraform plan -var-file="environments/dev.tfvars" -out=dev.tfplan

# Test staging config
terraform plan -var-file="environments/staging.tfvars" -out=staging.tfplan

# Test prod config
terraform plan -var-file="environments/prod.tfvars" -out=prod.tfplan
```

---

## Troubleshooting

### Issue: Variables not being loaded

**Solution:** Ensure you're using the correct path:
```bash
terraform apply -var-file="./environments/prod.tfvars"
```

### Issue: Conflicting variable values

**Solution:** Check variable precedence:
1. Environment variables (TF_VAR_*)
2. terraform.tfvars
3. *.auto.tfvars
4. -var-file flags (in order)
5. -var flags (in order)

### Issue: Cannot find tfvars file

**Solution:** Use absolute or relative path:
```bash
terraform apply -var-file="$(pwd)/environments/prod.tfvars"
```

---

## Best Practices

1. **Version Control:** Commit tfvars files (except sensitive data)
2. **Naming Convention:** Use `{environment}.tfvars` pattern
3. **Documentation:** Comment complex configurations
4. **Validation:** Always run `terraform plan` before `apply`
5. **State Management:** Use remote state for team collaboration
6. **Secrets:** Use AWS Secrets Manager or environment variables for sensitive data
7. **Tagging:** Maintain consistent tagging across environments

---

## Next Steps

After deploying your VPC:

1. **Configure VPC Flow Logs:**
   ```bash
   # Deploy flow logs module
   terraform apply -var-file="vpc-flow-logs.tfvars"
   ```

2. **Set up Network ACLs:**
   - Review default NACL rules
   - Create custom NACLs if needed

3. **Deploy Application Resources:**
   - EC2 instances
   - RDS databases
   - EKS clusters
   - Load balancers

4. **Enable Monitoring:**
   - CloudWatch dashboards
   - VPC Flow Logs analysis
   - Cost monitoring

5. **Security Hardening:**
   - Security group rules
   - Network Firewall policies
   - WAF rules
