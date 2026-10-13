locals {
  # The parameter itself is made by hand (no secret in Terraform). Its ARN has no
  # slash after "parameter" when the name starts with one.
  demo_parameter_arn = "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/${trimprefix(var.demo_parameter_name, "/")}"
}

# The identity demo (plan 1.7): one pod reads one Parameter Store secret.
# Only that service account (identity-demo/secret-reader) can wear this role.
data "aws_iam_policy_document" "demo_trust" {
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
      values   = ["system:serviceaccount:identity-demo:secret-reader"]
    }
  }
}

resource "aws_iam_role" "demo" {
  name               = "${var.cluster_name}-identity-demo"
  assume_role_policy = data.aws_iam_policy_document.demo_trust.json
}

data "aws_iam_policy_document" "demo_read_secret" {
  # Exactly one parameter. A second parameter is refused, which is the scope proof.
  statement {
    sid       = "ReadOneParameter"
    actions   = ["ssm:GetParameters"]
    resources = [local.demo_parameter_arn]
  }

  # A SecureString is encrypted with the AWS-managed key aws/ssm. No policy can be
  # attached to that key, so the permission lives here. The key is created on first
  # use, so its ARN is not known yet: any key in this account and region, but only
  # when the decrypt is for our one parameter. UNVERIFIED until the first AWS test.
  statement {
    sid       = "DecryptThatParameter"
    actions   = ["kms:Decrypt"]
    resources = ["arn:aws:kms:${var.region}:${data.aws_caller_identity.current.account_id}:key/*"]

    condition {
      test     = "StringEquals"
      variable = "kms:EncryptionContext:PARAMETER_ARN"
      values   = [local.demo_parameter_arn]
    }
  }
}

resource "aws_iam_role_policy" "demo_read_secret" {
  name   = "read-one-parameter"
  role   = aws_iam_role.demo.id
  policy = data.aws_iam_policy_document.demo_read_secret.json
}
