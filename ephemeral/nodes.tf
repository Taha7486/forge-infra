# Only the instance metadata options live here. The AMI type, instance types, subnets and
# node role stay on the node group: EKS rejects a setting given in both places.
resource "aws_launch_template" "nodes" {
  name = "${var.cluster_name}-nodes"

  # IMDSv2 only. The hop limit decides whether pods can reach the node role through the
  # metadata service: 1 stops them (host-network pods such as aws-node should be
  # unaffected, and IRSA pods do not use it; both to be seen on the first apply), 2 lets
  # them. 2 is also what EKS sets for a managed node group with a custom launch template,
  # so it is the same as not setting it.
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = var.node_metadata_hop_limit
  }
}

resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.cluster_name}-nodes"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = aws_subnet.public[*].id

  capacity_type  = "ON_DEMAND"
  instance_types = var.node_instance_types
  ami_type       = "AL2023_x86_64_STANDARD"

  launch_template {
    id      = aws_launch_template.nodes.id
    version = aws_launch_template.nodes.latest_version
  }

  scaling_config {
    min_size     = var.node_count
    desired_size = var.node_count
    max_size     = var.node_count
  }

  # The node role's policies must exist before the nodes start and outlive them,
  # or EKS cannot clean up the instances and network interfaces on destroy.
  # The VPC CNI add-on goes first so the nodes start with the network policy agent configured.
  depends_on = [
    aws_iam_role_policy_attachment.node,
    aws_eks_addon.vpc_cni,
  ]
}
