// Jenkinsfile for deploying to existing servers via Terraform and SSH
// NO AWS credentials needed - connects directly to server via SSH

pipeline {
    agent any
    
    // Environment variables for Terraform
    environment {
        // Terraform variables (mapped from job parameters)
        TF_VAR_target_ip = "${params.TARGET_IP ?: ''}"
        TF_VAR_instance_user = "${params.INSTANCE_USER ?: 'ec2-user'}"
        TF_VAR_private_key_path = "${params.PRIVATE_KEY_PATH ?: ''}"
        TF_VAR_repository_url = "${params.REPOSITORY_URL ?: 'https://github.com/cdguru/simple-static-site.git'}"
        TF_VAR_environment = "${params.ENVIRONMENT ?: 'production'}"
    }
    
    // Job parameters for UI configuration
    parameters {
        string(name: 'TARGET_IP', description: 'IP address of the target server (public or private IP)')
        string(name: 'INSTANCE_USER', defaultValue: 'ec2-user', description: 'SSH user (ec2-user, ubuntu, admin, root, etc.)')
        string(name: 'PRIVATE_KEY_PATH', description: 'Path to SSH private key file (~/.ssh/key.pem)')
        string(name: 'REPOSITORY_URL', defaultValue: 'https://github.com/cdguru/simple-static-site.git', description: 'Git repository URL')
        choice(name: 'ENVIRONMENT', choices: ['development', 'staging', 'production'], description: 'Environment')
        choice(name: 'ACTION', choices: ['plan', 'apply', 'destroy', 'validate'], description: 'Terraform action')
        booleanParam(name: 'AUTO_APPROVE', defaultValue: false, description: 'Skip approval (use with caution)')
    }
    
    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 30, unit: 'MINUTES')
    }
    
    stages {
        stage('Checkout') {
            steps {
                script {
                    echo "Checking out repository..."
                    checkout scm
                }
            }
        }
        
        stage('Validate Parameters') {
            steps {
                script {
                    echo "=== Validating Required Parameters ==="
                    if (!params.TARGET_IP || params.TARGET_IP.isEmpty()) {
                        error("❌ TARGET_IP parameter is required!")
                    }
                    if (!params.PRIVATE_KEY_PATH || params.PRIVATE_KEY_PATH.isEmpty()) {
                        error("❌ PRIVATE_KEY_PATH parameter is required!")
                    }
                    echo "✅ TARGET_IP: ${params.TARGET_IP}"
                    echo "✅ INSTANCE_USER: ${params.INSTANCE_USER}"
                    echo "✅ PRIVATE_KEY_PATH: ${params.PRIVATE_KEY_PATH}"
                    echo "✅ REPOSITORY_URL: ${params.REPOSITORY_URL}"
                    echo "✅ ENVIRONMENT: ${params.ENVIRONMENT}"
                    echo "✅ ACTION: ${params.ACTION}"
                }
            }
        }
        
        stage('Validate') {
            steps {
                script {
                    echo "=== Validating Terraform Configuration ==="
                    dir('terraform') {
                        sh '''
                            terraform init -backend=false
                            terraform validate
                        '''
                    }
                }
            }
        }
        
        stage('Plan') {
            when {
                expression { params.ACTION in ['plan', 'apply'] }
            }
            steps {
                script {
                    echo "=== Generating Terraform Plan ==="
                    dir('terraform') {
                        sh '''
                            echo "Environment Variables:"
                            echo "TF_VAR_target_ip=${TF_VAR_target_ip}"
                            echo "TF_VAR_instance_user=${TF_VAR_instance_user}"
                            echo "TF_VAR_repository_url=${TF_VAR_repository_url}"
                            echo "TF_VAR_environment=${TF_VAR_environment}"
                            
                            terraform init
                            terraform plan -out=tfplan
                        '''
                    }
                }
            }
        }
        
        stage('Approval') {
            when {
                expression { params.ACTION == 'apply' && !params.AUTO_APPROVE }
            }
            steps {
                script {
                    echo "=== Awaiting Approval for Deployment ==="
                    input message: 'Deploy to target server?', ok: 'Deploy'
                }
            }
        }
        
        stage('Execute') {
            when {
                expression { params.ACTION in ['apply', 'destroy', 'validate'] }
            }
            steps {
                script {
                    dir('terraform') {
                        if (params.ACTION == 'apply') {
                            echo "=== Deploying to Target Server ==="
                            sh 'terraform apply -auto-approve tfplan'
                        } else if (params.ACTION == 'destroy') {
                            echo "=== WARNING: Stopping Deployment on Target Server ==="
                            input message: 'Confirm destroy?', ok: 'Destroy'
                            sh 'terraform destroy -auto-approve'
                        } else if (params.ACTION == 'validate') {
                            echo "=== Validation Complete ==="
                        }
                    }
                }
            }
        }
        
        stage('Output') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                script {
                    echo "=== Deployment Information ==="
                    dir('terraform') {
                        sh 'terraform output'
                    }
                }
            }
        }
    }
    
    post {
        always {
            script {
                echo "Pipeline execution completed"
            }
        }
        success {
            echo "✅ Pipeline completed successfully"
        }
        failure {
            echo "❌ Pipeline failed"
        }
    }
}
