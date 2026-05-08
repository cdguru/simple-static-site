# ============================================================================
# Terraform Configuration for DEPLOYMENT-ONLY Mode
# Target: EXISTING EC2 Instance (no resource creation)
# ============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ============================================================================
# Data Sources: Retrieve information about EXISTING resources
# ============================================================================

# Get the EXISTING EC2 instance by instance ID
data "aws_instance" "target" {
  instance_id = var.instance_id

  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
}

# Get the security group attached to the instance
# Use provided security_group_id if specified, otherwise use the instance's primary security group
data "aws_security_group" "target" {
  id = var.security_group_id != "" ? var.security_group_id : data.aws_instance.target.vpc_security_group_ids[0]
}

# ============================================================================
# Resources: Only modify security group rules (if needed)
# ============================================================================

# Add HTTP access to security group if enabled
resource "aws_security_group_rule" "allow_http" {
  count       = var.enable_http ? 1 : 0
  type        = "ingress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = data.aws_security_group.target.id

  tags = {
    Name = "allow-http-app"
  }
}

# Add HTTPS access to security group if enabled
resource "aws_security_group_rule" "allow_https" {
  count       = var.enable_https ? 1 : 0
  type        = "ingress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = data.aws_security_group.target.id

  tags = {
    Name = "allow-https-app"
  }
}

# ============================================================================
# Locals: Deployment script to run on the instance
# ============================================================================

locals {
  # Use private IP if available, otherwise use public IP
  target_ip = data.aws_instance.target.private_ip != "" ? data.aws_instance.target.private_ip : data.aws_instance.target.public_ip

  # Deployment script to execute on the instance
  deploy_script = <<-EOF
    #!/bin/bash
    set -e

    echo "Starting application deployment..."
    echo "Repository: ${var.repository_url}"
    echo "Time: $(date)"

    # Create application directory
    APP_DIR="/opt/simple-static-site"
    mkdir -p "$APP_DIR"
    cd "$APP_DIR"

    # Clean previous deployment if exists
    if [ -d ".git" ]; then
      echo "Removing previous deployment..."
      rm -rf *
    fi

    # Clone repository
    echo "Cloning repository..."
    git clone ${var.repository_url} .

    # Stop previous container if exists
    echo "Stopping previous container (if exists)..."
    docker stop simple-static-site 2>/dev/null || true
    docker rm simple-static-site 2>/dev/null || true

    # Build Docker image
    echo "Building Docker image..."
    docker build -t simple-static-site:latest .

    # Run Docker container with restart policy
    echo "Starting Docker container..."
    docker run -d \
      --name simple-static-site \
      --restart always \
      -p 80:80 \
      simple-static-site:latest

    # Verify container is running
    sleep 2
    if docker ps | grep -q simple-static-site; then
      echo "✓ Container started successfully"
      docker ps --filter "name=simple-static-site"
    else
      echo "✗ Container failed to start"
      docker logs simple-static-site
      exit 1
    fi

    echo "Deployment completed successfully at $(date)"
  EOF
}

# ============================================================================
# Provisioner: Execute deployment on the EXISTING instance via SSH
# ============================================================================

resource "null_resource" "deploy" {
  triggers = {
    instance_id      = data.aws_instance.target.id
    repository_url   = var.repository_url
    target_ip        = local.target_ip
    instance_user    = var.instance_user
    private_key_path = var.private_key_path
  }

  # Upload deployment script
  provisioner "file" {
    content     = local.deploy_script
    destination = "/tmp/deploy.sh"

    connection {
      type        = "ssh"
      user        = var.instance_user
      private_key = file(var.private_key_path)
      host        = local.target_ip
      timeout     = "5m"
    }
  }

  # Execute deployment script
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/deploy.sh",
      "/tmp/deploy.sh"
    ]

    connection {
      type        = "ssh"
      user        = var.instance_user
      private_key = file(var.private_key_path)
      host        = local.target_ip
      timeout     = "10m"
    }
  }

  # Cleanup script on destroy
  provisioner "remote-exec" {
    when   = destroy
    inline = [
      "echo 'Stopping application container...'",
      "docker stop simple-static-site || true",
      "docker rm simple-static-site || true",
      "echo 'Application container removed. Instance will remain running.'"
    ]

    connection {
      type        = "ssh"
      user        = self.triggers.instance_user
      private_key = file(self.triggers.private_key_path)
      host        = self.triggers.target_ip
      timeout     = "5m"
    }

    on_failure = continue
  }
}
