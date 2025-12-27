[ansible_controller]
${ansible_controller_ip}

[jenkins_master]
${jenkins_master_ip}

[jenkins_agents]
%{ for ip in jenkins_agent_ips ~}
${ip}
%{ endfor ~}

[all:vars]
ansible_user=ec2-user
ansible_ssh_private_key_file=~/.ssh/abhimanyu-innovantra.pem
