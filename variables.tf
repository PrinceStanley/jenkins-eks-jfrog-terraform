// variables.tf

variable "aws_region" {
  description = "AWS region for the EKS cluster"
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
}

variable "node_group_name" {
  description = "Name of the EKS node group"
  type        = string
  default     = "workers"
}

variable "existing_vpc_id" {
  description = "The ID of the existing VPC to deploy the EKS cluster into."
  type        = string
}

variable "existing_private_subnet_ids" {
  description = "Comma-separated string of existing private subnet IDs for the EKS cluster."
  type        = list(string)
  default     = []
}

variable "existing_cluster_security_group_id" {
  description = "Optional: The ID of an existing security group to associate with the cluster control plane ENIs."
  type        = string
  default     = ""
}

variable "additional_cluster_security_group_ids" {
  description = "Comma-separated string of additional security group IDs to attach to the EKS cluster control plane."
  type        = list(string)
  default     = []
}

# --- EKS Managed Addon Version Variables ---
variable "addon_coredns_version" {
  description = "Specific version for the CoreDNS EKS addon. Leave empty for 'most_recent'."
  type        = string
  default     = ""
}

variable "addon_kube_proxy_version" {
  description = "Specific version for the Kube-Proxy EKS addon. Leave empty for 'most_recent'."
  type        = string
  default     = ""
}

variable "addon_vpc_cni_version" {
  description = "Specific version for the VPC CNI EKS addon. Leave empty for 'most_recent'."
  type        = string
  default     = ""
}

variable "addon_ebs_csi_driver_version" {
  description = "Specific version for the EBS CSI Driver EKS addon. Leave empty for 'most_recent'."
  type        = string
  default     = ""
}

variable "addon_efs_csi_driver_version" {
  description = "Specific version for the EFS CSI Driver. Leave empty for 'most_recent'."
  default     = ""
  type        = string
}

variable "node_group_launch_template_id" {
  description = "The ID of the existing EC2 Launch Template to use for the EKS managed node group."
  type        = string
}

variable "node_group_launch_template_version" {
  description = "The version of the Launch Template to use. Can be '$Latest', '$Default', or a specific version number."
  type        = string
  default     = "1"
}

variable "node_group_iam_role_arn" {
  description = "The ARN of the IAM role to use for the EKS managed node group."
  type        = string  
  default     = "" 
}
