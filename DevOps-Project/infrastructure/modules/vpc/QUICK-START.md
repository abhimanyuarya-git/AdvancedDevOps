# VPC Module - Quick Start Guide

## 🚀 Deploy in 3 Steps

### Step 1: Initialize
```bash
cd /Users/abhi/codeclub/AdvancedDevOps/DevOps-Project/infrastructure/modules/vpc
terraform init
```

### Step 2: Choose Environment
```bash
# Development (1 NAT Gateway - $35/month)
terraform plan -var-file="environments/dev.tfvars"

# Staging (2 NAT Gateways - $70/month)
terraform plan -var-file="environments/staging.tfvars"

# Production (3 NAT Gateways - $105/month)
terraform plan -var-file="environments/prod.tfvars"

# Production + Firewall (3 NAT Gateways + Inspection)
terraform plan -var-file="environments/prod-with-inspection.tfvars"
```

### Step 3: Deploy
```bash
terraform apply -var-file="environments/prod.tfvars"
```

## 📋 Common Commands

```bash
# Plan changes
terraform plan -var-file="environments/prod.tfvars"

# Apply changes
terraform apply -var-file="environments/prod.tfvars"

# Show outputs
terraform output

# Destroy resources
terraform destroy -var-file="environments/prod.tfvars"

# Format code
terraform fmt -recursive

# Validate configuration
terraform validate
```

## 🎯 Environment Comparison

| Environment | NAT Gateways | AZs | Cost/Month | Use Case |
|-------------|--------------|-----|------------|----------|
| **dev** | 1 | 2 | $35-45 | Development/Testing |
| **staging** | 2 | 2 | $70-90 | Pre-production |
| **prod** | 3 | 3 | $105-135 | Production |
| **prod-inspection** | 3 | 3 | $105-135+ | Enterprise/Compliance |

## 📁 Key Files

- `environments/dev.tfvars` - Development config
- `environments/staging.tfvars` - Staging config
- `environments/prod.tfvars` - Production config
- `terraform.tfvars.example` - Template for custom config
- `README.md` - Full documentation
- `USAGE.md` - Detailed usage guide

## 🔧 Customize Your VPC

```bash
# Copy example
cp terraform.tfvars.example my-vpc.tfvars

# Edit values
vim my-vpc.tfvars

# Deploy
terraform apply -var-file="my-vpc.tfvars"
```

## 📤 Access Outputs

```bash
# Show all outputs
terraform output

# Show specific output
terraform output vpc_id
terraform output public_subnet_ids
terraform output nat_gateway_ids
```

## 🆘 Troubleshooting

```bash
# Validate syntax
terraform validate

# Check formatting
terraform fmt -check

# Refresh state
terraform refresh -var-file="environments/prod.tfvars"

# Show current state
terraform show
```

## 📚 Need More Help?

- **Full Documentation**: See `README.md`
- **Usage Examples**: See `USAGE.md`
- **Environment Guide**: See `environments/README.md`
- **Changes Made**: See `REFINEMENTS.md`
- **Complete Summary**: See `SUMMARY.md`

## ✅ Pre-Deployment Checklist

- [ ] Terraform installed (>= 1.3)
- [ ] AWS credentials configured
- [ ] Reviewed tfvars file
- [ ] Checked CIDR block availability
- [ ] Confirmed NAT Gateway count
- [ ] Planned for costs
- [ ] Ran `terraform plan`

## 🎉 You're Ready!

```bash
terraform apply -var-file="environments/prod.tfvars"
```

---

**Questions?** Check `USAGE.md` for detailed examples and scenarios.
