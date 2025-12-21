# Step-02: Setting Up Passwordless SSH Authentication for Ansible

## Overview
Configure passwordless SSH authentication between the Ansible Controller and all managed nodes (Jenkins Master and Agents).

## Why Passwordless SSH?
- Enables seamless automation with Ansible
- Strengthens security (no password-based logins)
- Essential for CI/CD pipeline integration

## Automated Setup

### Quick Start
```bash
./setup-ssh.sh
```

This script automatically:
1. Generates SSH key pair on Ansible Controller
2. Distributes public key to all managed nodes
3. Verifies passwordless SSH connections

## Manual Setup (Alternative)

### 1. Generate SSH Key on Ansible Controller
```bash
ssh ec2-user@<ansible-controller-ip>
ssh-keygen -t rsa -b 4096
# Press Enter to accept defaults
```

### 2. Copy Public Key to Managed Nodes
```bash
# From Ansible Controller
ssh-copy-id ec2-user@<jenkins-master-ip>
ssh-copy-id ec2-user@<jenkins-agent-1-ip>
ssh-copy-id ec2-user@<jenkins-agent-2-ip>
```

### 3. Verify Passwordless Access
```bash
# From Ansible Controller
ssh ec2-user@<jenkins-master-ip>
ssh ec2-user@<jenkins-agent-ip>
```

### 4. Test with Ansible
```bash
cd ansible
ansible all -m ping
```

## Security Best Practices
- Set proper permissions: `chmod 600 ~/.ssh/id_rsa`
- Use passphrase for private key (optional)
- Rotate keys regularly
- Backup keys securely

## Troubleshooting

### Permission Denied
```bash
# Fix permissions on managed node
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

### Connection Timeout
- Check security group rules (port 22)
- Verify instance is running
- Check network connectivity

### Key Not Working
```bash
# Regenerate and redistribute
rm ~/.ssh/id_rsa*
ssh-keygen -t rsa -b 4096
# Run setup-ssh.sh again
```

## Verification
```bash
# From your local machine
ssh ec2-user@<ansible-controller-ip>

# From Ansible Controller
ssh ec2-user@<jenkins-master-ip>
ansible all -m shell -a "hostname"
```

✅ After completing this step, Ansible can manage all nodes without password prompts.
