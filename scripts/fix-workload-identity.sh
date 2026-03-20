#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PROJECT_ID="karafra-net"
PROJECT_NUMBER="1019265211616"
POOL_ID="terraform-cloud"
PROVIDER_ID="terraform-cloud"
SERVICE_ACCOUNT="terraform@karafra-net.iam.gserviceaccount.com"

echo -e "${YELLOW}=====================================${NC}"
echo -e "${YELLOW}Fixing Workload Identity Pool Configuration${NC}"
echo -e "${YELLOW}=====================================${NC}"
echo ""

# Step 1: Update the workload identity pool provider with correct attribute mappings
echo -e "${GREEN}Step 1: Updating workload identity pool provider attribute mappings...${NC}"
gcloud iam workload-identity-pools providers update-oidc "${PROVIDER_ID}" \
  --project="${PROJECT_ID}" \
  --location="global" \
  --workload-identity-pool="${POOL_ID}" \
  --attribute-mapping="google.subject=assertion.sub,attribute.terraform_organization_id=assertion.terraform_organization_id,attribute.terraform_organization_name=assertion.terraform_organization_name,attribute.terraform_workspace_id=assertion.terraform_workspace_id,attribute.terraform_workspace_name=assertion.terraform_workspace_name,attribute.terraform_run_phase=assertion.terraform_run_phase,attribute.terraform_run_id=assertion.terraform_run_id"

echo -e "${GREEN}✓ Attribute mappings updated successfully${NC}"
echo ""

# Step 2: Verify the configuration
echo -e "${GREEN}Step 2: Verifying workload identity pool provider configuration...${NC}"
gcloud iam workload-identity-pools providers describe "${PROVIDER_ID}" \
  --project="${PROJECT_ID}" \
  --location="global" \
  --workload-identity-pool="${POOL_ID}" \
  --format="yaml(attributeMapping)"

echo ""

# Step 3: Update service account IAM binding
echo -e "${GREEN}Step 3: Updating service account IAM binding...${NC}"
echo -e "${YELLOW}Note: You may need to adjust the principal filter based on your needs${NC}"
echo ""

# Option A: Allow any workspace in your Terraform Cloud organization
# Uncomment this if you want to allow all workspaces
# echo "Adding binding for all workspaces in organization..."
# gcloud iam service-accounts add-iam-policy-binding \
#   "${SERVICE_ACCOUNT}" \
#   --role="roles/iam.workloadIdentityUser" \
#   --member="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_ID}/*"

# Option B: Allow specific Terraform Cloud organization
echo "Adding binding for specific organization..."
read -p "Enter your Terraform Cloud organization name: " ORG_NAME
gcloud iam service-accounts add-iam-policy-binding \
  "${SERVICE_ACCOUNT}" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_ID}/attribute.terraform_organization_name/${ORG_NAME}"

echo ""
echo -e "${GREEN}✓ Service account IAM binding updated${NC}"
echo ""

# Step 4: Verify service account IAM policy
echo -e "${GREEN}Step 4: Verifying service account IAM policy...${NC}"
gcloud iam service-accounts get-iam-policy "${SERVICE_ACCOUNT}" \
  --format="yaml(bindings)"

echo ""
echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}✓ Configuration complete!${NC}"
echo -e "${GREEN}=====================================${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Wait a few moments for the changes to propagate"
echo "2. Re-run your Terraform deployment"
echo ""

