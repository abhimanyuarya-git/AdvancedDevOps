#!/bin/bash
set -e

echo "🔑 Step-02: Setting Up Passwordless SSH Authentication"
echo "======================================================="

# Get IPs from Terraform output
cd infrastructure
ANSIBLE_IP=$(terraform output -raw ansible_controller_public_ip)
JENKINS_MASTER_IP=$(terraform output -raw jenkins_master_public_ip)
JENKINS_AGENT_IPS=$(terraform output -json jenkins_agent_public_ips | jq -r '.[]')

cd ..

echo "📍 Ansible Controller: $ANSIBLE_IP"
echo "📍 Jenkins Master: $JENKINS_MASTER_IP"
echo "📍 Jenkins Agents: $JENKINS_AGENT_IPS"
echo ""

# Step 1: Generate SSH key on Ansible Controller
echo "🔐 Step 1: Generating SSH key pair on Ansible Controller..."
ssh -o StrictHostKeyChecking=no ec2-user@$ANSIBLE_IP "
  if [ ! -f ~/.ssh/id_rsa ]; then
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ''
    echo '✅ SSH key pair generated'
  else
    echo '✅ SSH key pair already exists'
  fi
"

# Step 2: Get public key from Ansible Controller
echo ""
echo "📤 Step 2: Retrieving public key from Ansible Controller..."
PUB_KEY=$(ssh ec2-user@$ANSIBLE_IP "cat ~/.ssh/id_rsa.pub")
echo "✅ Public key retrieved"

# Step 3: Distribute public key to Jenkins Master
echo ""
echo "📥 Step 3: Distributing public key to Jenkins Master..."
ssh ec2-user@$JENKINS_MASTER_IP "
  mkdir -p ~/.ssh
  chmod 700 ~/.ssh
  echo '$PUB_KEY' >> ~/.ssh/authorized_keys
  chmod 600 ~/.ssh/authorized_keys
  sort -u ~/.ssh/authorized_keys -o ~/.ssh/authorized_keys
"
echo "✅ Public key added to Jenkins Master"

# Step 4: Distribute public key to Jenkins Agents
echo ""
echo "📥 Step 4: Distributing public key to Jenkins Agents..."
for AGENT_IP in $JENKINS_AGENT_IPS; do
  echo "  → Configuring agent: $AGENT_IP"
  ssh ec2-user@$AGENT_IP "
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    echo '$PUB_KEY' >> ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/authorized_keys
    sort -u ~/.ssh/authorized_keys -o ~/.ssh/authorized_keys
  "
  echo "  ✅ Public key added to $AGENT_IP"
done

# Step 5: Verify passwordless SSH
echo ""
echo "🧪 Step 5: Verifying passwordless SSH connections..."
echo "Testing Jenkins Master..."
ssh ec2-user@$ANSIBLE_IP "ssh -o StrictHostKeyChecking=no ec2-user@$JENKINS_MASTER_IP 'echo Connected to Jenkins Master'" && echo "✅ Jenkins Master: SUCCESS"

for AGENT_IP in $JENKINS_AGENT_IPS; do
  echo "Testing Jenkins Agent: $AGENT_IP..."
  ssh ec2-user@$ANSIBLE_IP "ssh -o StrictHostKeyChecking=no ec2-user@$AGENT_IP 'echo Connected to Jenkins Agent'" && echo "✅ Agent $AGENT_IP: SUCCESS"
done

echo ""
echo "🎉 Passwordless SSH Setup Complete!"
echo "===================================="
echo "✅ Ansible Controller can now manage all nodes without passwords"
echo ""
echo "📝 Test from Ansible Controller:"
echo "   ssh ec2-user@$ANSIBLE_IP"
echo "   ssh ec2-user@$JENKINS_MASTER_IP"
