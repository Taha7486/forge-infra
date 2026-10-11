# forge-infra

Terraform for Forge on AWS (region eu-west-3). Two stacks:

- `persistent/`: lives for the whole project (GitHub OIDC provider, CI role, ECR repositories, Budgets alert).
- `ephemeral/`: built at the start of a session and destroyed at the end (VPC, EKS, nodes, IAM roles for pods).

State is stored in an S3 bucket created by hand; no state or variable values are committed.

## Tools

Pinned binaries in `~/.local/bin`: Terraform v1.16.5, tflint v0.64.0 (AWS ruleset plugin 0.49.0, see `.tflint.hcl`).

## Check without an AWS account

```
terraform init -backend=false
terraform validate
tflint --init && tflint
```
