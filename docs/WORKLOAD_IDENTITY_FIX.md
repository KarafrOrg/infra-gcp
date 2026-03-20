# Fixing Workload Identity Authentication Error

## The Problem
Error: `Could not obtain a value for google.subject from the given credential`

This error occurs because your GCP Workload Identity Pool provider doesn't have the correct attribute mappings to extract the `google.subject` claim from the Terraform Cloud JWT token.

## Solution

You need to update your Workload Identity Pool provider with the correct attribute mappings. Run this command:

```bash
gcloud iam workload-identity-pools providers update-oidc terraform-cloud \
  --project="karafra-net" \
  --location="global" \
  --workload-identity-pool="terraform-cloud" \
  --attribute-mapping="google.subject=assertion.sub,attribute.terraform_organization_id=assertion.terraform_organization_id,attribute.terraform_organization_name=assertion.terraform_organization_name,attribute.terraform_workspace_id=assertion.terraform_workspace_id,attribute.terraform_workspace_name=assertion.terraform_workspace_name,attribute.terraform_run_phase=assertion.terraform_run_phase,attribute.terraform_run_id=assertion.terraform_run_id"
```

## Explanation

The attribute mapping tells GCP how to map JWT token claims to GCP attributes:
- `google.subject=assertion.sub` - **CRITICAL**: Maps the JWT's `sub` claim to GCP's required `google.subject` attribute
- The other mappings are useful for creating attribute conditions on the service account

## Verify Configuration

After updating, verify the configuration:

```bash
gcloud iam workload-identity-pools providers describe terraform-cloud \
  --project="karafra-net" \
  --location="global" \
  --workload-identity-pool="terraform-cloud"
```

Look for the `attributeMapping` section and ensure it includes `google.subject: assertion.sub`.

## Service Account Binding

Also ensure your service account has the correct IAM binding:

```bash
gcloud iam service-accounts add-iam-policy-binding \
  terraform@karafra-net.iam.gserviceaccount.com \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/1019265211616/locations/global/workloadIdentityPools/terraform-cloud/attribute.terraform_organization_name/karafra-net"
```

(Adjust the `attribute.terraform_organization_name` value to match your Terraform Cloud organization name)

