variable "region" {
  description = "AWS region for every resource in this stack."
  type        = string
  default     = "eu-west-3"
}

variable "github_repository" {
  description = "GitHub repository (owner/name) whose workflows may assume the CI role: the repo that runs the image build."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$", var.github_repository))
    error_message = "Use the form owner/name."
  }
}

variable "github_ref" {
  description = "Git ref allowed to push images. Workflows on other refs (pull requests, other branches) cannot assume the role."
  type        = string
  default     = "refs/heads/main"
}

variable "ecr_prefix" {
  description = "Namespace in front of every repository name. The CI role can push under this prefix only."
  type        = string
  default     = "forge"
}

variable "ecr_repositories" {
  description = "Repository names created under the prefix (forge/<name>)."
  type        = list(string)
  default     = ["podinfo"]
}

variable "budget_limit_usd" {
  description = "Monthly cost budget in USD. Alerts at 50% and 100% of actual spend."
  type        = number
  default     = 10
}

variable "budget_alert_email" {
  description = "Address that receives Budgets alerts. Set it in a git-ignored tfvars file, never in the repo."
  type        = string
}
