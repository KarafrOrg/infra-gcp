# infra-gcp Documentation

Infrastructure as Code (IaC) repository for GCP infrastructure, specializing in k8s Workload Identity Federation.

## 📚 Documentation Index

### Getting Started

- **[Quick Start Guide](./QUICKSTART.md)** ⚡  
  Get up and running in 5 minutes with k8s Workload Identity Federation.

- **[Complete Setup Guide](./k8s_WORKLOAD_IDENTITY_SETUP.md)** 📖  
  Comprehensive guide covering architecture, configuration, and usage.

- **[Implementation Summary](./IMPLEMENTATION_SUMMARY.md)** 🔧  
  Technical details about the module architecture and design decisions.

### Module Documentation

- **[google-secret-manager](../modules/google-secret-manager/README.md)**  
  Store k8s CA certificates with rotation notifications via Pub/Sub.

- **[google-workload-identity-federation](../modules/google-workload-identity-federation/README.md)**  
  Configure Workload Identity Federation for k8s clusters.

- **[kubernetes-service-account](../modules/kubernetes-service-account/README.md)**  
  Create Kubernetes service accounts with GCP annotations.

- **[google-service-account](../modules/google-service-account/)**  
  Manage GCP service accounts and IAM roles.

### Examples

- **[Complete Working Example](../examples/k8s-workload-identity-complete.tf)**  
  Full Terraform configuration using all modules together.

### Helper Scripts

- **[extract-k8s-ca.sh](../scripts/extract-k8s-ca.sh)**  
  Extract CA certificates from k8s clusters.

## 🎯 What This Repository Provides

### k8s Workload Identity Federation
Enable Kubernetes pods in k8s clusters to authenticate with GCP services without service account keys.

**Key Features:**
- ✅ Secure, keyless authentication
- ✅ CA certificate rotation handling with Pub/Sub
- ✅ Multi-cluster support
- ✅ Namespace isolation
- ✅ Fully modular design

### Module Architecture

```
┌─────────────────────────────────────┐
│   google-service-account            │  Creates GCP service accounts
└───────────────┬─────────────────────┘
                │
                ↓
┌─────────────────────────────────────┐
│   google-secret-manager             │  Stores CA certificates
└───────────────┬─────────────────────┘  + Pub/Sub for rotation
                │
                ↓
┌─────────────────────────────────────┐
│   google-workload-identity-         │  Configures WIF pools
│   federation                        │  + IAM bindings
└───────────────┬─────────────────────┘
                │
                ↓
┌─────────────────────────────────────┐
│   kubernetes-service-account        │  Creates K8s service accounts
└─────────────────────────────────────┘  with GCP annotations
```

## 🚀 Quick Start

```bash
# 1. Extract your k8s CA certificate
./scripts/extract-k8s-ca.sh my-k8s-cluster

# 2. Configure and deploy
cp examples/k8s-workload-identity-complete.tf main.tf
# Edit variables
terraform init
terraform apply

# 3. Test authentication
kubectl exec -it test-pod -n production -- gcloud auth list
```

See [Quick Start Guide](./QUICKSTART.md) for detailed instructions.

## 📋 Prerequisites

- Terraform >= 1.0
- k8s cluster with OIDC authentication
- GCP project with billing enabled
- kubectl with cluster access
- gcloud CLI installed

## 🔒 Security Features

- **No Service Account Keys**: Uses Workload Identity Federation
- **Secure Storage**: CA certificates in Secret Manager
- **Rotation Monitoring**: Pub/Sub notifications
- **Least Privilege**: Minimal IAM permissions
- **Namespace Isolation**: Per-namespace service accounts

## 📖 Learn More

| Document | When to Read |
|----------|--------------|
| [QUICKSTART.md](./QUICKSTART.md) | First time setup |
| [k8s_WORKLOAD_IDENTITY_SETUP.md](./k8s_WORKLOAD_IDENTITY_SETUP.md) | Understanding architecture |
| [IMPLEMENTATION_SUMMARY.md](./IMPLEMENTATION_SUMMARY.md) | Contributing or customizing |
| Module READMEs | Using specific modules |

## 🤝 Contributing

When contributing:
1. Follow the existing module structure
2. Update relevant documentation
3. Add examples for new features
4. Test with multiple configurations

## 📞 Support

- Review module-specific documentation
- Check troubleshooting sections
- See [k8s_WORKLOAD_IDENTITY_SETUP.md](./k8s_WORKLOAD_IDENTITY_SETUP.md#troubleshooting)
