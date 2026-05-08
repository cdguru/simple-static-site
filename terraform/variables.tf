# ============================================================================
# Variables for Deployment-Only Approach (SSH deployment to existing server)
# ============================================================================
# This configuration deploys to an EXISTING server via SSH.
# No AWS credentials or resources are needed.
# ============================================================================

variable "target_ip" {
  description = "REQUIRED: IP address of the target server (public or private IP that's reachable)"
  type        = string
  validation {
    condition     = can(regex("^\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}$", var.target_ip))
    error_message = "target_ip must be a valid IP address (e.g., 192.168.1.1 or 54.123.45.67)."
  }
}

variable "instance_user" {
  description = "SSH user for the target server (ec2-user for Amazon Linux, ubuntu for Ubuntu, etc.)"
  type        = string
  default     = "ec2-user"
  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]+$", var.instance_user))
    error_message = "instance_user must be a valid username."
  }
}

variable "private_key_path" {
  description = "REQUIRED: Path to the SSH private key file (e.g., ~/.ssh/my-key.pem)"
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

variable "environment" {
  description = "Environment name for reference/logging"
  type        = string
  default     = "production"
}
