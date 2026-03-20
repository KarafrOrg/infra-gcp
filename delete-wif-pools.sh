#!/bin/bash
# Delete Workload Identity Pools and Providers

set -e

PROJECT="karafra-net"
LOCATION="global"

echo "=== Deleting Workload Identity Pools ==="
echo ""

# Function to delete a pool with all its providers
delete_pool() {
  local pool_id=$1
  echo "Processing pool: ${pool_id}"

  # First, try to list and delete all providers in the pool
  echo "  Checking for providers in pool ${pool_id}..."
  providers=$(gcloud iam workload-identity-pools providers list \
    --project="${PROJECT}" \
    --location="${LOCATION}" \
    --workload-identity-pool="${pool_id}" \
    --format="value(name.basename())" 2>/dev/null || true)

  if [ -n "$providers" ]; then
    echo "  Found providers in pool ${pool_id}:"
    for provider in $providers; do
      echo "    Deleting provider: ${provider}"
      gcloud iam workload-identity-pools providers delete "${provider}" \
        --project="${PROJECT}" \
        --location="${LOCATION}" \
        --workload-identity-pool="${pool_id}" \
        --quiet 2>/dev/null || echo "    Failed to delete provider ${provider} (may not exist)"
    done
  else
    echo "  No providers found in pool ${pool_id}"
  fi

  # Now delete the pool itself
  echo "  Deleting pool: ${pool_id}"
  gcloud iam workload-identity-pools delete "${pool_id}" \
    --project="${PROJECT}" \
    --location="${LOCATION}" \
    --quiet 2>/dev/null || echo "  Failed to delete pool ${pool_id} (may not exist)"

  echo "  Done with pool: ${pool_id}"
  echo ""
}

# Delete specific pools
echo "This will delete the following pools if they exist:"
echo "  - k3s-admin"
echo "  - k3s-onprem"
echo "  - terraform-cloud (if exists)"
echo ""

read -p "Are you sure you want to continue? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
  echo "Aborted."
  exit 0
fi

echo ""
delete_pool "k3s-admin"
delete_pool "k3s-onprem"
# Uncomment if you also want to delete terraform-cloud pool
# delete_pool "terraform-cloud"

echo "=== Deletion complete ==="
echo ""
echo "To verify, run:"
echo "gcloud iam workload-identity-pools list --project=${PROJECT} --location=${LOCATION}"

