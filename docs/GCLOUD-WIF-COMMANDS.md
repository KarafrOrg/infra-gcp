# GCloud Commands to Manage Workload Identity Pools

## Quick Reference Commands

### List All Workload Identity Pools
```bash
gcloud iam workload-identity-pools list \
  --project=karafra-net \
  --location=global
```

### List Pools with Details
```bash
gcloud iam workload-identity-pools list \
  --project=karafra-net \
  --location=global \
  --format="table(name,displayName,state,description)"
```

### Describe a Specific Pool
```bash
gcloud iam workload-identity-pools describe k3s-admin \
  --project=karafra-net \
  --location=global
```

### List Providers in a Pool
```bash
gcloud iam workload-identity-pools providers list \
  --project=karafra-net \
  --location=global \
  --workload-identity-pool=k3s-admin
```

### Describe a Specific Provider
```bash
gcloud iam workload-identity-pools providers describe oidc-provider \
  --project=karafra-net \
  --location=global \
  --workload-identity-pool=k3s-admin
```

## Deletion Commands

### Delete a Provider (must be done before deleting pool)
```bash
# Delete provider 'oidc-provider' from pool 'k3s-admin'
gcloud iam workload-identity-pools providers delete oidc-provider \
  --project=karafra-net \
  --location=global \
  --workload-identity-pool=k3s-admin \
  --quiet
```

### Delete a Workload Identity Pool
```bash
# Delete pool 'k3s-admin'
gcloud iam workload-identity-pools delete k3s-admin \
  --project=karafra-net \
  --location=global \
  --quiet
```

### Delete Multiple Pools
```bash
# Delete k3s-admin pool
gcloud iam workload-identity-pools delete k3s-admin \
  --project=karafra-net \
  --location=global \
  --quiet

# Delete k3s-onprem pool
gcloud iam workload-identity-pools delete k3s-onprem \
  --project=karafra-net \
  --location=global \
  --quiet
```

## Complete Cleanup (Providers + Pool)

### For k3s-admin pool:
```bash
# 1. List providers first
gcloud iam workload-identity-pools providers list \
  --project=karafra-net \
  --location=global \
  --workload-identity-pool=k3s-admin

# 2. Delete each provider (example)
gcloud iam workload-identity-pools providers delete oidc-provider \
  --project=karafra-net \
  --location=global \
  --workload-identity-pool=k3s-admin \
  --quiet

# 3. Delete the pool
gcloud iam workload-identity-pools delete k3s-admin \
  --project=karafra-net \
  --location=global \
  --quiet
```

### For k3s-onprem pool:
```bash
# 1. List providers first
gcloud iam workload-identity-pools providers list \
  --project=karafra-net \
  --location=global \
  --workload-identity-pool=k3s-onprem

# 2. Delete each provider (if any exist)
gcloud iam workload-identity-pools providers delete oidc-provider \
  --project=karafra-net \
  --location=global \
  --workload-identity-pool=k3s-onprem \
  --quiet

# 3. Delete the pool
gcloud iam workload-identity-pools delete k3s-onprem \
  --project=karafra-net \
  --location=global \
  --quiet
```

## Using the Helper Scripts

### Option 1: Check what exists
```bash
cd /Users/matustoth/IdeaProjects/infra-gcp
./check-wif-pools.sh
```

### Option 2: Delete pools with interactive confirmation
```bash
cd /Users/matustoth/IdeaProjects/infra-gcp
./delete-wif-pools.sh
```

## One-Liner Cleanup Commands

### Delete k3s-admin completely (providers + pool):
```bash
for provider in $(gcloud iam workload-identity-pools providers list --project=karafra-net --location=global --workload-identity-pool=k3s-admin --format="value(name.basename())" 2>/dev/null); do gcloud iam workload-identity-pools providers delete $provider --project=karafra-net --location=global --workload-identity-pool=k3s-admin --quiet; done && gcloud iam workload-identity-pools delete k3s-admin --project=karafra-net --location=global --quiet
```

### Delete k3s-onprem completely (providers + pool):
```bash
for provider in $(gcloud iam workload-identity-pools providers list --project=karafra-net --location=global --workload-identity-pool=k3s-onprem --format="value(name.basename())" 2>/dev/null); do gcloud iam workload-identity-pools providers delete $provider --project=karafra-net --location=global --workload-identity-pool=k3s-onprem --quiet; done && gcloud iam workload-identity-pools delete k3s-onprem --project=karafra-net --location=global --quiet
```

## Verification

### After deletion, verify pools are gone:
```bash
gcloud iam workload-identity-pools list \
  --project=karafra-net \
  --location=global
```

### Expected output after cleanup:
```
Listed 0 items.
```

## Troubleshooting

### Pool not visible in Console
Workload Identity Pools may not appear in the GCP Console UI but still exist in the API. Always use gcloud commands to verify.

### Error: "Pool has providers"
You must delete all providers before deleting the pool:
```bash
# List providers
gcloud iam workload-identity-pools providers list \
  --project=karafra-net \
  --location=global \
  --workload-identity-pool=POOL_NAME

# Delete each provider first, then the pool
```

### Error: "PERMISSION_DENIED"
Ensure your account has the following permissions:
- `iam.workloadIdentityPools.delete`
- `iam.workloadIdentityPoolProviders.delete`

Or role: `roles/iam.workloadIdentityPoolAdmin`

## After Cleanup

Once pools are deleted, you can run your Terraform apply again:
```bash
cd /Users/matustoth/IdeaProjects/infra-gcp
terraform plan
terraform apply
```

