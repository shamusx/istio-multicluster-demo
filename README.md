# Istio Multi-Cluster Service Mesh

This repository contains the configuration and deployment files for setting up a secure, multi-cluster Istio service mesh with two distinct clusters:

- **Backend Cluster (Cluster 1)**: Hosts internal services and applications
- **Edge Cluster (Cluster 2)**: External-facing cluster with ingress capabilities

## 📋 Features

- **Multi-Primary** configuration for high availability
- **mTLS** secured service-to-service communication
- **Centralized Certificate Management** using cert-manager
- **GitOps** workflow with ArgoCD
- **Multi-cluster Service Discovery**
- **Automated Certificate Rotation**
- **Zero-Trust Security** with strict mTLS

## 📚 Documentation

### Getting Started
- [Multi-Cluster Setup Guide](MULTICLUSTER.md) - Comprehensive guide for setting up the multi-cluster environment

### Components
- [Edge Gateway Configuration](EDGEGW.md) - Configuring the Edge Gateway for external traffic
- [Service Authorization](AUTHORIZATION.md) - Managing service-to-service authorization policies

## 📂 Repository Structure

```
.
├── apps/                  # Application deployments
├── clusters/              # Cluster-specific configurations
│   ├── cluster1/          # Backend cluster configs
│   └── cluster2/          # Edge cluster configs
├── helm/                  # Helm chart configurations
└── scripts/               # Utility scripts
```