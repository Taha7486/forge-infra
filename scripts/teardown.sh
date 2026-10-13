#!/usr/bin/env bash
# End-of-session teardown for the ephemeral stack (rules file: rules 24 and 28).
#   1. If the cluster exists: stop ArgoCD managing things, then remove what Kubernetes
#      can turn into AWS resources Terraform does not know about (LoadBalancer Services,
#      Ingresses, PVCs). Everything it will delete is listed first and needs a yes.
#   2. terraform destroy on ephemeral/ only (Terraform asks for its own yes).
# The leftover check runs afterwards from the Makefile. persistent/ is never touched.
set -euo pipefail

REGION="${REGION:-eu-west-3}"
CLUSTER_NAME="${CLUSTER_NAME:-forge}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BACKEND="$ROOT/backend.hcl"

if [ ! -f "$BACKEND" ]; then
  echo "Missing $BACKEND (git-ignored). Copy backend.hcl.example to backend.hcl and put the state bucket name in it." >&2
  exit 1
fi

# ---- 1. Is there a cluster? ----
if ! out=$(aws eks describe-cluster --name "$CLUSTER_NAME" --region "$REGION" 2>&1); then
  if grep -q ResourceNotFoundException <<<"$out"; then
    echo "No cluster '$CLUSTER_NAME' in $REGION: skipping the Kubernetes cleanup."
    have_cluster=0
  else
    echo "Could not look up the cluster, stopping: $out" >&2
    exit 1
  fi
else
  have_cluster=1
fi

if [ "$have_cluster" -eq 1 ]; then
  # ---- 2. Pin kubectl to this cluster (every command below passes --context) ----
  account=$(aws sts get-caller-identity --query Account --output text)
  CONTEXT="arn:aws:eks:$REGION:$account:cluster/$CLUSTER_NAME"
  if ! kubectl config get-contexts -o name | grep -qx "$CONTEXT"; then
    echo "Adding kubeconfig context $CONTEXT (aws eks update-kubeconfig)."
    aws eks update-kubeconfig --region "$REGION" --name "$CLUSTER_NAME" >/dev/null
  fi
  k() { kubectl --context "$CONTEXT" --request-timeout=30s "$@"; }

  if ! k get namespaces >/dev/null 2>&1; then
    echo "Cluster '$CLUSTER_NAME' exists but is not reachable with kubectl (context $CONTEXT)." >&2
    echo "Fix access, or stop here and run terraform destroy by hand; nothing was changed." >&2
    exit 1
  fi

  # ---- 3. What would be removed? ----
  apps=""
  if k get crd applications.argoproj.io >/dev/null 2>&1; then
    apps=$(k get applications.argoproj.io -A \
      -o jsonpath='{range .items[*]}{.metadata.namespace}/{.metadata.name}{"\n"}{end}')
  fi
  lbs=$(k get svc -A \
    -o jsonpath='{range .items[?(@.spec.type=="LoadBalancer")]}{.metadata.namespace}/{.metadata.name}{"\n"}{end}')
  ings=$(k get ingress -A \
    -o jsonpath='{range .items[*]}{.metadata.namespace}/{.metadata.name}{"\n"}{end}')
  pvcs=$(k get pvc -A \
    -o jsonpath='{range .items[*]}{.metadata.namespace}/{.metadata.name}{"\n"}{end}')

  if [ -z "$apps$lbs$ings$pvcs" ]; then
    echo "Nothing to clean inside the cluster."
  else
    echo "About to delete in context $CONTEXT:"
    [ -n "$apps" ] && echo "  ArgoCD Applications (non-cascading: only the Application objects):" && sed 's/^/    /' <<<"$apps"
    [ -n "$lbs" ] && echo "  LoadBalancer Services:" && sed 's/^/    /' <<<"$lbs"
    [ -n "$ings" ] && echo "  Ingresses:" && sed 's/^/    /' <<<"$ings"
    [ -n "$pvcs" ] && echo "  PersistentVolumeClaims:" && sed 's/^/    /' <<<"$pvcs"
    read -r -p "Type yes to delete these: " answer || answer=""
    if [ "$answer" != "yes" ]; then
      echo "Not confirmed: stopping. Nothing was changed."
      exit 1
    fi

    # ArgoCD first, so it cannot recreate what is removed next. Non-cascading, as in
    # the ArgoCD docs: clear the finalizer, then delete the Application.
    while IFS=/ read -r ns name; do
      [ -z "$name" ] && continue
      k -n "$ns" patch applications.argoproj.io "$name" --type merge \
        -p '{"metadata":{"finalizers":null}}' | cat
      k -n "$ns" delete applications.argoproj.io "$name" --wait=true --timeout=120s | cat
    done <<<"$apps"

    # Services wait for their AWS load balancer to be gone before they disappear.
    while IFS=/ read -r ns name; do
      [ -z "$name" ] && continue
      k -n "$ns" delete svc "$name" --wait=true --timeout=300s | cat
    done <<<"$lbs"
    while IFS=/ read -r ns name; do
      [ -z "$name" ] && continue
      k -n "$ns" delete ingress "$name" --wait=true --timeout=300s | cat
    done <<<"$ings"
    while IFS=/ read -r ns name; do
      [ -z "$name" ] && continue
      k -n "$ns" delete pvc "$name" --wait=true --timeout=300s | cat
    done <<<"$pvcs"
  fi
fi

# ---- 4. Destroy the ephemeral stack (Terraform asks for its own yes) ----
terraform -chdir="$ROOT/ephemeral" init -input=false -backend-config="$BACKEND"
terraform -chdir="$ROOT/ephemeral" destroy
echo "terraform destroy finished."
