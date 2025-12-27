#!/bin/bash
set -e

echo "🚀 Starting DevOps Infrastructure Deployment"

# Step 1: Provision Infrastructure
echo "📦 Step 1: Provisioning infrastructure with Terraform..."
cd infrastructure
terraform init
terraform plan -var-file=environments/dev.tfvars
terraform apply -var-file=environments/dev.tfvars -auto-approve

echo "✅ Infrastructure provisioned successfully"
echo "⏳ Waiting 30 seconds for instances to initialize..."
sleep 30

# Step 2: Setup Passwordless SSH
echo "🔑 Step 2: Setting up passwordless SSH authentication..."
cd ..
./setup-ssh.sh

# Step 3: Configure with Ansible
echo "🔧 Step 3: Configuring servers with Ansible..."
cd ansible

echo "Testing connectivity..."
ansible all -m ping

echo "Running configuration playbooks..."
ansible-playbook playbooks/site.yml

echo "✅ Configuration completed successfully"

# Step 4: Display Access Information
echo ""
echo "🎉 Deployment Complete!"
echo "================================"
cd ../infrastructure
echo "Jenkins Master URL: http://$(terraform output -raw jenkins_master_public_ip):8080"
echo "Ansible Controller IP: $(terraform output -raw ansible_controller_public_ip)"
echo ""
echo "📝 Next Steps:"
echo "1. Access Jenkins UI and complete setup wizard"
echo "2. Configure Jenkins agents in Jenkins UI"
echo "3. Create your first pipeline"
