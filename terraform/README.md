# Terraform Deployment Guide (Deployment-Only Mode)

**IMPORTANT: This configuration deploys to an EXISTING EC2 instance in AWS. It does NOT create infrastructure.**

This Terraform setup is designed to deploy the static site application to an existing EC2 instance via SSH. No AWS resources are created or modified beyond adding necessary security group rules for HTTP/HTTPS access.

## Prerequisites

1. **EXISTING EC2 Instance**
   - Instance must be running in AWS
   - Instance ID (format: `i-XXXXXXXXXXXXXXXXX`)
   - Accessible via SSH
   - Docker already installed
   - Has associated security group

2. **EC2 Key Pair**
   - SSH private key file (.pem) for the instance
   - File must exist locally and be readable
   - Permissions: `chmod 400 key.pem`

3. **Terraform** (>= 1.0)
   - [Install Terraform](https://www.terraform.io/downloads.html)

4. **AWS Credentials** (for read-only access)
   - Option A: AWS CLI credentials at `~/.aws/credentials`
   - Option B: Environment variables `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`
   - Option C: AWS IAM Role (if running Terraform from EC2)
   - **NOTE**: Only needs read access to query instance info

5. **Git** installed on local machine (for cloning repository)

## Configuration

### Available Variables

All deployment variables can be provided three ways:

| Variable | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `aws_region` | string | No | `us-east-1` | AWS region where instance exists |
| `instance_id` | string | **YES** | - | Instance ID to deploy to (e.g., i-0123456789abcdef) |
| `instance_user` | string | No | `ec2-user` | SSH user (ec2-user, ubuntu, admin) |
| `private_key_path` | string | **YES** | - | Path to EC2 key pair (.pem file) |
| `repository_url` | string | **YES** | - | Git repository HTTPS URL |
| `security_group_id` | string | No | "" | Specific SG to modify (auto-detected if empty) |
| `enable_http` | bool | No | `true` | Enable HTTP port 80 |
| `enable_https` | bool | No | `true` | Enable HTTPS port 443 |
| `environment` | string | No | `production` | Environment name for reference |

### Method 1: Local Development (terraform.tfvars)

Edit `terraform.tfvars` and update **REQUIRED** variables:

```hcl
# REQUIRED
instance_id       = "i-0123456789abcdef"
private_key_path  = "/Users/you/.ssh/my-key.pem"
repository_url    = "https://github.com/cdguru/simple-static-site.git"

# OPTIONAL
aws_region        = "us-east-1"
instance_user     = "ec2-user"  # or "ubuntu", "admin"
security_group_id = ""          # Leave empty to auto-detect
enable_http       = true
enable_https      = true
environment       = "production"
```

### Method 2: Command Line Variables (Recommended for CI/CD)

Pass variables directly via CLI using `-var` flag:

```bash
terraform apply \
  -var="instance_id=i-0123456789abcdef" \
  -var="private_key_path=/Users/you/.ssh/my-key.pem" \
  -var="repository_url=https://github.com/cdguru/simple-static-site.git"
```

Or using the deployment script:

```bash
./deploy.sh apply \
  -var="instance_id=i-0123456789abcdef" \
  -var="private_key_path=~/.ssh/my-key.pem" \
  -var="repository_url=https://github.com/cdguru/simple-static-site.git"
```

### Method 3: Environment Variables

Set Terraform variables using `TF_VAR_` prefix:

```bash
export TF_VAR_instance_id="i-0123456789abcdef"
export TF_VAR_private_key_path="/Users/you/.ssh/my-key.pem"
export TF_VAR_repository_url="https://github.com/yourusername/simple-static-site.git"
export TF_VAR_instance_user="ec2-user"
export TF_VAR_aws_region="us-east-1"
export TF_VAR_enable_http="true"
export TF_VAR_enable_https="true"

terraform apply
```

### Method 4: Variable Files

Create custom `.tfvars` files for different environments:

**production.tfvars:**
```hcl
aws_region       = "us-east-1"
instance_id      = "i-0123456789abcdef"
private_key_path = "/Users/you/.ssh/prod-key.pem"
repository_url   = "https://github.com/cdguru/simple-static-site.git"
instance_user    = "ec2-user"
enable_http      = true
enable_https     = true
environment      = "production"
```

**staging.tfvars:**
```hcl
aws_region       = "us-west-2"
instance_id      = "i-9876543210fedcba"
private_key_path = "/Users/you/.ssh/staging-key.pem"
repository_url   = "https://github.com/cdguru/simple-static-site.git"
instance_user    = "ubuntu"
enable_http      = true
enable_https     = false
environment      = "staging"
```

Deploy using variable file:

```bash
terraform apply -var-file="production.tfvars"
```

## Deployment Steps

### Step 0: Prepare Your Instance

Before deploying, ensure:

1. **Instance is running** in AWS
2. **Get the Instance ID**: Go to AWS Console → EC2 → Instances → Copy Instance ID
3. **Verify SSH access**:
   ```bash
   ssh -i /path/to/key.pem ec2-user@<public-ip>
   ```
4. **Verify Docker is installed**:
   ```bash
   docker --version
   ```
5. **Instance has security group with outbound internet access**

### Step 1: Configure Variables

Edit `terraform.tfvars` and update the three **REQUIRED** variables:

```hcl
instance_id       = "i-0123456789abcdef"  # Your existing instance ID
private_key_path  = "/Users/you/.ssh/my-key.pem"  # Path to your .pem file
repository_url    = "https://github.com/yourusername/simple-static-site.git"
```

### Step 2: Initialize Terraform

```bash
cd terraform
terraform init
```

**Expected output:**
```
Terraform has been successfully configured!
```

### Step 3: Review the Plan

```bash
terraform plan
```

This shows what Terraform will do (add security group rules and deploy application).

**Expected output** should show:
- 0-2 `aws_security_group_rule` (HTTP and/or HTTPS rules, if not already present)
- 1 `null_resource` provisioner (for SSH deployment)

**Example:**
```
Plan: 2 to add, 0 to change, 0 to destroy.

Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # aws_security_group_rule.allow_http will be created
  + resource "aws_security_group_rule" "allow_http" {
      ...
    }

  # null_resource.deploy will be created
  + resource "null_resource" "deploy" {
      ...
    }
```

### Step 4: Apply the Configuration

```bash
terraform apply
```

Review the plan output and type `yes` when prompted to proceed.

**What happens during apply:**
1. Security group rules are added (if needed)
2. SSH connection is established to your instance
3. Deployment script is uploaded to the instance
4. Script runs to:
   - Clone the Git repository
   - Build Docker image
   - Stop any previous container
   - Start new Docker container on port 80
5. Terraform monitors the deployment

**Expected output** should show:
- Resource creation in progress
- SSH connection output showing deployment steps

### Step 5: Monitor Deployment Progress

During `terraform apply`, you'll see provisioner output:

```
null_resource.deploy: Provisioning with 'file'...
null_resource.deploy: Uploading deployment script...
null_resource.deploy: Provisioning with 'remote-exec'...
null_resource.deploy: (remote-exec): Starting application deployment...
null_resource.deploy: (remote-exec): Cloning repository...
null_resource.deploy: (remote-exec): Building Docker image...
null_resource.deploy: (remote-exec): Starting Docker container...
null_resource.deploy: (remote-exec): ✓ Container started successfully
null_resource.deploy: Creation complete after 45s
```

**Deployment takes 30-60 seconds** depending on:
- Repository size
- Docker image build time
- Network speed

### Step 6: View Deployment Outputs

Once deployment completes, Terraform outputs will show:

```
Outputs:

application_url = "http://1.2.3.4"

deployment_info = {
  "application_url" = "http://1.2.3.4"
  "instance_id" = "i-0123456789abcdef"
  "instance_type" = "t3.micro"
  "private_ip" = "10.0.1.100"
  "public_ip" = "1.2.3.4"
  "ssh_access" = "ssh -i key.pem ec2-user@10.0.1.100"
}
```

### Step 7: Verify Application

Open your browser and visit the application URL:

```
http://<public-ip-from-outputs>
```

You should see the "Congratulations!" message from the static site.

**SSH into instance and verify**:

```bash
ssh -i /path/to/key.pem ec2-user@<public-ip>
docker ps
docker logs simple-static-site
```

## Verification Checklist

- [ ] Terraform initialized without errors
- [ ] Configuration shows deployment to existing instance (not creating resources)
- [ ] SSH connection successful during apply
- [ ] Deployment script uploads successfully
- [ ] Docker image builds without errors
- [ ] Container starts successfully
- [ ] Application accessible via HTTP at public IP
- [ ] "Congratulations!" page loads
- [ ] All outputs displayed correctly

## Programmatic Deployment (CI/CD)

This setup is optimized for programmatic execution from Jenkins, GitHub Actions, GitLab CI, or any CI/CD platform.

### Using the Deployment Script

The included `deploy.sh` script simplifies execution and is recommended for CI/CD:

```bash
# Make script executable
chmod +x deploy.sh

# Plan deployment
./deploy.sh plan \
  -var="instance_id=i-0123456789abcdef" \
  -var="private_key_path=/path/to/key.pem" \
  -var="repository_url=https://github.com/cdguru/simple-static-site.git"

# Apply with auto-approval (for CI/CD)
./deploy.sh apply -auto-approve \
  -var="instance_id=i-0123456789abcdef" \
  -var="private_key_path=/path/to/key.pem" \
  -var="repository_url=https://github.com/cdguru/simple-static-site.git"

# Destroy deployment (removes container, keeps instance)
./deploy.sh destroy -auto-approve \
  -var="instance_id=i-0123456789abcdef" \
  -var="private_key_path=/path/to/key.pem"
```

### Jenkins Integration

A complete `Jenkinsfile` is included for Jenkins pipeline execution:

**Features:**
- ✅ Parameterized builds (configure via Jenkins UI)
- ✅ Environment variables for Terraform
- ✅ Plan and approval workflow
- ✅ Auto-approval option for non-production
- ✅ Artifact archiving
- ✅ Post-deployment output display
- ✅ Deployment-only mode (no infrastructure creation)

**Setup:**

1. **Create Jenkins credentials** for AWS:
   - Jenkins Dashboard → Credentials → System → Global credentials
   - Add credentials type `Secret text`:
     - ID: `aws-access-key-id`
     - Secret: Your AWS Access Key ID
   - Add credentials type `Secret text`:
     - ID: `aws-secret-access-key`
     - Secret: Your AWS Secret Access Key
   - Add credentials type `Secret file`:
     - ID: `ec2-key-pem`
     - File: Upload your EC2 key pair .pem file
     - ID: `aws-secret-access-key`
     - Secret: Your AWS Secret Access Key
   - Add credentials type `Secret file`:
     - ID: `ec2-key-pem`
     - File: Upload your EC2 key pair .pem file

2. **Create Jenkins Pipeline Job:**
   - Jenkins Dashboard → New Item
   - Choose `Pipeline`
   - In Pipeline section:
     - Definition: Pipeline script from SCM
     - SCM: Git
     - Repository URL: Your repository
     - Script Path: `terraform/Jenkinsfile`

3. **Build with Parameters:**
   - Click "Build with Parameters"
   - Configure variables:
     - AWS_REGION: us-east-1 (region of your instance)
     - INSTANCE_ID: i-0123456789abcdef (your existing instance)
     - PRIVATE_KEY_PATH: /path/to/key.pem (path in Jenkins workspace)
     - INSTANCE_USER: ec2-user (or ubuntu)
     - REPOSITORY_URL: https://github.com/yourusername/simple-static-site.git
     - ACTION: plan (or apply/destroy)
     - AUTO_APPROVE: unchecked for production
   - Click "Build"

**Jenkins Pipeline Example Execution:**
```groovy
// Minimal Groovy code to trigger from another pipeline
build job: 'TerraformDeployment',
  parameters: [
    string(name: 'AWS_REGION', value: 'us-east-1'),
    string(name: 'INSTANCE_ID', value: 'i-0123456789abcdef'),
    string(name: 'ACTION', value: 'apply')
  ]
```

### GitHub Actions Integration

Example GitHub Actions workflow for deployment-only:

**`.github/workflows/terraform-deploy.yml`:**
```yaml
name: Deploy to Existing Instance

on:
  push:
    branches: [main]
    paths: ['terraform/**']
  workflow_dispatch:
    inputs:
      action:
        description: 'Terraform action'
        required: true
        default: 'plan'
        type: choice
        options:
          - plan
          - apply
          - destroy
      aws_region:
        description: 'AWS Region'
        required: false
        default: 'us-east-1'
      instance_type:
        description: 'Instance Type'
        required: false
        default: 't2.micro'

jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: ~1.0
      
      - name: Terraform Init
        run: |
          cd terraform
          terraform init
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
      
      - name: Terraform Plan
        run: |
          cd terraform
          terraform plan \
            -var="aws_region=${{ github.event.inputs.aws_region || 'us-east-1' }}" \
            -var="instance_type=${{ github.event.inputs.instance_type || 't2.micro' }}" \
            -var="repository_url=${{ github.server_url }}/${{ github.repository }}.git"
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
      
      - name: Terraform Apply
        if: github.event.inputs.action == 'apply'
        run: |
          cd terraform
          terraform apply -auto-approve \
            -var="aws_region=${{ github.event.inputs.aws_region || 'us-east-1' }}" \
            -var="instance_type=${{ github.event.inputs.instance_type || 't2.micro' }}" \
            -var="repository_url=${{ github.server_url }}/${{ github.repository }}.git"
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}

      - name: Output Results
        if: github.event.inputs.action == 'apply'
        run: |
          cd terraform
          echo "## Deployment Complete ✅" >> $GITHUB_STEP_SUMMARY
          echo "Application URL: $(terraform output application_url)" >> $GITHUB_STEP_SUMMARY
```

**GitHub Actions Setup:**
1. Go to Repository Settings → Secrets and variables → Actions
2. Add secrets:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
3. Commit `.github/workflows/terraform-deploy.yml`
4. Actions → Deploy Infrastructure → Run workflow

### Docker-based Execution

Run Terraform in Docker to ensure consistent environment:

```bash
docker run --rm \
  -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
  -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
  -e TF_VAR_aws_region=us-east-1 \
  -e TF_VAR_instance_type=t2.micro \
  -e TF_VAR_repository_url=https://github.com/yourusername/simple-static-site.git \
  -v $(pwd)/terraform:/terraform \
  -w /terraform \
  hashicorp/terraform:latest \
  apply -auto-approve
```

### GitLab CI Integration

Example `.gitlab-ci.yml`:

```yaml
stages:
  - plan
  - apply

variables:
  TERRAFORM_VERSION: "1.5"
  TF_ROOT: ${CI_PROJECT_DIR}/terraform

before_script:
  - cd ${TF_ROOT}
  - terraform init

plan:
  stage: plan
  image: hashicorp/terraform:latest
  script:
    - terraform plan
      -var="aws_region=${AWS_REGION:-us-east-1}"
      -var="instance_type=${INSTANCE_TYPE:-t2.micro}"
      -var="repository_url=${CI_PROJECT_URL}.git"

apply:
  stage: apply
  image: hashicorp/terraform:latest
  script:
    - terraform apply -auto-approve
      -var="aws_region=${AWS_REGION:-us-east-1}"
      -var="instance_type=${INSTANCE_TYPE:-t2.micro}"
      -var="repository_url=${CI_PROJECT_URL}.git"
  only:
    - main
```

### Best Practices for CI/CD

1. **Never hardcode secrets**: Always use CI/CD secrets/credentials
2. **Use auto-approval carefully**: Require approval for production
3. **Plan before apply**: Always run plan and review before apply
4. **Lock versions**: Use `.terraform.lock.hcl` for provider consistency
5. **Artifact preservation**: Archive state files and outputs
6. **Separate environments**: Use different `tfvars` files per environment
7. **Restrict SSH**: Set `ssh_allowed_cidr` for production
8. **Monitor costs**: Set up AWS budget alerts

### Troubleshooting CI/CD

**Credentials not found:**
```bash
# Verify environment variables
env | grep AWS_
env | grep TF_VAR_
```

**State conflicts:**
```bash
# Run refresh before apply
terraform refresh
terraform apply -auto-approve
```

**Provider version mismatch:**
```bash
# Use .terraform.lock.hcl
git commit .terraform.lock.hcl
```

## Troubleshooting

### Application not loading after 3+ minutes

**Check 1**: Verify EC2 instance is running
```bash
terraform state show aws_instance.app
# Check for "running" in instance_state
```

**Check 2**: Connect via SSH and inspect logs
```bash
ssh -i <your-key> ec2-user@<public-ip>
sudo docker logs simple-static-site
```

**Check 3**: Check Docker is running
```bash
ssh -i <your-key> ec2-user@<public-ip>
sudo docker ps -a
```

**Check 4**: View user data script output
```bash
ssh -i <your-key> ec2-user@<public-ip>
tail -f /var/log/user-data.log
```

### Cannot connect via SSH

- Verify security group has SSH rule (port 22) enabled
- Verify SSH allowed CIDR includes your IP: `ssh_allowed_cidr`
- Check you're using the correct EC2 key pair (if using SSH keys)

### Terraform state issues

If Terraform loses track of resources:
```bash
terraform refresh
terraform state list
terraform state show <resource-name>
```

## Cleanup

To destroy all resources and avoid ongoing costs:

```bash
terraform destroy
```

Type `yes` when prompted. This will:
- Terminate the EC2 instance
- Delete the security group
- Release the public IP
- Remove local state file

**Warning**: This is irreversible. Make sure you want to delete everything.

## Managing Updates

### Updating the Application Code

There are several approaches:

**Option A: Manual SSH** (simple for occasional updates)
```bash
ssh -i <your-key> ec2-user@<public-ip>
cd /opt/app
git pull
docker build -t simple-static-site:latest .
docker stop simple-static-site
docker rm simple-static-site
docker run -d --name simple-static-site --restart always -p 80:80 simple-static-site:latest
```

**Option B: CI/CD Pipeline** (recommended for frequent updates)
- Use GitHub Actions or CodePipeline
- Trigger container rebuild on push
- Auto-deploy to EC2

**Option C: Re-apply Terraform** (updates infrastructure + code)
```bash
terraform apply
```

## Cost Estimation

- **t2.micro instance**: ~$0-$9/month within AWS free tier (12 months)
- **After free tier**: ~$10-15/month
- **Data transfer**: Minimal costs for typical usage

## Security Considerations

1. **SSH Access**: Restrict `ssh_allowed_cidr` to your IP in production
2. **Secrets Management**: For private repos, use AWS Secrets Manager
3. **SSL/TLS**: Current setup uses HTTP. For HTTPS, add:
   - Application Load Balancer (ALB)
   - AWS Certificate Manager (ACM) certificate
   - DNS record pointing to ALB

4. **Monitoring**: Consider adding:
   - CloudWatch alarms for instance health
   - CloudWatch logs for Docker container output
   - AWS Systems Manager for instance management

5. **Backups**: Current setup has no data persistence. For stateful apps:
   - Add EBS volume snapshots
   - Configure automated backups
   - Consider multi-AZ deployment for HA

## Next Steps

1. ✅ Customize `terraform.tfvars`
2. ✅ Run `terraform init`
3. ✅ Run `terraform plan`
4. ✅ Run `terraform apply`
5. ✅ Wait 2-3 minutes
6. ✅ Access application
7. ⏳ Set up monitoring/updates (optional)
8. ⏳ Implement CI/CD for auto-deployment (optional)

## Support

For issues or questions:
1. Check the troubleshooting section
2. Review AWS CloudWatch logs
3. Inspect Docker container logs via SSH
4. Check Terraform documentation: https://www.terraform.io/docs
5. Check AWS documentation: https://docs.aws.amazon.com
