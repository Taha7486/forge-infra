# forge-infra

Terraform for Forge on AWS (region eu-west-3). Two stacks:

- `persistent/`: lives for the whole project (GitHub OIDC provider, CI role, ECR repositories, Budgets alert).
- `ephemeral/`: built at the start of a session and destroyed at the end (VPC, EKS, nodes, IAM roles for pods).

State is stored in an S3 bucket created by hand; no state or variable values are committed.

## What is in each stack

Flat resources, no modules; one file per concern.

`persistent/`
- `github_oidc.tf`: GitHub OIDC provider and the CI role `forge-ci-ecr-push` (trusted for one repository and one branch, may push to `forge/*` only).
- `ecr.tf`: repositories under `forge/` with immutable tags and a lifecycle policy.
- `budgets.tf`: monthly cost budget with alerts at 50% and 100% of actual spend.

`ephemeral/`
- `network.tf`: VPC, two public subnets in two zones, internet gateway, route table. No NAT Gateway.
- `iam.tf`: EKS cluster role and node role.
- `cluster.tf`: EKS control plane. The API endpoint is public and open; access needs valid IAM credentials.
- `nodes.tf`: managed node group, On-Demand, fixed size.
- `oidc.tf`: IAM OIDC provider for the cluster, which lets a pod's service account be swapped for an IAM role (IRSA).
- `irsa_kyverno.tf`: role for Kyverno's admission controller, read-only on `forge/*` in ECR.
- `outputs.tf`: cluster name and the Kyverno role ARN.

## Using the stacks

Not yet run against a real account. The state bucket is created by hand first; its name is passed at init because it differs per account.

```
cd persistent
cp terraform.tfvars.example terraform.tfvars   # fill in the two values; the file is git-ignored
terraform init -backend-config="bucket=<state bucket>"
terraform apply

cd ../ephemeral
terraform init -backend-config="bucket=<state bucket>"
terraform apply
aws eks update-kubeconfig --region eu-west-3 --name forge
terraform destroy                              # at the end of the session
```

`persistent/` stays between sessions. `ephemeral/` has no required variables.

## Tools

Pinned binaries in `~/.local/bin`: Terraform v1.16.5, AWS CLI v2.37.12, tflint v0.64.0 (AWS ruleset plugin 0.49.0, see `.tflint.hcl`).

How they were checked (2026-10-11): the Terraform zip against HashiCorp's SHA256 file and GPG signature (key fingerprint `C874 011F 0AB4 0511 0D02 1055 3436 5D94 72D7 468F`); the AWS CLI zip against the signature key fingerprint printed on AWS's install page; tflint's checksums file with cosign keyless against the terraform-linters GitHub identity. `aws configure` has not been run (no account yet).

## Check without an AWS account

```
terraform init -backend=false
terraform validate
tflint --init && tflint
```
