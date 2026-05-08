# ============================================================================
# Variables for Deployment-Only Approach (existing EC2 instance)
# ============================================================================
# This configuration deploys to an EXISTING EC2 instance.
# Do NOT create new AWS resources - only deploy the application.
# ============================================================================

variable "aws_region" {
  description = "AWS region where the existing EC2 instance is located"
  type        = string
  default     = "us-east-1"
}

variable "instance_id" {
  description = "REQUIRED: The instance ID of the EXISTING EC2 instance (e.g., i-0123456789abcdef)"
  type        = string
  validation {
    condition     = can(regex("^i-[a-f0-9]{17}$", var.instance_id))
    error_message = "instance_id must be a valid AWS instance ID format (i-xxxxxxxxxxxxx)."
  }
}

variable "instance_user" {
  description = "SSH user for EC2 instance (ec2-user for Amazon Linux, ubuntu for Ubuntu)"
  type        = string
  default     = "ec2-user"
  validation {
    condition     = contains(["ec2-user", "ubuntu", "admin", "root"], var.instance_user)
    error_message = "instance_user should be one of: ec2-user, ubuntu, admin, root."
  }
}

variable "private_key_path" {
  description = "REQUIRED: Path to the EC2 key pair private key file (e.g., ~/.ssh/my-key.pem)"
  type        = string
}

variable "repository_url" {
  description = "REQUIRED: Git repository URL (HTTPS) for cloning the application"
  type        = string
  validation {
    condition     = can(regex("^https://", var.repository_url))
    error_message = "repository_url must be an HTTPS URL."
  }
}

variable "security_group_id" {
  description = "OPTIONAL: Specific security group ID to modify. If not provided, will use the instance's primary security group"
  type        = string
  default     = ""
}

variable "enable_http" {
  description = "Enable HTTP access (port 80) on the security group"
  type        = bool
  default     = true
}

variable "enable_https" {
  description = "Enable HTTPS access (port 443) on the security group"
  type        = bool
  default     = true
}

variable "environment" {
  description = "Environment name for reference/logging"
  type        = string
  default     = "production"
}
