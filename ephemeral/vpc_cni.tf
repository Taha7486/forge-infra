# EKS installs the VPC CNI (the pod network, the aws-node DaemonSet) on its own. Managing it
# here lets us switch on its network policy agent: without it a NetworkPolicy object (the
# Juice Shop deny-all-egress one in forge-gitops) is accepted by the API and silently not
# enforced. Default mode on purpose: a new pod starts with allow-all until its policies are
# programmed. Do NOT set NETWORK_POLICY_ENFORCING_MODE=strict: it needs a policy for every
# endpoint, CoreDNS included.
resource "aws_eks_addon" "vpc_cni" {
  cluster_name  = aws_eks_cluster.this.name
  addon_name    = "vpc-cni"
  addon_version = var.vpc_cni_version

  configuration_values = jsonencode({
    enableNetworkPolicy = "true"
  })

  # The self-managed copy EKS installed at cluster creation is taken over, and Terraform
  # stays the source of truth on later updates.
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
}
