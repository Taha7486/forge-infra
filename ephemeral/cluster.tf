resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  version  = var.kubernetes_version
  role_arn = aws_iam_role.cluster.arn

  vpc_config {
    subnet_ids = aws_subnet.public[*].id
  }

  # Access is granted through EKS access entries (an AWS API), not the older
  # aws-auth ConfigMap. The identity that creates the cluster becomes its admin.
  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = true
  }

  # No control-plane logs: they go to CloudWatch, which is off (rules file).
  enabled_cluster_log_types = []

  # The role's policy must be attached before the cluster is created, and stay
  # attached until it is deleted.
  depends_on = [aws_iam_role_policy_attachment.cluster]
}
