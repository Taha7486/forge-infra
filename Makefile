# Session helpers for the ephemeral stack (rules file: rules 24, 25, 28).
#   make check   read-only list of leftovers that still cost money
#   make down    clean the cluster, destroy ephemeral/, then run the check
# Both start with a guard that prints who you are logged in as and stops if not logged in.

REGION := eu-west-3

.PHONY: guard check down

guard:
	@echo "Region: $(REGION)"
	@aws sts get-caller-identity --region $(REGION) --output text --query '[Account,Arn]' \
		|| { echo "Not logged in to AWS: run 'aws login'"; exit 1; }

check: guard
	@REGION=$(REGION) scripts/leftover-check.sh

down: guard
	@REGION=$(REGION) scripts/teardown.sh
	@REGION=$(REGION) scripts/leftover-check.sh
