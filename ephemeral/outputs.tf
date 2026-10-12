output "cluster_name" {
  description = "For: aws eks update-kubeconfig --region <region> --name <cluster_name>"
  value       = aws_eks_cluster.this.name
}

output "kyverno_role_arn" {
  description = "Annotation value (eks.amazonaws.com/role-arn) for the kyverno-admission-controller service account."
  value       = aws_iam_role.kyverno.arn
}
