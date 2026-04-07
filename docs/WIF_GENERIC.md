# Workload Identity Federation for External Providers

## Overview

This guide explains how to configure Workload Identity Federation for external identity providers including GitHub Actions, GitLab CI/CD, AWS, and any OIDC or SAML-based identity provider using the `google-workload-identity-federation` module.

The module supports both:
- **Kubernetes clusters**: Traditional K8s workload identity with service account mapping
- **External providers**: CI/CD systems (GitHub Actions, GitLab CI/CD), AWS, custom OIDC/SAML providers

## Features

- Support for multiple identity providers (OIDC, AWS, SAML)
- Configurable attribute mappings for fine-grained access control
- Service account impersonation with attribute-based conditions
- Support for multiple workload identity pools
- GitHub Actions integration (primary use case)
- GitLab CI/CD integration
- AWS cross-account access
- Custom OIDC providers

## Architecture

```
External Identity Provider → WIF Pool → WIF Provider → 
Service Account Binding → GCP Service Account → GCP APIs
```

### Components

1. **Workload Identity Pool**: Container for identity providers
2. **Identity Provider**: Configuration for external identity system (GitHub, GitLab, AWS, etc.)
3. **Service Account Binding**: Maps external identities to GCP service accounts
4. **Attribute Mapping**: Transforms external identity claims to Google-compatible attributes

## Use Cases

### GitHub Actions

Authenticate GitHub Actions workflows to GCP without using service account keys.

```hcl
external_identity_pools = {
  "github-actions" = {
    display_name = "GitHub Actions Pool"
    description  = "Workload Identity for GitHub Actions workflows"
    
    providers = {
      "github-oidc" = {
        display_name = "GitHub OIDC Provider"
        
        oidc = {
          issuer_uri = "https://token.actions.githubusercontent.com"
          allowed_audiences = []
        }
        
        attribute_mapping = {
          "google.subject"       = "assertion.sub"
          "attribute.actor"      = "assertion.actor"
          "attribute.repository" = "assertion.repository"
          "attribute.ref"        = "assertion.ref"
        }
        
        attribute_condition = "assertion.repository_owner == 'YourOrgName'"
      }
    }
    
    service_account_bindings = {
      "deploy-prod" = {
        service_account_email = "github-deploy@project.iam.gserviceaccount.com"
        attribute_name        = "repository"
        attribute_value       = "YourOrgName/your-repo"
      }
    }
  }
}
```

**GitHub Actions Workflow Example**:

```yaml
name: Deploy to GCP
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      id-token: write
    
    steps:
      - uses: actions/checkout@v4
      
      - id: auth
        uses: google-github-actions/auth@v2
        with:
          workload_identity_provider: 'projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github-actions/providers/github-oidc'
          service_account: 'github-deploy@project.iam.gserviceaccount.com'
      
      - name: Deploy
        run: |
          gcloud compute instances list
```

### GitLab CI/CD

Authenticate GitLab CI/CD pipelines to GCP.

```hcl
external_identity_pools = {
  "gitlab-ci" = {
    display_name = "GitLab CI Pool"
    description  = "Workload Identity for GitLab CI/CD pipelines"
    
    providers = {
      "gitlab-oidc" = {
        display_name = "GitLab OIDC Provider"
        
        oidc = {
          issuer_uri        = "https://gitlab.com"
          allowed_audiences = ["https://gitlab.com"]
        }
        
        attribute_mapping = {
          "google.subject"           = "assertion.sub"
          "attribute.project_path"   = "assertion.project_path"
          "attribute.namespace_path" = "assertion.namespace_path"
          "attribute.ref"            = "assertion.ref"
          "attribute.ref_type"       = "assertion.ref_type"
        }
        
        attribute_condition = "assertion.namespace_path == 'your-group'"
      }
    }
    
    service_account_bindings = {
      "gitlab-deploy" = {
        service_account_email = "gitlab-deploy@project.iam.gserviceaccount.com"
        attribute_name        = "project_path"
        attribute_value       = "your-group/your-project"
      }
    }
  }
}
```

**GitLab CI/CD Configuration**:

```yaml
deploy:
  image: google/cloud-sdk:alpine
  id_tokens:
    GITLAB_OIDC_TOKEN:
      aud: https://gitlab.com
  script:
    - echo $GITLAB_OIDC_TOKEN > token.txt
    - gcloud iam workload-identity-pools create-cred-config \
        projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/gitlab-ci/providers/gitlab-oidc \
        --service-account=gitlab-deploy@project.iam.gserviceaccount.com \
        --output-file=credentials.json \
        --credential-source-file=token.txt
    - export GOOGLE_APPLICATION_CREDENTIALS=credentials.json
    - gcloud compute instances list
```

### AWS Cross-Account Access

Allow AWS resources to access GCP services.

```hcl
external_identity_pools = {
  "aws-integration" = {
    display_name = "AWS Integration Pool"
    description  = "Workload Identity for AWS resources"
    
    providers = {
      "aws-provider" = {
        display_name = "AWS Provider"
        
        aws = {
          account_id = "123456789012"
        }
        
        attribute_mapping = {
          "google.subject"        = "assertion.arn"
          "attribute.aws_role"    = "assertion.arn.extract('assumed-role/{role}/')"
          "attribute.aws_account" = "assertion.account"
        }
      }
    }
    
    service_account_bindings = {
      "aws-lambda" = {
        service_account_email = "aws-integration@project.iam.gserviceaccount.com"
        attribute_name        = "aws_role"
        attribute_value       = "lambda-execution-role"
      }
    }
  }
}
```

### Multiple Repositories with Granular Access

Control access per repository with different permissions.

```hcl
external_identity_pools = {
  "github-multi-repo" = {
    display_name = "GitHub Multiple Repositories"
    
    providers = {
      "github-oidc" = {
        oidc = {
          issuer_uri = "https://token.actions.githubusercontent.com"
        }
        
        attribute_mapping = {
          "google.subject"       = "assertion.sub"
          "attribute.repository" = "assertion.repository"
          "attribute.ref"        = "assertion.ref"
        }
      }
    }
    
    service_account_bindings = {
      "frontend-deploy" = {
        service_account_email = "frontend-deploy@project.iam.gserviceaccount.com"
        attribute_name        = "repository"
        attribute_value       = "YourOrg/frontend-app"
      }
      
      "backend-deploy" = {
        service_account_email = "backend-deploy@project.iam.gserviceaccount.com"
        attribute_name        = "repository"
        attribute_value       = "YourOrg/backend-api"
      }
      
      "infrastructure-deploy" = {
        service_account_email = "infra-deploy@project.iam.gserviceaccount.com"
        attribute_name        = "repository"
        attribute_value       = "YourOrg/infrastructure"
      }
    }
  }
}
```

## Module Structure

### Input Variables

#### `gcp_project_name`

- **Type**: `string`
- **Required**: Yes
- **Description**: GCP project ID where resources will be created

#### `workload_identity_pools`

- **Type**: `map(object)`
- **Required**: No (default: `{}`)
- **Description**: Map of workload identity pool configurations

**Object Structure**:

```hcl
{
  pool_name = {
    display_name = string                  # Optional: Human-readable name
    description  = string                  # Optional: Pool description
    disabled     = bool                    # Optional: Disable pool (default: false)
    
    providers = map(object({
      display_name        = string         # Optional: Provider display name
      description         = string         # Optional: Provider description
      disabled            = bool           # Optional: Disable provider (default: false)
      attribute_mapping   = map(string)    # Optional: Attribute mappings
      attribute_condition = string         # Optional: CEL condition for access
      
      oidc = object({                      # Optional: OIDC configuration
        issuer_uri        = string
        allowed_audiences = list(string)
        jwks_json         = string
      })
      
      aws = object({                       # Optional: AWS configuration
        account_id = string
      })
      
      saml = object({                      # Optional: SAML configuration
        idp_metadata_xml = string
      })
    }))
    
    service_account_bindings = map(object({
      service_account_email = string       # Required: GCP service account email
      role                  = string       # Optional: IAM role (default: roles/iam.workloadIdentityUser)
      attribute_name        = string       # Required: Attribute to match
      attribute_value       = string       # Required: Attribute value
    }))
  }
}
```

### Outputs

#### `workload_identity_pools`

Map of created workload identity pools with metadata.

#### `workload_identity_providers`

Map of created providers with their configuration.

#### `service_account_bindings`

Map of IAM bindings between external identities and GCP service accounts.

#### `provider_names`

Map of provider resource names for use in authentication configuration.

## Attribute Mappings

Attribute mappings transform claims from external identity tokens into Google-compatible attributes.

### Common Mappings

#### GitHub Actions

```hcl
attribute_mapping = {
  "google.subject"       = "assertion.sub"
  "attribute.actor"      = "assertion.actor"
  "attribute.repository" = "assertion.repository"
  "attribute.ref"        = "assertion.ref"
  "attribute.ref_type"   = "assertion.ref_type"
}
```

**Available GitHub Claims**:
- `sub`: Subject (e.g., `repo:org/repo:ref:refs/heads/main`)
- `actor`: GitHub username triggering workflow
- `repository`: Full repository name (org/repo)
- `repository_owner`: Organization or user name
- `ref`: Git ref (branch/tag)
- `ref_type`: Type of ref (branch/tag)
- `workflow`: Workflow file name
- `job_workflow_ref`: Full workflow reference

#### GitLab CI/CD

```hcl
attribute_mapping = {
  "google.subject"           = "assertion.sub"
  "attribute.project_path"   = "assertion.project_path"
  "attribute.namespace_path" = "assertion.namespace_path"
  "attribute.ref"            = "assertion.ref"
  "attribute.ref_type"       = "assertion.ref_type"
  "attribute.pipeline_source" = "assertion.pipeline_source"
}
```

**Available GitLab Claims**:
- `project_path`: Full project path (group/subgroup/project)
- `namespace_path`: Group/user path
- `ref`: Branch or tag name
- `ref_type`: Type (branch/tag)
- `pipeline_source`: How pipeline was triggered
- `user_login`: Username triggering pipeline

## Attribute Conditions

Use CEL (Common Expression Language) to enforce fine-grained access control.

### Examples

#### Restrict to Specific Organization

```hcl
attribute_condition = "assertion.repository_owner == 'YourOrgName'"
```

#### Allow Only Main Branch

```hcl
attribute_condition = "assertion.ref == 'refs/heads/main'"
```

#### Multiple Conditions

```hcl
attribute_condition = "assertion.repository_owner == 'YourOrg' && assertion.ref_type == 'branch'"
```

#### Pattern Matching

```hcl
attribute_condition = "assertion.repository.startsWith('YourOrg/') && assertion.ref.matches('refs/heads/(main|develop)')"
```

## Security Best Practices

### 1. Use Attribute Conditions

Always use attribute conditions to restrict access to specific repositories, branches, or environments.

```hcl
attribute_condition = "assertion.repository == 'YourOrg/your-repo' && assertion.ref == 'refs/heads/main'"
```

### 2. Principle of Least Privilege

Create separate service accounts for different purposes with minimal required permissions.

```hcl
service_account_bindings = {
  "deploy-staging" = {
    service_account_email = "staging-deploy@project.iam.gserviceaccount.com"
    attribute_name        = "ref"
    attribute_value       = "refs/heads/develop"
  }
  
  "deploy-production" = {
    service_account_email = "prod-deploy@project.iam.gserviceaccount.com"
    attribute_name        = "ref"
    attribute_value       = "refs/heads/main"
  }
}
```

### 3. Audit Logging

Enable audit logs to track workload identity usage:

```bash
gcloud logging read "protoPayload.serviceName=sts.googleapis.com" \
  --project=PROJECT_ID \
  --format=json
```

### 4. Regular Review

Periodically review:
- Active workload identity pools
- Service account bindings
- Access patterns in audit logs
- Unused bindings (candidates for removal)

### 5. Disable When Not Needed

Temporarily disable pools or providers when not in use:

```hcl
external_identity_pools = {
  "github-actions" = {
    disabled = true  # Temporarily disable
    # ...
  }
}
```

## Testing

### Test GitHub Actions Authentication

1. Create a test workflow in your repository:

```yaml
name: Test WIF
on: workflow_dispatch

jobs:
  test:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
    
    steps:
      - name: Authenticate to GCP
        id: auth
        uses: google-github-actions/auth@v2
        with:
          workload_identity_provider: 'projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/POOL_ID/providers/PROVIDER_ID'
          service_account: 'SERVICE_ACCOUNT@PROJECT_ID.iam.gserviceaccount.com'
      
      - name: Verify Authentication
        run: |
          gcloud auth list
          gcloud config list
```

2. Run the workflow manually from GitHub Actions UI
3. Check workflow logs for authentication success

### Test from Local Environment

You can test the setup using the GitHub CLI:

```bash
# Generate a GitHub token
gh auth token

# Exchange for GCP credentials
gcloud iam workload-identity-pools create-cred-config \
  projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/POOL_ID/providers/PROVIDER_ID \
  --service-account=SERVICE_ACCOUNT@PROJECT_ID.iam.gserviceaccount.com \
  --credential-source-file=token.txt \
  --output-file=credentials.json

# Use credentials
export GOOGLE_APPLICATION_CREDENTIALS=credentials.json
gcloud auth list
```

## Troubleshooting

### Common Issues

#### 1. Permission Denied Errors

**Error**: `Permission denied on Workload Identity Pool`

**Solution**: Ensure the external identity provider is correctly configured and the attribute mappings match the token claims.

```bash
# Decode GitHub token to inspect claims
echo $GITHUB_TOKEN | jq -R 'split(".") | .[1] | @base64d | fromjson'
```

#### 2. Attribute Condition Failures

**Error**: `Attribute condition evaluation failed`

**Solution**: Verify the CEL expression is correct and the attributes exist in the token.

```hcl
# Test without condition first
attribute_condition = null

# Then add condition gradually
attribute_condition = "assertion.repository_owner == 'YourOrg'"
```

#### 3. Service Account Impersonation Failed

**Error**: `Permission denied to impersonate service account`

**Solution**: Verify the service account binding is correct:

```bash
gcloud iam service-accounts get-iam-policy SERVICE_ACCOUNT@PROJECT_ID.iam.gserviceaccount.com
```

Should show:
```yaml
bindings:
- members:
  - principalSet://iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/POOL_ID/attribute.ATTRIBUTE_NAME/ATTRIBUTE_VALUE
  role: roles/iam.workloadIdentityUser
```

#### 4. Provider Not Found

**Error**: `Workload Identity Provider not found`

**Solution**: Ensure the provider name is correct:

```bash
gcloud iam workload-identity-pools providers list \
  --workload-identity-pool=POOL_ID \
  --location=global \
  --project=PROJECT_ID
```

## Migration from Static Keys

### Step 1: Create Workload Identity Setup

Apply this module to create WIF pools and providers.

### Step 2: Update CI/CD Workflows

Replace service account key usage with WIF authentication.

**Before**:
```yaml
- uses: google-github-actions/setup-gcloud@v1
  with:
    service_account_key: ${{ secrets.GCP_SA_KEY }}
```

**After**:
```yaml
- uses: google-github-actions/auth@v2
  with:
    workload_identity_provider: 'projects/.../workloadIdentityPools/...'
    service_account: 'sa@project.iam.gserviceaccount.com'
```

### Step 3: Verify New Setup

Test thoroughly in non-production environments.

### Step 4: Remove Static Keys

Delete service account keys from secrets and revoke them in GCP.

```bash
# List keys
gcloud iam service-accounts keys list \
  --iam-account=SERVICE_ACCOUNT@PROJECT_ID.iam.gserviceaccount.com

# Delete key
gcloud iam service-accounts keys delete KEY_ID \
  --iam-account=SERVICE_ACCOUNT@PROJECT_ID.iam.gserviceaccount.com
```

## Additional Resources

- [Google Cloud Workload Identity Federation](https://cloud.google.com/iam/docs/workload-identity-federation)
- [GitHub Actions OIDC](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)
- [GitLab CI/CD OIDC](https://docs.gitlab.com/ee/ci/cloud_services/)
- [CEL Language](https://github.com/google/cel-spec)

