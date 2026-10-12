resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.cluster_name}-nodes"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = aws_subnet.public[*].id

  capacity_type  = "ON_DEMAND"
  instance_types = var.node_instance_types
  ami_type       = "AL2023_x86_64_STANDARD"

  scaling_config {
    min_size     = var.node_count
    desired_size = var.node_count
    max_size     = var.node_count
  }

  # The node role's policies must exist before the nodes start and outlive them,
  # or EKS cannot clean up the instances and network interfaces on destroy.
  depends_on = [aws_iam_role_policy_attachment.node]
}
