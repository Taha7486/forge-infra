# forge-infra

Terraform for Forge on AWS (region eu-west-3). Two stacks:

- `persistent/`: lives for the whole project (GitHub OIDC provider, CI role, ECR repositories, Budgets alert).
- `ephemeral/`: built at the start of a session and destroyed at the end (VPC, EKS, nodes, IAM roles for pods).

State is stored in an S3 bucket created by hand; no state or variable values are committed.

## Tools

Pinned binaries in `~/.local/bin`: Terraform v1.16.5, AWS CLI v2.37.12, tflint v0.64.0 (AWS ruleset plugin 0.49.0, see `.tflint.hcl`).

How they were checked (2026-10-11): the Terraform zip against HashiCorp's SHA256 file and GPG signature (key fingerprint `C874 011F 0AB4 0511 0D02 1055 3436 5D94 72D7 468F`); the AWS CLI zip against the signature key fingerprint printed on AWS's install page; tflint's checksums file with cosign keyless against the terraform-linters GitHub identity. `aws configure` has not been run (no account yet).

## Check without an AWS account

```
terraform init -backend=false
terraform validate
tflint --init && tflint
```
