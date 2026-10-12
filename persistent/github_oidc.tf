data "aws_caller_identity" "current" {}

# GitHub Actions swaps its OIDC token for temporary credentials of the CI role.
# No AWS key is stored anywhere.
resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

data "aws_iam_policy_document" "ci_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repository}:ref:${var.github_ref}"]
    }
  }
}

resource "aws_iam_role" "ci" {
  name               = "forge-ci-ecr-push"
  assume_role_policy = data.aws_iam_policy_document.ci_trust.json
}

data "aws_iam_policy_document" "ci_ecr_push" {
  # The login token is account-wide by design; it grants nothing by itself.
  statement {
    sid       = "EcrLogin"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  # Push and read-back, on the forge/ prefix only. A push anywhere else is refused.
  statement {
    sid = "PushUnderPrefix"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
    ]
    resources = [
      "arn:aws:ecr:${var.region}:${data.aws_caller_identity.current.account_id}:repository/${var.ecr_prefix}/*",
    ]
  }
}

resource "aws_iam_role_policy" "ci_ecr_push" {
  name   = "ecr-push-forge-prefix"
  role   = aws_iam_role.ci.id
  policy = data.aws_iam_policy_document.ci_ecr_push.json
}
