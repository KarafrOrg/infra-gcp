# Quick Fix for Workload Identity Authentication Error

## TL;DR - Run This Command

```bash
./scripts/fix-workload-identity.sh
```

Or manually run:

```bash
gcloud iam workload-identity-pools providers update-oidc terraform-cloud \
  --project="karafra-net" \
  --location="global" \
  --workload-identity-pool="terraform-cloud" \
  --attribute-mapping="google.subject=assertion.sub,attribute.terraform_organization_id=assertion.terraform_organization_id,attribute.terraform_organization_name=assertion.terraform_organization_name,attribute.terraform_workspace_id=assertion.terraform_workspace_id,attribute.terraform_workspace_name=assertion.terraform_workspace_name,attribute.terraform_run_phase=assertion.terraform_run_phase,attribute.terraform_run_id=assertion.terraform_run_id"
```

## What This Fixes

The error `Could not obtain a value for google.subject` occurs because your Workload Identity Pool provider is missing the critical attribute mapping:

```
google.subject=assertion.sub
```

This mapping tells GCP to extract the subject identifier from the `sub` field of the Terraform Cloud JWT token.

## After Running the Fix

1. Wait 10-30 seconds for changes to propagate
2. Re-run your Terraform deployment
3. The authentication should now work

## Additional Configuration (if needed)

If you still get authentication errors after this fix, you may also need to add the IAM binding:

```bash
# Replace YOUR_ORG_NAME with your actual Terraform Cloud organization name
gcloud iam service-accounts add-iam-policy-binding \
  terraform@karafra-net.iam.gserviceaccount.com \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/1019265211616/locations/global/workloadIdentityPools/terraform-cloud/attribute.terraform_organization_name/YOUR_ORG_NAME"
```

Or allow all workspaces:

```bash
gcloud iam service-accounts add-iam-policy-binding \
  terraform@karafra-net.iam.gserviceaccount.com \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/1019265211616/locations/global/workloadIdentityPools/terraform-cloud/*"
```

