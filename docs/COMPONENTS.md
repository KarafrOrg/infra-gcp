# Component Reference

This document provides detailed technical reference for each Terraform component in the stack.

## Table of Contents

- [google-service-account](#google-service-account)
- [google-secret-manager](#google-secret-manager)
- [google-workload-identity-federation](#google-workload-identity-federation)
- [kubernetes-service-account](#kubernetes-service-account)
- [google-workload-identity-federation-generic](#google-workload-identity-federation-generic)

## google-service-account

### Overview

Manages GCP service accounts and their IAM role assignments across the project.

### Source

`./modules/google-service-account`

### Provider Requirements

- `google` ~> 7.7

### Input Variables

#### `gcp_project_name`
- **Type**: `string`
- **Required**: Yes
- **Description**: GCP project name where service accounts will be created

#### `service_accounts`
- **Type**: `map(object)`
- **Required**: Yes
- **Description**: Map of service account configurations
- **Object Schema**:
  ```hcl
  {
    display_name = optional(string)
    description  = optional(string)
    roles        = optional(list(string))
  }
  ```

### Resources Created

- `google_service_account` - One per service account configuration
- `google_project_iam_member` - One per role per service account

### Example Configuration

```hcl
component "google-service-account" {
  source = "./modules/google-service-account"

  providers = {
    google = provider.google.main
  }

  inputs = {
    gcp_project_name = "my-project"
    service_accounts = {
      "k8s-admin" = {
        display_name = "k8s Admin Service Account"
        description  = "Service account for k8s cluster administration"
        roles = [
          "roles/container.admin",
          "roles/iam.serviceAccountUser"
        ]
      }
      "k8s-secret-reader" = {
        display_name = "K8s secrets reader service account"
        description  = "Service account for k8s pods to read secrets"
        roles = [
          "roles/secretmanager.secretAccessor"
        ]
      }
    }
  }
}
```

### Outputs

- `service_accounts` - Map of created service account resources
- `service_account_emails` - Map of service account emails keyed by account name

### Dependencies

None - This is a foundational component.

### Notes

- Service account names are used as-is (without project/domain suffix)
- Roles are assigned at the project level
- Deletion protection is not enabled by default

---

## google-secret-manager

### Overview

Manages Secret Manager integration, including API enablement, service agent provisioning, and Pub/Sub topics for certificate rotation notifications.

### Source

`./modules/google-secret-manager`

### Provider Requirements

- `google` ~> 7.7
- `google-beta` ~> 7.7

### Input Variables

#### `gcp_project_name`
- **Type**: `string`
- **Required**: Yes
- **Description**: GCP project name

#### `k8s_ca_certificate_refs`
- **Type**: `map(object)`
- **Required**: No
- **Default**: `{}`
- **Description**: Map of k8s cluster CA certificate references for Pub/Sub topic creation
- **Object Schema**:
  ```hcl
  {
    enable_pub_sub = optional(bool, true)
    labels         = optional(map(string), {})
  }
  ```

#### `pub_sub_topic_prefix`
- **Type**: `string`
- **Required**: No
- **Default**: `"k8s-ca-rotation"`
- **Description**: Prefix for Pub/Sub topic names for secret rotation notifications

### Resources Created

- `google_project_service.secretmanager` - Enables Secret Manager API
- `google_project_service.serviceusage` - Enables Service Usage API
- `google_project_service_identity.secretmanager_agent` - Creates Secret Manager service agent
- `google_pubsub_topic.secret_rotation` - One per cluster with Pub/Sub enabled
- `google_pubsub_topic_iam_member.secret_manager_publisher` - Grants publisher role to service agent

### Example Configuration

```hcl
component "google-secret-manager" {
  source = "./modules/google-secret-manager"

  providers = {
    google      = provider.google.main
    google-beta = provider.google-beta.main
  }

  inputs = {
    gcp_project_name = "my-project"
    k8s_ca_certificate_refs = {
      "k8s-production" = {
        enable_pub_sub = true
        labels = {
          environment = "production"
          cluster     = "k8s-production"
          managed_by  = "terraform-stacks"
        }
      }
      "k8s-staging" = {
        enable_pub_sub = true
        labels = {
          environment = "staging"
        }
      }
    }
    pub_sub_topic_prefix = "k8s-ca-rotation"
  }
}
```

### Outputs

- `pub_sub_topics` - Map of created Pub/Sub topic resources
- `secret_manager_service_agent_email` - Email of the Secret Manager service agent

### Dependencies

None - Independent component.

### Notes

- API enablement is required before creating service agent
- Service agent is automatically created by GCP when API is enabled
- Pub/Sub topics are named: `{prefix}-{cluster_name}`
- The Secret Manager service agent receives `roles/pubsub.publisher` on topics
- Secrets themselves must be managed externally

### Important: Secret Manager Service Agent

The Secret Manager service agent (`service-{project-number}@gcp-sa-secretmanager.iam.gserviceaccount.com`) is automatically created by Google when you enable the Secret Manager API. This module explicitly provisions it using `google_project_service_identity` to ensure it exists before granting IAM permissions.

---

## google-workload-identity-federation

### Overview

Configures Workload Identity Federation to allow Kubernetes workloads to authenticate to GCP without static credentials.

### Source

`./modules/google-workload-identity-federation`

### Provider Requirements

- `google` ~> 7.7

### Input Variables

#### `gcp_project_name`
- **Type**: `string`
- **Required**: Yes
- **Description**: GCP project name

#### `k8s_clusters`
- **Type**: `map(object)`
- **Required**: Yes
- **Description**: Map of k8s cluster configurations for workload identity federation
- **Object Schema**:
  ```hcl
  {
    issuer_uri                  = string
    display_name                = optional(string)
    description                 = optional(string)
    default_namespace           = optional(string, "default")
    allowed_audiences           = optional(list(string), ["sts.googleapis.com"])
    jwks_json_data              = optional(string)
    kubernetes_service_accounts = map(object({
      namespace                       = optional(string)
      gcp_service_account_email       = string
      create_k8s_sa                   = optional(bool, true)
      k8s_sa_annotations              = optional(map(string), {})
      k8s_sa_labels                   = optional(map(string), {})
      automount_service_account_token = optional(bool, true)
    }))
  }
  ```

### Resources Created

- `google_iam_workload_identity_pool` - One per project (if not using GKE's built-in pool)
- `google_iam_workload_identity_pool_provider` - One per cluster
- `google_service_account_iam_member` - One per Kubernetes service account (for workload identity binding)

### Example Configuration

```hcl
component "google-workload-identity-federation" {
  source = "./modules/google-workload-identity-federation"

  providers = {
    google = provider.google.main
  }

  inputs = {
    gcp_project_name = "my-project"
    k8s_clusters = {
      "k8s-production" = {
        issuer_uri        = "https://kubernetes.default.svc.cluster.local"
        display_name      = "k8s Production Cluster"
        description       = "Workload Identity Federation for production k8s cluster"
        default_namespace = "default"
        allowed_audiences = ["sts.googleapis.com"]
        jwks_json_data    = file("jwks.json")

        kubernetes_service_accounts = {
          "cluster-admin" = {
            namespace                 = "kube-system"
            gcp_service_account_email = "k8s-admin@my-project.iam.gserviceaccount.com"
            create_k8s_sa             = true
            k8s_sa_labels = {
              app  = "cluster-admin"
              tier = "infrastructure"
            }
          }
          "default-app" = {
            namespace                 = "default"
            gcp_service_account_email = "k8s-secret-reader@my-project.iam.gserviceaccount.com"
            create_k8s_sa             = true
          }
        }
      }
    }
  }

  depends_on = [
    component.google-service-account
  ]
}
```

### Outputs

- `workload_identity_pool_id` - ID of the workload identity pool
- `workload_identity_provider_names` - Map of provider names by cluster
- `service_account_bindings` - Map of IAM bindings created

### Dependencies

- **google-service-account** - GCP service accounts must exist before creating WIF bindings

### Notes

- For GKE clusters, use the built-in workload identity pool: `{project-id}.svc.id.goog`
- JWKS must be provided for OIDC token validation
- The issuer URI should match your cluster's OIDC issuer
- IAM binding format: `serviceAccount:{project-id}.svc.id.goog[{namespace}/{k8s-sa}]`

### Security Considerations

- Use specific allowed audiences to prevent token misuse
- Regularly rotate JWKS for enhanced security
- Follow principle of least privilege for GCP service account permissions
- Audit workload identity token exchanges via Cloud Logging

---

## kubernetes-service-account

### Overview

Creates and configures Kubernetes service accounts with Workload Identity annotations for GCP integration.

### Source

`./modules/kubernetes-service-account`

### Provider Requirements

- `kubernetes` ~> 2.35

### Input Variables

#### `k8s_clusters`
- **Type**: `map(object)`
- **Required**: Yes
- **Description**: Map of k8s cluster configurations (same structure as WIF component)
- **Object Schema**: See google-workload-identity-federation component

### Resources Created

- `kubernetes_service_account_v1` - One per service account configuration where `create_k8s_sa = true`

### Example Configuration

```hcl
component "kubernetes-service-account" {
  source = "./modules/kubernetes-service-account"

  providers = {
    kubernetes = provider.kubernetes.k8s
  }

  inputs = {
    k8s_clusters = {
      "k8s-production" = {
        kubernetes_service_accounts = {
          "cluster-admin" = {
            namespace                 = "kube-system"
            gcp_service_account_email = "k8s-admin@my-project.iam.gserviceaccount.com"
            create_k8s_sa             = true
            k8s_sa_labels = {
              app  = "cluster-admin"
              tier = "infrastructure"
            }
            k8s_sa_annotations = {
              "description" = "Admin service account"
            }
          }
        }
      }
    }
  }

  depends_on = [
    component.google-workload-identity-federation
  ]
}
```

### Service Account Annotations

The component automatically adds the following annotation to each service account:
```yaml
iam.gke.io/gcp-service-account: {gcp_service_account_email}
```

This annotation is required for Workload Identity to function.

### Outputs

- `service_accounts` - Map of created Kubernetes service account resources
- `service_account_names` - Map of service account names by cluster and identifier

### Dependencies

- **google-workload-identity-federation** - WIF must be configured before creating K8s service accounts

### Notes

- Service accounts are created in the namespace specified in configuration
- The GCP service account email annotation is automatically added
- Custom annotations and labels can be provided
- `automount_service_account_token` defaults to `true`

### Verification

After creation, verify service accounts with:

```bash
kubectl get sa {name} -n {namespace} -o yaml
```

Check for the `iam.gke.io/gcp-service-account` annotation.

---

## Component Interaction

### Dependency Graph

```
google-service-account
        ↓
google-workload-identity-federation
        ↓
kubernetes-service-account

google-secret-manager (independent)
```

### Execution Order

1. **google-service-account**: Creates GCP service accounts first
2. **google-secret-manager**: Can run in parallel with step 1
3. **google-workload-identity-federation**: Requires service accounts to exist
4. **kubernetes-service-account**: Requires WIF to be configured

### Data Flow Between Components

1. Service account emails flow from `google-service-account` to `google-workload-identity-federation`
2. Cluster and service account configurations flow from `google-workload-identity-federation` to `kubernetes-service-account`
3. Secret Manager operates independently but uses service accounts for access control

## Common Configuration Patterns

### Pattern 1: Admin Service Account

```hcl
# In deployments.tfdeploy.hcl
gcp_service_service_accounts = {
  "k8s-admin" = {
    display_name = "k8s Admin Service Account"
    description  = "Service account for k8s cluster administration"
    roles = [
      "roles/container.admin",
      "roles/iam.serviceAccountUser"
    ]
  }
}

k8s_clusters = {
  "k8s-production" = {
    kubernetes_service_accounts = {
      "cluster-admin" = {
        namespace                 = "kube-system"
        gcp_service_account_email = "k8s-admin@{project}.iam.gserviceaccount.com"
        create_k8s_sa             = true
      }
    }
  }
}
```

### Pattern 2: Application with Secret Access

```hcl
gcp_service_service_accounts = {
  "app-secrets" = {
    display_name = "Application Secret Reader"
    roles = ["roles/secretmanager.secretAccessor"]
  }
}

k8s_clusters = {
  "k8s-production" = {
    kubernetes_service_accounts = {
      "myapp" = {
        namespace                 = "production"
        gcp_service_account_email = "app-secrets@{project}.iam.gserviceaccount.com"
        create_k8s_sa             = true
        k8s_sa_labels = {
          app = "myapp"
        }
      }
    }
  }
}
```

### Pattern 3: Multi-Purpose Service Account

```hcl
gcp_service_service_accounts = {
  "k8s-monitoring" = {
    display_name = "k8s Monitoring Service Account"
    roles = [
      "roles/monitoring.metricWriter",
      "roles/logging.logWriter",
      "roles/cloudtrace.agent"
    ]
  }
}
```

## Troubleshooting

### Service Account Issues

**Problem**: Service account creation fails
- Check project permissions
- Verify project ID is correct
- Ensure IAM API is enabled

**Problem**: Role assignment fails
- Verify role name is correct (use `gcloud iam roles list`)
- Check if you have permissions to grant the role
- Ensure service account exists

### Workload Identity Issues

**Problem**: Pod cannot authenticate to GCP
- Verify Kubernetes service account annotation exists
- Check IAM binding exists for workload identity user role
- Verify JWKS is correct
- Ensure allowed audiences match

**Problem**: Token exchange fails
- Check issuer URI matches cluster configuration
- Verify JWKS endpoint is accessible
- Check STS API is enabled
- Review token claims

### Secret Manager Issues

**Problem**: Service agent doesn't exist
- Ensure Secret Manager API is enabled
- Wait for API propagation (2-3 minutes)
- Verify Service Usage API is enabled
- Check `google_project_service_identity` resource

**Problem**: Pub/Sub permissions error
- Verify service agent has publisher role
- Check topic exists
- Review IAM bindings on topic

See [DEPLOYMENT.md](DEPLOYMENT.md) for more troubleshooting guidance.

---

## google-workload-identity-federation-generic

### Overview

Provides flexible Workload Identity Federation for external identity providers including GitHub Actions, GitLab CI/CD, AWS, and any OIDC or SAML-based provider. This module enables authentication from CI/CD systems to GCP without using static service account keys.

### Source

`./modules/google-workload-identity-federation-generic`

### Provider Requirements

- `google` ~> 7.24

### Input Variables

#### `gcp_project_name`
- **Type**: `string`
- **Required**: Yes
- **Description**: GCP project ID where resources will be created

#### `workload_identity_pools`
- **Type**: `map(object)`
- **Required**: No (default: `{}`)
- **Description**: Map of workload identity pool configurations for external providers
- **Object Schema**:
  ```hcl
  {
    display_name = optional(string)
    description  = optional(string)
    disabled     = optional(bool, false)
    
    providers = map(object({
      display_name        = optional(string)
      description         = optional(string)
      disabled            = optional(bool, false)
      attribute_mapping   = optional(map(string))
      attribute_condition = optional(string)
      
      oidc = optional(object({
        issuer_uri        = string
        allowed_audiences = optional(list(string))
        jwks_json         = optional(string)
      }))
      
      aws = optional(object({
        account_id = string
      }))
      
      saml = optional(object({
        idp_metadata_xml = string
      }))
    }))
    
    service_account_bindings = optional(map(object({
      service_account_email = string
      role                  = optional(string, "roles/iam.workloadIdentityUser")
      attribute_name        = string
      attribute_value       = string
    })), {})
  }
  ```

### Resources Created

- `google_iam_workload_identity_pool` - One per pool configuration
- `google_iam_workload_identity_pool_provider` - One per provider in each pool
- `google_service_account_iam_member` - One per service account binding

### Example Configuration

#### GitHub Actions

```hcl
component "google-workload-identity-federation-generic" {
  source = "./modules/google-workload-identity-federation-generic"
  
  providers = {
    google = provider.google.main
  }
  
  inputs = {
    gcp_project_name = "my-project"
    
    workload_identity_pools = {
      "github-actions" = {
        display_name = "GitHub Actions"
        
        providers = {
          "github-oidc" = {
            oidc = {
              issuer_uri = "https://token.actions.githubusercontent.com"
            }
            
            attribute_mapping = {
              "google.subject"       = "assertion.sub"
              "attribute.repository" = "assertion.repository"
            }
            
            attribute_condition = "assertion.repository_owner == 'YourOrg'"
          }
        }
        
        service_account_bindings = {
          "deploy" = {
            service_account_email = "github-deploy@my-project.iam.gserviceaccount.com"
            attribute_name        = "repository"
            attribute_value       = "YourOrg/your-repo"
          }
        }
      }
    }
  }
}
```

#### GitLab CI/CD

```hcl
workload_identity_pools = {
  "gitlab-ci" = {
    display_name = "GitLab CI/CD"
    
    providers = {
      "gitlab-oidc" = {
        oidc = {
          issuer_uri        = "https://gitlab.com"
          allowed_audiences = ["https://gitlab.com"]
        }
        
        attribute_mapping = {
          "google.subject"         = "assertion.sub"
          "attribute.project_path" = "assertion.project_path"
        }
      }
    }
    
    service_account_bindings = {
      "deploy" = {
        service_account_email = "gitlab-deploy@my-project.iam.gserviceaccount.com"
        attribute_name        = "project_path"
        attribute_value       = "group/project"
      }
    }
  }
}
```

### Outputs

#### `workload_identity_pools`
- **Type**: `map(object)`
- **Description**: Map of created workload identity pools with metadata

#### `workload_identity_providers`
- **Type**: `map(object)`
- **Description**: Map of created identity providers with configuration

#### `service_account_bindings`
- **Type**: `map(object)`
- **Description**: Map of service account IAM bindings

#### `provider_names`
- **Type**: `map(string)`
- **Description**: Provider resource names for use in CI/CD authentication configuration

### Dependencies

- `component.google-service-account` - Service accounts must exist before binding

### Usage in CI/CD

#### GitHub Actions Workflow

```yaml
name: Deploy
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
      
      - uses: google-github-actions/auth@v2
        with:
          workload_identity_provider: 'projects/123456789/locations/global/workloadIdentityPools/github-actions/providers/github-oidc'
          service_account: 'github-deploy@project.iam.gserviceaccount.com'
      
      - run: gcloud compute instances list
```

#### GitLab CI/CD Pipeline

```yaml
deploy:
  image: google/cloud-sdk:alpine
  id_tokens:
    GITLAB_OIDC_TOKEN:
      aud: https://gitlab.com
  script:
    - echo ${GITLAB_OIDC_TOKEN} > token.txt
    - gcloud iam workload-identity-pools create-cred-config
        projects/123456789/locations/global/workloadIdentityPools/gitlab-ci/providers/gitlab-oidc
        --service-account=gitlab-deploy@project.iam.gserviceaccount.com
        --output-file=credentials.json
        --credential-source-file=token.txt
    - export GOOGLE_APPLICATION_CREDENTIALS=credentials.json
    - gcloud auth login --cred-file=credentials.json
    - gcloud compute instances list
```

### Best Practices

1. **Use Attribute Conditions**: Always restrict access using CEL expressions
   ```hcl
   attribute_condition = "assertion.repository_owner == 'YourOrg' && assertion.ref == 'refs/heads/main'"
   ```

2. **Separate Service Accounts**: Use different service accounts for different environments
   ```hcl
   service_account_bindings = {
     "prod"    = { attribute_value = "refs/heads/main", ... }
     "staging" = { attribute_value = "refs/heads/develop", ... }
   }
   ```

3. **Minimal Permissions**: Grant only required IAM roles to service accounts

4. **Audit Logging**: Enable audit logs for workload identity usage
   ```bash
   gcloud logging read "protoPayload.serviceName=sts.googleapis.com"
   ```

5. **Disable When Not Needed**: Temporarily disable pools or providers
   ```hcl
   disabled = true
   ```

### Supported Providers

- **GitHub Actions**: OIDC-based authentication
- **GitLab CI/CD**: OIDC-based authentication
- **AWS**: Cross-account access
- **Custom OIDC**: Any OIDC-compliant provider
- **SAML**: SAML 2.0 identity providers

### Attribute Mappings

Common attribute mappings for different providers:

#### GitHub Actions
```hcl
attribute_mapping = {
  "google.subject"           = "assertion.sub"
  "attribute.actor"          = "assertion.actor"
  "attribute.repository"     = "assertion.repository"
  "attribute.repository_owner" = "assertion.repository_owner"
  "attribute.ref"            = "assertion.ref"
}
```

#### GitLab CI/CD
```hcl
attribute_mapping = {
  "google.subject"         = "assertion.sub"
  "attribute.project_path" = "assertion.project_path"
  "attribute.ref"          = "assertion.ref"
}
```

### Security Considerations

1. **Attribute Conditions**: Use CEL expressions to restrict access
2. **Service Account Permissions**: Follow principle of least privilege
3. **Branch Protection**: Use repository branch protection rules
4. **Audit Logs**: Monitor STS token exchanges
5. **Regular Review**: Audit bindings and remove unused ones

### Troubleshooting

**Problem**: Authentication fails in CI/CD
- Verify workload identity provider name is correct
- Check service account exists
- Verify attribute condition matches token claims
- Ensure required APIs are enabled (IAM, STS)

**Problem**: Permission denied to impersonate service account
- Check service account IAM bindings
- Verify principal set matches attribute values
- Review attribute mapping configuration

**Problem**: Attribute condition evaluation failed
- Inspect OIDC token claims
- Verify CEL expression syntax
- Check attribute names match mappings

### Additional Documentation

- [WIF_GENERIC.md](WIF_GENERIC.md) - Comprehensive guide with examples
- [examples/github-actions.md](../modules/google-workload-identity-federation-generic/examples/github-actions.md) - GitHub Actions setup
- [examples/gitlab-ci.md](../modules/google-workload-identity-federation-generic/examples/gitlab-ci.md) - GitLab CI/CD setup
- [examples/workload-identity-federation.md](../examples/workload-identity-federation.md) - Configuration examples

### Notes

- Provider names are formatted as `{pool_id}-{provider_id}`
- All resources are created at the global location
- Service accounts must exist before applying this component
- Supports multiple pools and providers in a single configuration
- Each pool can have multiple providers
- Each provider can have multiple service account bindings


