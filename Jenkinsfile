// Jenkinsfile

// Define global environment variables for the pipeline
// IMPORTANT: DO NOT hardcode sensitive values here. Use Jenkins Credentials or IRSA.
def AWS_REGION = 'us-east-1' // Example region, change as needed
def TF_STATE_BUCKET = 'n8n-sb1-bucket001' // Replace with your S3 bucket name
def TF_STATE_LOCK_TABLE = 'test-eks-upgrade-lock-table' // Replace with your DynamoDB table name
def EKS_CLUSTER_NAME = 'test-eks-upgrade-cluster' // Name of your EKS cluster
def EKS_KUBERNETES_VERSION = '1.30' // Target EKS Kubernetes version
def EKS_NODE_GROUP_NAME = 'tst-eksupgdclstr-ng' // Name of your node group for the cluster

def EXISTING_VPC_ID = 'vpc-0e3e0e5f71c6d2dfb' // <<-- REPLACE with your existing VPC ID
def EXISTING_PRIVATE_SUBNET_IDS = '["subnet-05c75af00f233a847", "subnet-0ee22c1cfa1d6fbb2", "subnet-01cb3b49d3b0228e2"]' // <<-- REPLACE with your existing private subnet IDs (comma-separated)
def EXISTING_CLUSTER_SECURITY_GROUP_ID = 'sg-01740cdbe884b119c' // <<-- REPLACE with your existing cluster security group ID (if you have one for common access, else omit or let Terraform create)
def ADDITIONAL_CLUSTER_SECURITY_GROUP_IDS = '["sg-012f392beae6823e5"]' // Optional additional security groups for the cluster, can be left empty if not needed

def ADDON_COREDNS_VERSION = 'v1.11.4-eksbuild.2' // Example version for EKS 1.30, check AWS docs for latest
def ADDON_KUBE_PROXY_VERSION = 'v1.30.6-eksbuild.3' // Example, check AWS docs for latest
def ADDON_VPC_CNI_VERSION = 'v1.19.2-eksbuild.1' // Example, check AWS docs for latest
def ADDON_EBS_CSI_DRIVER_VERSION = 'v1.35.0-eksbuild.2' // Example, check AWS docs for latest
def ADDON_EFS_CSI_DRIVER_VERSION = 'v2.1.4-eksbuild.1' // Example, check AWS docs for latest

def NODE_GROUP_LAUNCH_TEMPLATE_ID = 'lt-0700fb456d69d6348' // <<-- REPLACE with your existing Launch Template ID
def NODE_GROUP_LAUNCH_TEMPLATE_VERSION = '2' // <<-- REPLACE with specific version, or '$Latest', '$Default'
def NODE_GROUP_IAM_ROLE_ARN = 'arn:aws:iam::828692096705:role/exl-uc-devops-eks-cluster-ng-role' // <<-- REPLACE with your existing IAM role ARN for the node group


pipeline {
    agent {
        kubernetes {
            cloud 'kubernetes' // Must match the name of your Kubernetes cloud config in Jenkins
            yaml """
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: terraform-runner
spec:
  serviceAccountName: jenkins-irsa-sa
  containers:
    - name: terraform-runner
      image: amazonlinux:2
      command: [ "sh", "-c", "cat" ]
      tty: true
      env:
        - name: AWS_REGION
          value: "us-east-1"
      volumeMounts:
        - name: kubeconfig-volume
          mountPath: /home/jenkins/.kube
  volumes:
    - name: kubeconfig-volume
      emptyDir: {}
            """
        }
    }

    options {
        disableConcurrentBuilds() // Prevent multiple builds from running simultaneously
        timeout(time: 2, unit: 'HOURS') // Global pipeline timeout
    }

    parameters {
        choice(name: 'ACTION', choices: ['install', 'upgrade', 'destroy'], description: 'Select action for EKS cluster')
        string(name: 'CLUSTER_VERSION_TO_UPGRADE_TO', defaultValue: '', description: 'Specify the Kubernetes version to upgrade to (e.g., 1.29, 1.30). Required for "upgrade" action.')
        booleanParam(name: 'CONFIRM_DESTROY', defaultValue: false, description: 'Check this box to confirm cluster destruction. DANGER ZONE!')
        string(name: 'COREDNS_ADDON_VERSION', defaultValue: ADDON_COREDNS_VERSION, description: 'Specific version for CoreDNS addon.')
        string(name: 'KUBE_PROXY_ADDON_VERSION', defaultValue: ADDON_KUBE_PROXY_VERSION, description: 'Specific version for Kube-Proxy addon.')
        string(name: 'VPC_CNI_ADDON_VERSION', defaultValue: ADDON_VPC_CNI_VERSION, description: 'Specific version for VPC CNI addon.')
        string(name: 'EBS_CSI_DRIVER_ADDON_VERSION', defaultValue: ADDON_EBS_CSI_DRIVER_VERSION, description: 'Specific version for EBS CSI Driver addon.')
        string(name: 'EFS_CSI_DRIVER_VERSION', defaultValue: ADDON_EFS_CSI_DRIVER_VERSION, description: 'Specific version for EFS CSI Driver addon.')
        string(name: 'NODE_GROUP_LT_ID', defaultValue: NODE_GROUP_LAUNCH_TEMPLATE_ID, description: 'ID of the existing EC2 Launch Template for the node group.')
        string(name: 'NODE_GROUP_LT_VERSION', defaultValue: NODE_GROUP_LAUNCH_TEMPLATE_VERSION, description: 'Version of the Launch Template ($Latest, $Default, or specific version number).')
    }

    environment {
        // Terraform environment variables to pass to the Terraform run
        TF_VAR_cluster_name = "${EKS_CLUSTER_NAME}"
        TF_VAR_kubernetes_version =  "${EKS_KUBERNETES_VERSION}"
        TF_VAR_node_group_name = "${EKS_NODE_GROUP_NAME}"
        TF_VAR_aws_region = "${AWS_REGION}"
        TF_VAR_existing_vpc_id = "${EXISTING_VPC_ID}"
        TF_VAR_existing_private_subnet_ids = "${EXISTING_PRIVATE_SUBNET_IDS}"
        TF_VAR_existing_cluster_security_group_id = "${EXISTING_CLUSTER_SECURITY_GROUP_ID}"
        TF_VAR_additional_cluster_security_group_ids = "${ADDITIONAL_CLUSTER_SECURITY_GROUP_IDS}"
        TF_VAR_addon_coredns_version = "${params.COREDNS_ADDON_VERSION}"
        TF_VAR_addon_kube_proxy_version = "${params.KUBE_PROXY_ADDON_VERSION}"
        TF_VAR_addon_vpc_cni_version = "${params.VPC_CNI_ADDON_VERSION}"
        TF_VAR_addon_ebs_csi_driver_version = "${params.EBS_CSI_DRIVER_ADDON_VERSION}"
        TF_VAR_addon_efs_csi_driver_version = "${params.EFS_CSI_DRIVER_VERSION}"
        TF_VAR_node_group_launch_template_id = "${params.NODE_GROUP_LT_ID}"
        TF_VAR_node_group_launch_template_version = "${params.NODE_GROUP_LT_VERSION}"
        TF_VAR_node_group_iam_role_arn = "${NODE_GROUP_IAM_ROLE_ARN}"
    }

    stages {
        stage('Install Tools') {
          steps {
            container('velero-runner') {
              sh '''
                echo "Installing AWS CLI, kubectl, velero, jq, gzip, tar, git..."
                yum install -y curl unzip tar gzip jq git

                # AWS CLI
                curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
                unzip awscliv2.zip && ./aws/install && rm -rf awscliv2.zip aws

                # kubectl
                curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
                chmod +x kubectl && mv kubectl /usr/local/bin/

                # terraform
                yum install -y yum-utils shadow-utils
                yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
                yum -y install terraform
              '''
            }
          }
        }
        stage('Checkout Code') {
            steps {
                container('terraform-runner') { // Run this step in the JNLP agent container
                    script {
                        echo "Cloning Terraform repository..."
                        // Replace 'your-git-repo-url' and 'your-branch' with your actual repository
                        // Use a Jenkins credential for Git if your repository is private
                        git branch: 'main', credentialsId: 'PrinceGithub', url: 'https://github.com/PrinceStanley/jenkins-eks-jfrog-terraform.git'
                    }
                }
            }
        }

        stage('Configure Jfrog credentials') {
          steps {
            container('terraform-runner') {
              withCredentials([string(credentialsId: 'PrinceJfrog', variable: 'TOKEN')]) {
                sh """
                    mkdir -p ~/.terraform.d
                   cat <<EOF > ~/.terraform.d/credentials.tfrc.json
{
        "credentials": {
                "trialdckwtg.jfrog.io": {
                        "token": "\${TOKEN}"
                }
        }
}
EOF
                """
              }
            }
          }
        }

        stage('Terraform Init') {
            steps {
                container('terraform-runner') { // Run this step in the Terraform sidecar
                    script {
                        echo "Initializing Terraform..."
                        // IRSA (IAM Roles for Service Accounts) is assumed for AWS authentication.
                        // The 'aws-cli' container runs first in 'Apply' stage to set up kubeconfig,
                        // ensuring Terraform's AWS provider can authenticate correctly if needed for initial calls.
                        // Ensure your Jenkins agent's Service Account has an IAM role attached via IRSA with permissions.
                        sh "terraform init -backend-config=\"bucket=${TF_STATE_BUCKET}\" -backend-config=\"key=eks/${EKS_CLUSTER_NAME}/terraform.tfstate\" -backend-config=\"dynamodb_table=${TF_STATE_LOCK_TABLE}\" -backend-config=\"region=${AWS_REGION}\""
                    }
                }
            }
        }

        stage('Plan') {
            when { expression { "${params.ACTION}" != 'destroy' } } // Don't plan if destroying, destroy command does its own plan
            steps {
                container('terraform-runner') { // Run this step in the Terraform sidecar
                    script {
                        echo "Generating Terraform plan..."
                        sh "terraform plan -out=tfplan"
                    }
                }
            }
        }

        stage('Apply / Upgrade / Destroy') {
            when { expression { "${params.ACTION}" == 'install' } }
            steps {
                script { // Use a script block for conditional logic
                    // Install EKS Cluster
                    input message: "Proceed with EKS cluster installation for '${EKS_CLUSTER_NAME}' (v${EKS_KUBERNETES_VERSION})?", ok: 'Install'
                    container('terraform-runner') {
                        echo "Applying Terraform to install EKS cluster..."
                        sh "terraform apply -auto-approve tfplan"
                    }
                    container('terraform-runner') { // Use awscli-kubectl for AWS CLI commands
                        echo "Updating Kubeconfig for new cluster..."
                        sh "KUBECONFIG=/home/jenkins/.kube/config aws eks update-kubeconfig --region ${AWS_REGION} --name ${EKS_CLUSTER_NAME}"
                    }
                }
            }
        }

        stage('Upgrade EKS Cluster and Addons') {
        // Upgrade EKS Cluster and Addons
        when { expression { params.ACTION == 'upgrade' } }
        steps {
            script {
                if (params.CLUSTER_VERSION_TO_UPGRADE_TO.trim().isEmpty()) {
                    error("CLUSTER_VERSION_TO_UPGRADE_TO parameter is required for 'upgrade' action.")
                }
                input message: "Proceed with EKS cluster upgrade for '${EKS_CLUSTER_NAME}' to v${params.CLUSTER_VERSION_TO_UPGRADE_TO}? This will upgrade both the control plane and node group, and addons.", ok: 'Upgrade'

                container('terraform-runner') {
                    echo "Upgrading EKS Control Plane to Kubernetes v${params.CLUSTER_VERSION_TO_UPGRADE_TO}..."
                    // Pass the upgrade version to Terraform environment variables explicitly
                    sh "export TF_VAR_kubernetes_version=${params.CLUSTER_VERSION_TO_UPGRADE_TO} && terraform apply -auto-approve -target=module.eks"
                }

                container('terraform-runner') {
                    echo "Updating Kubeconfig for new cluster version after control plane upgrade..."
                    sh "KUBECONFIG=/home/jenkins/.kube/config aws eks update-kubeconfig --region ${AWS_REGION} --name ${EKS_CLUSTER_NAME}"
                }

                container('terraform-runner') {
                    echo "Performing Node Group Rolling Update (Blue/Green for 1 node) and upgrading addons..."
                    // Pass the upgrade version for the node group and addons
                    // The 'update_config' in Terraform for the node group ensures new node comes up first.
                    sh "export TF_VAR_kubernetes_version=${params.CLUSTER_VERSION_TO_UPGRADE_TO} && terraform apply -auto-approve"
                    echo "EKS Cluster, Node Group, and Addons upgraded successfully to v${params.CLUSTER_VERSION_TO_UPGRADE_TO}"
                }
            }
        }
        }

        stage('Destroy EKS Cluster') {
            when { expression { params.ACTION == 'destroy' } }
            steps {
                script {
                    if (!params.CONFIRM_DESTROY) {
                        error("Destroy action requires 'CONFIRM_DESTROY' to be checked.")
                    }
                    input message: "ARE YOU ABSOLUTELY SURE YOU WANT TO DESTROY EKS CLUSTER '${EKS_CLUSTER_NAME}'? This is irreversible!", ok: 'Destroy'
                    container('terraform-runner') {
                        echo "Destroying EKS cluster..."
                        sh "terraform destroy -auto-approve"
                    }
                }
            }
        }

        stage('Cleanup (Optional)') {
            steps {
                container('terraform-runner') { // Can run in any container, JNLP is fine for basic file ops
                    echo "Cleaning up workspace..."
                    sh "rm -f tfplan || true" // Remove the Terraform plan file
                }
            }
        }
    }

    post {
        always {
            echo "Pipeline finished for EKS cluster: ${EKS_CLUSTER_NAME} with action: ${params.ACTION}"
        }
        success {
            echo "EKS operation completed successfully! Check AWS Console for confirmation."
        }
        failure {
            echo "EKS operation failed. Review the logs for errors."
            // Optionally, add notifications here (e.g., Slack, Email)
            // mail to: 'devops-team@example.com', subject: "Jenkins Pipeline Failed: EKS ${params.ACTION} for ${EKS_CLUSTER_NAME}", body: "Build URL: ${env.BUILD_URL}"
        }
    }
}
