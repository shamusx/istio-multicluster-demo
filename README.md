# 🚀 Istio Multi-Cluster Service Mesh with Zero-Trust Security

This repository provides a production-ready implementation of a secure, multi-cluster Istio service mesh with distinct trust domains and zero-trust security principles. The architecture consists of:

- **Backend Cluster (Cluster 1)**: Hosts internal services and applications with `internal.tetrate.io` trust domain
- **Edge Cluster (Cluster 2)**: External-facing cluster with `external.tetrate.io` trust domain and ingress capabilities

## 🔍 Key Concepts

- **Dual Trust Domains**: Strict separation between internal and external services
- **Zero-Trust Architecture**: All traffic is authenticated and authorized by default
- **Fine-grained Access Control**: Service-to-service authorization based on service identity
- **Defense in Depth**: Multiple layers of security controls

## 🛡️ Security Features

- **Mutual TLS (mTLS)** for all service communications
- **Service-to-Service Authorization** with precise access controls
- **Dual Trust Domains** for internal/external separation
- **Strict mTLS** with `STRICT` mode enforcement
- **Centralized Certificate Management** via cert-manager
- **Automated Certificate Rotation** for enhanced security
- **GitOps Workflow** with ArgoCD for policy as code

## 📚 Documentation

### Core Documentation
- [Multi-Cluster Setup](MULTICLUSTER.md) - Comprehensive guide to setting up the multi-cluster environment
- [Edge Gateway Configuration](EDGEGW.md) - Configuring the Edge Gateway for external traffic
- [Service Authorization](AUTHORIZATION.md) - Managing service-to-service authorization policies
- [Troubleshooting Guide](TROUBLESHOOTING.md) - Common issues and their resolutions

## 🏗️ Repository Structure

```
.
├── apps/                      # Application deployments
│   ├── bookinfo/             # Bookinfo application
│   │   ├── bookinfo-namespace.yaml
│   │   └── kustomization.yaml
│   └── sleep/                # Sleep utility for testing
│       ├── kustomization.yaml
│       └── sleep-namespace.yaml
│
├── clusters/                  # Cluster configurations
│   ├── cluster1/             # Backend cluster
│   │   ├── bookinfo.yaml
│   │   ├── cert-manager.yaml
│   │   ├── istio.yaml
│   │   ├── sleep.yaml
│   │   └── values/
│   │
│   ├── cluster2/             # Edge cluster
│   │   ├── cert-manager.yaml
│   │   ├── istio.yaml
│   │   ├── sleep.yaml
│   │   └── values/
│   │
│   └── common/               # Shared configurations
│       └── pki/              # PKI configurations
│
├── helm/                     # Helm charts
│   └── applications/         # Application deployments
│       ├── Chart.yaml
│       └── templates/
│
└── scripts/                  # Utility scripts
    └── gen_demo-mesh-ca_manifest.sh  # Certificate generation
```