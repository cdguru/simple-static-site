output "target_ip" {
  description = "The IP address of the target server"
  value       = var.target_ip
}

output "deployment_target_ip" {
  description = "The IP address used for SSH deployment"
  value       = local.target_ip
}

output "application_url" {
  description = "URL to access the deployed application (HTTP)"
  value       = "http://${var.target_ip}"
}

output "deployment_status" {
  description = "Status of the deployment"
  value       = "Deployment complete. Application running on ${var.target_ip}"
}

output "deployment_info" {
  description = "Comprehensive deployment information"
  value = {
    target_ip       = var.target_ip
    ssh_user        = var.instance_user
    private_key     = var.private_key_path
    repository      = var.repository_url
    environment     = var.environment
    application_url = "http://${var.target_ip}"
    ssh_command     = "ssh -i ${var.private_key_path} ${var.instance_user}@${var.target_ip}"
    deployment_time = timestamp()
  }
}
