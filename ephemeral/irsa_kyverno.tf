data "aws_caller_identity" "current" {}

locals {
  # The issuer without "https://": IAM condition keys are written that way.
  oidc_host = replace(aws_iam_openid_connect_provider.cluster.url, "https://", "")
}

# Kyverno's admission controller reads image signatures and attestations from ECR.
# Only that service account (kyverno/kyverno-admission-controller) can wear this role.
data "aws_iam_policy_document" "kyverno_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.cluster.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_host}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_host}:sub"
      values   = ["system:serviceaccount:kyverno:kyverno-admission-controller"]
    }
  }
}

resource "aws_iam_role" "kyverno" {
  name               = "${var.cluster_name}-kyverno-admission"
  assume_role_policy = data.aws_iam_policy_document.kyverno_trust.json
}

data "aws_iam_policy_document" "kyverno_ecr_read" {
  # The login token is account-wide by design; it grants nothing by itself.
  statement {
    sid       = "EcrLogin"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  # Read on the forge/ prefix only. A repository outside it is refused.
  statement {
    sid       = "ReadUnderPrefix"
    actions   = ["ecr:BatchGetImage"]
    resources = ["arn:aws:ecr:${var.region}:${data.aws_caller_identity.current.account_id}:repository/${var.ecr_prefix}/*"]
  }
}

resource "aws_iam_role_policy" "kyverno_ecr_read" {
  name   = "ecr-read-forge-prefix"
  role   = aws_iam_role.kyverno.id
  policy = data.aws_iam_policy_document.kyverno_ecr_read.json
}
