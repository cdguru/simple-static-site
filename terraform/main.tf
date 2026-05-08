# ============================================================================
# Terraform Configuration for DEPLOYMENT-ONLY Mode
# Target: EXISTING Server via SSH (no AWS resources needed)
# ============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

# ============================================================================
# Locals: Deployment script to run on the instance
# ============================================================================

locals {
  # Target IP is provided directly by the user
  target_ip = var.target_ip

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
    target_ip        = var.target_ip
    repository_url   = var.repository_url
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
