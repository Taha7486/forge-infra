#!/usr/bin/env bash
# Read-only. Lists AWS resources that cost money and should not exist after a teardown.
# Exit 0: nothing found. Exit 1: something found. Exit 2: a check could not run
# (a failed check is never reported as clean).
set -uo pipefail

REGION="${REGION:-eu-west-3}"
found=0
failed=0

# check LABEL AWS-COMMAND...   (the region and text output are added here)
check() {
  local label=$1
  shift
  local out
  if ! out=$("$@" --region "$REGION" --output text 2>&1); then
    echo "ERROR  $label: $out"
    failed=1
    return
  fi
  if [ -z "$out" ] || [ "$out" = "None" ]; then
    echo "ok     $label"
  else
    echo "FOUND  $label"
    echo "$out" | sed 's/^/         /'
    found=1
  fi
}

check "EKS clusters" \
  aws eks list-clusters --query 'clusters'
check "EC2 instances (pending, running, stopping, stopped)" \
  aws ec2 describe-instances \
  --filters Name=instance-state-name,Values=pending,running,stopping,stopped \
  --query 'Reservations[].Instances[].[InstanceId,InstanceType,State.Name]'
check "EBS volumes not attached to anything" \
  aws ec2 describe-volumes --filters Name=status,Values=available \
  --query 'Volumes[].[VolumeId,Size,CreateTime]'
check "Elastic IPs" \
  aws ec2 describe-addresses --query 'Addresses[].[AllocationId,PublicIp]'
check "NAT gateways (pending, available, deleting)" \
  aws ec2 describe-nat-gateways \
  --filter Name=state,Values=pending,available,deleting \
  --query 'NatGateways[].[NatGatewayId,State]'
check "Load balancers (ALB/NLB)" \
  aws elbv2 describe-load-balancers --query 'LoadBalancers[].[LoadBalancerName,Type]'
check "Load balancers (classic)" \
  aws elb describe-load-balancers --query 'LoadBalancerDescriptions[].LoadBalancerName'
check "Network interfaces" \
  aws ec2 describe-network-interfaces \
  --query 'NetworkInterfaces[].[NetworkInterfaceId,Status,Description]'

if [ "$failed" -ne 0 ]; then
  echo "Check incomplete: at least one command failed. Do not treat this as clean."
  exit 2
fi
if [ "$found" -ne 0 ]; then
  echo "Leftovers found in $REGION. Nothing was deleted; decide what to do with each."
  exit 1
fi
echo "Clean: nothing found in $REGION."
