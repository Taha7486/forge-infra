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
