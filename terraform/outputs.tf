output "instance_id" {
  description = "The ID of the target EC2 instance"
  value       = data.aws_instance.target.id
}

output "instance_private_ip" {
  description = "The private IP address of the target EC2 instance"
  value       = data.aws_instance.target.private_ip
}

output "instance_public_ip" {
  description = "The public IP address of the target EC2 instance"
  value       = data.aws_instance.target.public_ip
}

output "instance_public_dns" {
  description = "The public DNS name of the target EC2 instance"
  value       = data.aws_instance.target.public_dns
}

output "deployment_target_ip" {
  description = "The IP address used for deployment (private if available, public otherwise)"
  value       = local.target_ip
}

output "application_url" {
  description = "URL to access the deployed application (HTTP)"
  value       = "http://${data.aws_instance.target.public_ip}"
}

output "deployment_status" {
  description = "Status of the deployment"
  value       = "Deployment complete. Application running on instance ${data.aws_instance.target.id}"
}

output "security_group_id" {
  description = "The security group ID being used"
  value       = data.aws_security_group.target.id
}

output "deployment_info" {
  description = "Comprehensive deployment information"
  value = {
    instance_id        = data.aws_instance.target.id
    instance_type      = data.aws_instance.target.instance_type
    availability_zone  = data.aws_instance.target.availability_zone
    vpc_id             = data.aws_instance.target.vpc_id
    security_group_id  = data.aws_security_group.target.id
    private_ip         = data.aws_instance.target.private_ip
    public_ip          = data.aws_instance.target.public_ip
    public_dns         = data.aws_instance.target.public_dns
    application_url    = "http://${data.aws_instance.target.public_ip}"
    ssh_access         = "ssh -i <key.pem> ${var.instance_user}@${local.target_ip}"
    deployment_message = "Application deployed successfully"
    deployment_time    = timestamp()
  }
}
