# Terraform Deployment Guide (SSH-based Deployment)

**Simple SSH-based deployment to any server - No AWS credentials needed!**

This Terraform configuration deploys the static site application to an existing server via SSH. Works with any server (EC2, VPS, on-premises, etc.) - you just need the IP address and SSH access.

## Prerequisites

1. **Target Server (any provider or on-premises)**
   - Server must be running and accessible
   - IP address (public or private/internal)
   - SSH port open (port 22)
   - Docker pre-installed

2. **SSH Key Pair**
   - SSH private key file for accessing the server
   - File must exist locally and be readable
   - Permissions: `chmod 400 key.pem`

3. **Terraform** (>= 1.0)
   - [Install Terraform](https://www.terraform.io/downloads.html)

4. **Git** installed on local machine

## Configuration

### Available Variables

| Variable | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `target_ip` | string | **YES** | - | IP address of target server (public or private) |
| `instance_user` | string | No | `ec2-user` | SSH user (ec2-user, ubuntu, admin, root, etc.) |
| `private_key_path` | string | **YES** | - | Path to SSH private key file |
| `repository_url` | string | **YES** | - | Git repository HTTPS URL |
| `environment` | string | No | `production` | Environment name for reference |

### Method 1: Local Development (terraform.tfvars)

Edit `terraform.tfvars` and update **REQUIRED** variables:

```hcl
# REQUIRED
target_ip        = "54.123.45.67"  # Your server's IP
private_key_path = "~/.ssh/my-key.pem"
repository_url   = "https://github.com/cdguru/simple-static-site.git"

# OPTIONAL
instance_user = "ec2-user"  # or "ubuntu", "root", etc.
environment   = "production"
```

### Method 2: Command Line Variables (Recommended for CI/CD)

```bash
terraform apply \
  -var="target_ip=54.123.45.67" \
  -var="private_key_path=~/.ssh/my-key.pem" \
  -var="repository_url=https://github.com/cdguru/simple-static-site.git" \
  -var="instance_user=ec2-user"
```

### Method 3: Environment Variables

```bash
export TF_VAR_target_ip="54.123.45.67"
export TF_VAR_private_key_path="~/.ssh/my-key.pem"
export TF_VAR_repository_url="https://github.com/cdguru/simple-static-site.git"
export TF_VAR_instance_user="ec2-user"
export TF_VAR_environment="production"

terraform apply
```

### Method 4: Variable Files (.tfvars)

**production.tfvars:**
```hcl
target_ip        = "54.123.45.67"
private_key_path = "~/.ssh/prod-key.pem"
repository_url   = "https://github.com/cdguru/simple-static-site.git"
instance_user    = "ec2-user"
environment      = "production"
```

Deploy:
```bash
terraform apply -var-file="production.tfvars"
```

## Deployment Steps

### Step 0: Prepare Your Server

1. **Get the server IP address** (public or private)
2. **Verify SSH access**:
   ```bash
   ssh -i /path/to/key.pem user@<server-ip>
   ```
3. **Verify Docker is installed**:
   ```bash
   docker --version
   ```
4. **Note the SSH username** (ec2-user, ubuntu, root, etc.)

### Step 1: Configure Variables

Edit `terraform.tfvars`:

```hcl
target_ip        = "YOUR_SERVER_IP"  # Update this!
private_key_path = "/path/to/key.pem"  # Update this!
repository_url   = "https://github.com/cdguru/simple-static-site.git"
instance_user    = "ec2-user"  # Update if different
```

### Step 2: Initialize Terraform

```bash
cd terraform
terraform init
```

### Step 3: Plan the Deployment

```bash
terraform plan
```

This shows what will be deployed. You should see:
- `null_resource.deploy` will be created (handles SSH deployment)

### Step 4: Apply Configuration

```bash
terraform apply
```

Type `yes` to proceed. Terraform will:
1. Connect to your server via SSH
2. Upload the deployment script
3. Execute the script to:
   - Clone the repository
   - Build the Docker image
   - Start the Docker container on port 80

**Deployment takes 30-60 seconds** depending on:
- Repository size
- Docker image build time
- Network speed

### Step 5: View Outputs

After deployment completes, Terraform shows:

```
Outputs:

application_url = "http://54.123.45.67"
deployment_info = {...}
```

### Step 6: Verify Deployment

Open browser and visit the application:

```
http://<server-ip>
```

**Or SSH to verify Docker**:

```bash
ssh -i /path/to/key.pem user@<server-ip>
docker ps
docker logs simple-static-site
```

## Jenkins Integration

Configure Jenkins with these parameters:

```groovy
parameters {
    string(name: 'TARGET_IP', description: 'Server IP address')
    string(name: 'INSTANCE_USER', defaultValue: 'ec2-user', description: 'SSH user')
    string(name: 'PRIVATE_KEY_PATH', description: 'Path to SSH key')
    string(name: 'REPOSITORY_URL', defaultValue: 'https://github.com/cdguru/simple-static-site.git')
    choice(name: 'ENVIRONMENT', choices: ['development', 'staging', 'production'])
    choice(name: 'ACTION', choices: ['plan', 'apply', 'validate', 'destroy'])
}
```

**No AWS credentials required!** Only SSH key access.

**Setup:**

1. Create Jenkins credentials:
   - Jenkins Dashboard → Credentials → System → Global credentials
   - No AWS credentials needed!
   - Just ensure SSH key access to target server

2. Create Jenkins Pipeline Job:
   - Jenkins Dashboard → New Item
   - Choose `Pipeline`
   - Pipeline section:
     - Definition: Pipeline script from SCM
     - SCM: Git
     - Repository URL: Your repository
     - Script Path: `Jenkinsfile`

3. Build with Parameters:
   - Click "Build with Parameters"
   - Configure variables:
     - TARGET_IP: 54.123.45.67 (your server IP)
     - INSTANCE_USER: ec2-user (your SSH user)
     - PRIVATE_KEY_PATH: /path/to/key.pem
     - REPOSITORY_URL: https://github.com/cdguru/simple-static-site.git
     - ACTION: plan (or apply/destroy)
   - Click "Build"

## Troubleshooting

### SSH Connection Failed
```bash
# Test SSH connectivity
ssh -i /path/to/key.pem user@<ip> echo "Connected"

# Check key permissions
chmod 400 /path/to/key.pem

# Verify port 22 is open
nc -zv <ip> 22
```

### Docker Not Found
```bash
# SSH to server and install Docker
ssh -i /path/to/key.pem user@<ip>
sudo yum install docker  # Amazon Linux
# OR
sudo apt-get install docker.io  # Ubuntu
sudo systemctl start docker
```

### Terraform Timeout
- Increase connection timeout in main.tf if needed
- Verify server responds to HTTPS (for git clone)
- Check server has outbound internet access

### Re-Deploy

To redeploy the application:

```bash
terraform destroy -auto-approve
terraform apply -auto-approve
```

## Cleanup

To remove the application from the server:

```bash
terraform destroy
```

This stops the Docker container but **does NOT terminate the server**.

## Security Notes

- Never commit `.pem` files to git (add to `.gitignore`)
- Use SSH keys instead of passwords
- Restrict key file permissions: `chmod 400 key.pem`
- Store sensitive paths in `.tfvars` (excluded from git)

## Files

- `main.tf` - Main Terraform configuration
- `variables.tf` - Variable definitions
- `outputs.tf` - Output values
- `terraform.tfvars` - Default variable values (UPDATE THESE!)
- `.gitignore` - Excludes sensitive files
- `Jenkinsfile` - Jenkins pipeline integration
