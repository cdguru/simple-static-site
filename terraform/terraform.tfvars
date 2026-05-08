# ============================================================================
# Terraform Configuration for Deployment-Only Mode
# Deploys to EXISTING EC2 instance - DO NOT CREATE resources
# ============================================================================

# REQUIRED: AWS region where your instance exists
aws_region = "us-east-1"

# REQUIRED: Instance ID of your EXISTING EC2 instance
# Example: i-0123456789abcdef
instance_id = "i-XXXXXXXXXXXXXXXXX"  # UPDATE THIS!

# REQUIRED: Path to your EC2 key pair (.pem file)
# Example: ~/.ssh/my-key.pem or /path/to/key.pem
private_key_path = "/path/to/your/key.pem"  # UPDATE THIS!

# REQUIRED: Git repository URL (HTTPS)
# Example: https://github.com/username/simple-static-site.git
repository_url = "https://github.com/cdguru/simple-static-site.git"

# OPTIONAL: SSH user for the instance
# ec2-user = Amazon Linux
# ubuntu   = Ubuntu
# admin    = Debian
instance_user = "ec2-user"

# OPTIONAL: Specific security group ID to modify
# Leave empty to use the instance's primary security group
security_group_id = ""

# OPTIONAL: Enable/disable ports on security group
enable_http  = true
enable_https = true

# Reference name for environment
environment = "production"
