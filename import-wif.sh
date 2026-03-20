#!/bin/bash
# Import existing Workload Identity Federation resources into Terraform state

set -e

echo "This script will import existing Workload Identity Pool resources into Terraform state"
echo ""

# Configuration
PROJECT="karafra-net"
POOL_ID="k3s-admin"
PROVIDER_ID="oidc-provider"

echo "Importing Workload Identity Pool: ${POOL_ID}"
terraform import \
  'module.google-workload-identity-federation.google_iam_workload_identity_pool.simple["k3s-admin"]' \
  "projects/${PROJECT}/locations/global/workloadIdentityPools/${POOL_ID}"

echo ""
echo "Importing Workload Identity Pool Provider: ${PROVIDER_ID}"
terraform import \
  'module.google-workload-identity-federation.google_iam_workload_identity_pool_provider.simple["k3s-admin"]' \
  "projects/${PROJECT}/locations/global/workloadIdentityPools/${POOL_ID}/providers/${PROVIDER_ID}"

echo ""
echo "Import complete! You can now run 'terraform plan' to verify."

