// main.tf

provider "aws" {
  region = var.aws_region
}

//provider "kubernetes" {
//  host                   = data.aws_eks_cluster.this.endpoint
//  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
//  token                  = data.aws_eks_cluster_auth.this.token
//}

terraform {
  backend "s3" {
    bucket         = "n8n-sb1-bucket001"
    key            = "eks/test-eks-upgrade-cluster/terraform.tfstate"
    dynamodb_table = "test-eks-upgrade-lock-table"
    region         = "us-east-1"
    encrypt        = true
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.30"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }
}

// Data sources to get existing VPC, subnets, etc.
data "aws_vpc" "selected" {
  id = var.existing_vpc_id
}

//data "aws_subnets" "private_subnets" {
//  ids = split(",", var.existing_private_subnet_ids)
//}

//data "aws_security_group" "cluster_sg" {
//  count = var.existing_cluster_security_group_id != "" ? 1 : 0
//  id    = var.existing_cluster_security_group_id
//}

// EKS Cluster Module
module "eks" {
  source  = "trialdckwtg.jfrog.io/terraform-module__jfrog/terraform-aws-eks/aws"
  version = "20.36.0" # Make sure to check the latest version supporting EKS 1.30 (might be v20+)

  cluster_name    = var.cluster_name
  cluster_version = var.kubernetes_version

  vpc_id     = data.aws_vpc.selected.id
  subnet_ids = var.existing_private_subnet_ids

  cluster_security_group_id = var.existing_cluster_security_group_id
  cluster_additional_security_group_ids = var.additional_cluster_security_group_ids

  cluster_endpoint_private_access = true

  # EKS Managed Node Group
  eks_managed_node_groups = {
    "${var.node_group_name}" = {
      name = var.node_group_name
      
      create_iam_role = false
      iam_role_arn = var.node_group_iam_role_arn
      desired_size = 1
      max_size     = 2
      min_size     = 1
      
      create_launch_template = false
      use_custom_launch_template = true  
      launch_template_id      = var.node_group_launch_template_id
      launch_template_version   = var.node_group_launch_template_version

      update_config = {
        max_unavailable_percentage = 1
        max_surge_percentage       = 100
      }
    }
  }

  # EKS Addons (managed by the EKS module) - now with specific versions
  cluster_addons = {
    coredns = {
      resolve_conflicts = "OVERWRITE"
      addon_version = var.addon_coredns_version
      most_recent = var.addon_coredns_version == "" ? true : null
    }
    kube-proxy = {
      resolve_conflicts = "OVERWRITE"
      addon_version = var.addon_kube_proxy_version
      most_recent = var.addon_kube_proxy_version == "" ? true : null
    }
    vpc-cni = {
      resolve_conflicts = "OVERWRITE"
      addon_version = var.addon_vpc_cni_version
      most_recent = var.addon_vpc_cni_version == "" ? true : null
    }
    # EBS CSI Driver is now an EKS managed addon
    aws-ebs-csi-driver = {
      resolve_conflicts = "OVERWRITE"
      addon_version = var.addon_ebs_csi_driver_version
      most_recent = var.addon_ebs_csi_driver_version == "" ? true : null
    }
    aws-efs-csi-driver = {
      resolve_conflicts = "OVERWRITE"
      addon_version = var.addon_efs_csi_driver_version
      most_recent = var.addon_efs_csi_driver_version == "" ? true : null
    }
  }
}

// Data sources to get cluster endpoint and auth token for Kubernetes provider
//data "aws_eks_cluster" "this" {
//  name = module.eks.cluster_name
//}

//data "aws_eks_cluster_auth" "this" {
//  name = module.eks.cluster_name
//}
