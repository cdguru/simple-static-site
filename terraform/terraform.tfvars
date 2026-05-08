# ============================================================================
# Terraform Configuration for SSH-based Deployment
# Deploys to EXISTING server via SSH - NO AWS credentials required
# ============================================================================

# REQUIRED: IP address of the target server (public or private IP)
# Example: 54.123.45.67 or 192.168.1.100
target_ip = "YOUR_SERVER_IP_HERE"  # UPDATE THIS!

# REQUIRED: Path to your SSH private key file (.pem or similar)
# Example: ~/.ssh/my-key.pem or /path/to/key.pem
private_key_path = "/path/to/your/key.pem"  # UPDATE THIS!

# REQUIRED: Git repository URL (HTTPS)
# Example: https://github.com/username/simple-static-site.git
repository_url = "https://github.com/cdguru/simple-static-site.git"

# OPTIONAL: SSH user for the server
# ec2-user = Amazon Linux
# ubuntu   = Ubuntu
# admin    = Debian
instance_user = "ec2-user"

# OPTIONAL: Environment name for reference/logging
environment = "production"
