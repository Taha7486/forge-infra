variable "region" {
  description = "AWS region for every resource in this stack."
  type        = string
  default     = "eu-west-3"
}

variable "cluster_name" {
  description = "EKS cluster name. Also used in the subnet tags EKS looks for."
  type        = string
  default     = "forge"
}

variable "vpc_cidr" {
  description = "Address range of the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Two zones, one public subnet each. EKS needs subnets in at least two zones."
  type        = list(string)
  default     = ["eu-west-3a", "eu-west-3b"]

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "EKS needs subnets in at least two availability zones."
  }
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version."
  type        = string
  default     = "1.35"
}

variable "node_instance_types" {
  description = "EC2 instance types for the managed node group (On-Demand)."
  type        = list(string)
  default     = ["m7i-flex.large"]
}

variable "node_count" {
  description = "Number of worker nodes. The group is fixed at this size."
  type        = number
  default     = 2
}

variable "vpc_cni_version" {
  description = "Version of the vpc-cni EKS add-on. v1.23.1-eksbuild.1 is the latest listed for Kubernetes 1.35 in the EKS user guide (checked 2026-10-22); network policy needs v1.14.0-eksbuild.3 or later. If apply rejects it, list the valid versions with aws eks describe-addon-versions --addon-name vpc-cni --kubernetes-version 1.35."
  type        = string
  default     = "v1.23.1-eksbuild.1"
}

variable "node_metadata_hop_limit" {
  description = "Instance metadata hop limit on the nodes. 2 lets pods reach the node role through IMDS (the EKS default for a custom launch template); 1 stops them. Left at 2 until R2 step 3 has shown whether Kyverno can borrow the node role; then set 1 for the next rebuild."
  type        = number
  default     = 2

  validation {
    condition     = contains([1, 2], var.node_metadata_hop_limit)
    error_message = "Use 1 (pods cannot reach IMDS) or 2 (they can)."
  }
}

variable "ecr_prefix" {
  description = "Namespace in front of every ECR repository name (same as the persistent stack). Kyverno can read under this prefix only."
  type        = string
  default     = "forge"
}

variable "demo_parameter_name" {
  description = "Parameter Store name of the identity demo secret (plan 1.7). Made by hand as a SecureString; Terraform only writes the permission to read it."
  type        = string
  default     = "/forge/demo/secret"
}
