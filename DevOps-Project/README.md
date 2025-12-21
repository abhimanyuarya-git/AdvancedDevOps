# DevOps Project - Infrastructure Automation

## Overview
This project provisions a complete CI/CD infrastructure using Terraform and configures it using Ansible.

## Architecture
- **VPC**: Isolated network with public/private subnets
- **Security Groups**: Firewall rules for each component
- **Ansible Controller**: Configuration management server
- **Jenkins Master**: CI/CD orchestration server
- **Jenkins Agents**: Worker nodes for parallel job execution

## Prerequisites
- AWS CLI configured with credentials
- Terraform >= 1.0
- Ansible >= 2.9
- SSH key pair created in AWS (abhimanyu-innovantra)

## Step 1: Provision Infrastructure

### Initialize Terraform
```bash
cd infrastructure
terraform init
```

### Plan Infrastructure
```bash
terraform plan -var-file=environments/dev.tfvars
```

### Apply Infrastructure
```bash
terraform apply -var-file=environments/dev.tfvars -auto-approve
```

### Get Outputs
```bash
terraform output
```

## Step 2: Configure with Ansible

### Verify Inventory
```bash
cd ../ansible
cat inventory/hosts.ini
```

### Setup Passwordless SSH (Automated)
```bash
cd ..
./setup-ssh.sh
```

Or manually:
```bash
# SSH to Ansible Controller
ssh ec2-user@<ansible-controller-ip>

# Generate SSH key
ssh-keygen -t rsa -b 4096

# Copy to managed nodes
ssh-copy-id ec2-user@<jenkins-master-ip>
ssh-copy-id ec2-user@<jenkins-agent-ip>
```

### Test Connectivity
```bash
ansible all -m ping
```

### Run Configuration Playbooks
```bash
# Configure all servers
ansible-playbook playbooks/site.yml

# Or configure individually
ansible-playbook playbooks/ansible-controller.yml
ansible-playbook playbooks/jenkins-master.yml
ansible-playbook playbooks/jenkins-agent.yml
```

## Step 3: Access Jenkins

### Get Jenkins Initial Password
The password will be displayed after running the playbook, or SSH to Jenkins Master:
```bash
ssh -i ~/.ssh/abhimanyu-innovantra.pem ec2-user@<jenkins-master-ip>
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

### Access Jenkins UI
```
http://<jenkins-master-ip>:8080
```

## Step 4: Configure Jenkins Agents

1. Login to Jenkins Master
2. Go to **Manage Jenkins** → **Manage Nodes and Clouds**
3. Click **New Node**
4. Configure each agent with:
   - Name: jenkins-agent-1, jenkins-agent-2
   - Remote root directory: /home/ec2-user/jenkins-agent
   - Launch method: Launch agents via SSH
   - Host: <agent-ip>
   - Credentials: Add SSH key

## Remote State Management (Optional)

### Create S3 Bucket and DynamoDB Table
```bash
aws s3api create-bucket --bucket devops-project-terraform-state --region us-east-1
aws s3api put-bucket-versioning --bucket devops-project-terraform-state --versioning-configuration Status=Enabled
aws dynamodb create-table --table-name terraform-state-lock --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --billing-mode PAY_PER_REQUEST
```

### Migrate to Remote Backend
Uncomment backend configuration in `backend.tf` and run:
```bash
terraform init -migrate-state
```

## Monitoring and Maintenance

### Check Instance Status
```bash
ansible all -m shell -a "uptime"
```

### Update Packages
```bash
ansible all -m yum -a "name=* state=latest" --become
```

## Cleanup

### Destroy Infrastructure
```bash
cd infrastructure
terraform destroy -var-file=environments/dev.tfvars -auto-approve
```

## Best Practices Implemented
✅ Infrastructure as Code (Terraform)
✅ Configuration Management (Ansible)
✅ Security Groups with least privilege
✅ Modular Terraform structure
✅ Remote state management ready
✅ Automated inventory generation
✅ Version control ready

## Next Steps
- Set up Jenkins pipelines
- Integrate Jenkins with Ansible
- Configure monitoring (CloudWatch/Prometheus)
- Implement backup strategies
- Set up CI/CD workflows
