resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/templates/inventory.tpl", {
    ansible_controller_ip = aws_instance.ansible_controller.public_ip
    jenkins_master_ip     = aws_instance.jenkins_master.public_ip
    jenkins_agent_ips     = aws_instance.jenkins_agent[*].public_ip
  })
  filename = "${path.module}/../ansible/inventory/hosts.ini"
}
