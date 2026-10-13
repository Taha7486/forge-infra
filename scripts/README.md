# Session helpers

Used every session that spins up AWS. The `Makefile` is in the repo root; run `make` from there.

The goal: nothing keeps billing after a session (rules file, rules 24, 25 and 28).

## What each piece does

| Piece | What it does | Changes anything? |
| --- | --- | --- |
| `make guard` | Prints the region and the account and user you are logged in as. Stops with "run `aws login`" if you are not. Runs first inside `check` and `down`. | No |
| `make check` | Runs `scripts/leftover-check.sh`. | No (read-only) |
| `make down` | Runs `scripts/teardown.sh`, then the leftover check. | Yes: destroys the ephemeral stack |
| `scripts/leftover-check.sh` | Lists things that cost money and should not exist: EKS clusters, EC2 instances, unattached EBS volumes, Elastic IPs, NAT gateways, load balancers (both kinds), network interfaces. Region eu-west-3. | No (read-only) |
| `scripts/teardown.sh` | Will clean the cluster, then run `terraform destroy` on `ephemeral/` only. **Not written yet: it is a placeholder that refuses to run.** | Not yet |

## Reading the check result

- `ok`: nothing found for that item.
- `FOUND`: something exists. Nothing is deleted for you; look at it and decide.
- `ERROR`: that command failed (not logged in, no permission). The check is then incomplete and exits with code 2. Never read it as clean.
- Exit codes: 0 clean, 1 leftovers found, 2 check incomplete.

The check lists everything in the region, not only Forge's resources, so not every item it shows is a leftover of ours.

## Session routine

1. `aws login` if the session has expired (it lasts up to 12 hours).
2. Check the credit balance on the Billing console Credits page. Stop if it is under $25 (rule 22).
3. `make check` from the repo root. It should be clean before you build anything.
4. Build: `cd ephemeral && terraform apply`, then `aws eks update-kubeconfig --region eu-west-3 --name forge`. There is no `make up` yet; this step is by hand.
5. Do the work. Write down the cluster-hours used (rule 23).
6. Delete the ArgoCD apps, then `make down` from the repo root. Terraform asks for a yes before it destroys.
7. `make down` ends with the leftover check. If it is not clean, deal with each item before you stop (rule 24).

Never leave the cluster running overnight (rule 25). `persistent/` is never destroyed by these helpers.

## Status

Untested against a real AWS account. What was tested without one: syntax, `make -n`, and the no-login behaviour (the guard stops `make down`; the check exits 2 with errors instead of looking clean). Still unproven: how each AWS command prints an empty result.
