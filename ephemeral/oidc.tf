# Lets IAM trust the cluster's own token issuer, so a pod's Kubernetes service
# account can be swapped for an IAM role (IRSA). The thumbprint is omitted: IAM
# fetches it itself.
resource "aws_iam_openid_connect_provider" "cluster" {
  url            = aws_eks_cluster.this.identity[0].oidc[0].issuer
  client_id_list = ["sts.amazonaws.com"]
}
