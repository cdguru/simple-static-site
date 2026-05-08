#!/bin/bash
# Terraform deployment script for programmatic execution (Jenkins, GitHub Actions, etc.)
# DEPLOYMENT-ONLY MODE: Deploys to EXISTING EC2 instance
# Usage: ./deploy.sh [action] [options]
# Example: ./deploy.sh apply -var="instance_id=i-0123456789abcdef" -var="private_key_path=/path/to/key.pem"

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
ACTION="${1:-plan}"
TERRAFORM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function to print colored output
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Function to print usage
usage() {
    cat << EOF
Usage: $0 [action] [terraform_options]

Actions (DEPLOYMENT-ONLY MODE - targeting existing EC2 instance):
  init       Initialize Terraform working directory
  plan       Generate and show execution plan
  apply      Apply deployment to existing instance
  destroy    Remove deployed application (keep instance running)
  validate   Validate Terraform configuration
  refresh    Refresh remote state

REQUIRED Variables for deployment:
  -var="instance_id=i-XXXXXXXXX"           Instance ID of existing EC2
  -var="private_key_path=/path/to/key.pem" Path to EC2 key pair
  -var="repository_url=https://..."        Git repository HTTPS URL

Examples:
  # Deploy to existing instance
  $0 apply \
    -var="instance_id=i-0123456789abcdef" \
    -var="private_key_path=~/.ssh/my-key.pem" \
    -var="repository_url=https://github.com/username/simple-static-site.git"
  
  # Deploy with auto-approve (for CI/CD)
  $0 apply -auto-approve \
    -var="instance_id=i-0123456789abcdef" \
    -var="private_key_path=/path/to/key.pem" \
    -var="repository_url=https://github.com/username/simple-static-site.git"
  
  # Deploy with variable file
  $0 apply -var-file="production.tfvars"
  
  # Destroy application (keep instance running)
  $0 destroy -auto-approve -var-file="production.tfvars"

Environment Variables (alternative to -var):
  TF_VAR_aws_region           AWS region (default: us-east-1)
  TF_VAR_instance_id          Instance ID (REQUIRED)
  TF_VAR_private_key_path     Path to .pem file (REQUIRED)
  TF_VAR_instance_user        SSH user (default: ec2-user)
  TF_VAR_repository_url       Git repo URL (REQUIRED)
  TF_VAR_security_group_id    Specific SG to modify (optional)
  TF_VAR_enable_http          Enable HTTP port 80 (default: true)
  TF_VAR_enable_https         Enable HTTPS port 443 (default: true)

EOF
    exit 1
}

# Validate action
case "$ACTION" in
    init|plan|apply|destroy|validate|refresh)
        ;;
    -h|--help|help)
        usage
        ;;
    *)
        log_error "Unknown action: $ACTION"
        usage
        ;;
esac

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    log_error "Terraform not found. Please install Terraform >= 1.0"
    exit 1
fi

# Check if AWS credentials are configured
if [ -z "$AWS_ACCESS_KEY_ID" ] && [ ! -f ~/.aws/credentials ]; then
    log_error "AWS credentials not configured. Set AWS_ACCESS_KEY_ID/AWS_SECRET_ACCESS_KEY or configure ~/.aws/credentials"
    exit 1
fi

log_info "Terraform Directory: $TERRAFORM_DIR"
log_info "Mode: DEPLOYMENT-ONLY (targeting existing EC2 instance)"
log_info "Action: $ACTION"
log_info "Additional options: ${@:2}"

cd "$TERRAFORM_DIR"

# Initialize if not already done
if [ ! -d ".terraform" ]; then
    log_info "Terraform working directory not initialized. Running init..."
    terraform init
fi

# Execute terraform command
case "$ACTION" in
    init)
        log_info "Initializing Terraform..."
        terraform init "${@:2}"
        log_info "Terraform initialized successfully"
        ;;
    plan)
        log_info "Generating Terraform plan..."
        terraform plan "${@:2}"
        log_info "Plan generated successfully"
        ;;
    apply)
        log_warn "DEPLOYMENT-ONLY MODE: Will deploy application to EXISTING EC2 instance"
        log_info "Applying Terraform configuration..."
        terraform apply "${@:2}"
        log_info "Terraform apply completed successfully"
        log_info "View outputs with: terraform output"
        ;;
    destroy)
        log_warn "CAREFUL: You are about to remove the deployed application"
        log_warn "The EC2 instance will remain running (not terminated)"
        if [ "$2" != "-auto-approve" ]; then
            read -p "Are you sure? (yes/no): " -r
            if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
                log_info "Destroy cancelled"
                exit 0
            fi
        fi
        terraform destroy "${@:2}"
        log_info "Application removed (instance still running)"
        ;;
    validate)
        log_info "Validating Terraform configuration..."
        terraform validate "${@:2}"
        log_info "Configuration is valid"
        ;;
    refresh)
        log_info "Refreshing remote state..."
        terraform refresh "${@:2}"
        log_info "State refreshed successfully"
        ;;
esac

log_info "Done!"
