#!/bin/bash
# Check and delete Workload Identity Pools

set -e

PROJECT="karafra-net"
LOCATION="global"

echo "=== Checking Workload Identity Pools in project: ${PROJECT} ==="
echo ""

# List all workload identity pools
echo "Listing all Workload Identity Pools:"
gcloud iam workload-identity-pools list \
  --project="${PROJECT}" \
  --location="${LOCATION}" \
  --format="table(name,displayName,state)"

echo ""
echo "=== To delete a specific pool, use: ==="
echo ""
echo "# Delete pool named 'k3s-admin':"
echo "gcloud iam workload-identity-pools delete k3s-admin \\"
echo "  --project=${PROJECT} \\"
echo "  --location=${LOCATION}"
echo ""

echo "# Delete pool named 'k3s-onprem':"
echo "gcloud iam workload-identity-pools delete k3s-onprem \\"
echo "  --project=${PROJECT} \\"
echo "  --location=${LOCATION}"
echo ""

echo "=== To delete a provider within a pool: ==="
echo ""
echo "# List providers in a pool:"
echo "gcloud iam workload-identity-pools providers list \\"
echo "  --project=${PROJECT} \\"
echo "  --location=${LOCATION} \\"
echo "  --workload-identity-pool=k3s-admin"
echo ""

echo "# Delete a specific provider:"
echo "gcloud iam workload-identity-pools providers delete oidc-provider \\"
echo "  --project=${PROJECT} \\"
echo "  --location=${LOCATION} \\"
echo "  --workload-identity-pool=k3s-admin"
echo ""

