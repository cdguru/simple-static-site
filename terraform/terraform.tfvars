# ============================================================================
# Terraform Configuration for SSH-based Deployment
# Deploys to EXISTING server via SSH - NO AWS credentials required
# ============================================================================
#
# FOR LOCAL DEVELOPMENT: Copy terraform.tfvars.example to terraform.tfvars
#   cp terraform.tfvars.example terraform.tfvars
#   Then edit with your actual values
#
# FOR CI/CD (Jenkins/GitHub Actions): Variables are passed via environment
#   export TF_VAR_target_ip="your-ip"
#   export TF_VAR_private_key_path="/path/to/key"
#   export TF_VAR_repository_url="https://github.com/.../repo.git"
#
# This file is intentionally kept empty for CI/CD compatibility
# See terraform.tfvars.example for template with all available variables
