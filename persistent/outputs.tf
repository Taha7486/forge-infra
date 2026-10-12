output "ci_role_arn" {
  description = "Role the GitHub workflow assumes (set as a repository variable, not a secret)."
  value       = aws_iam_role.ci.arn
}

output "ecr_repository_urls" {
  description = "Push targets, keyed by repository name."
  value       = { for name, repo in aws_ecr_repository.this : name => repo.repository_url }
}

output "ecr_repository_arns" {
  description = "Repository ARNs, for the read-only pull roles in the ephemeral stack."
  value       = [for repo in aws_ecr_repository.this : repo.arn]
}
