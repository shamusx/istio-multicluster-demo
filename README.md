# Istio Multi-Cluster

## Bash Script to 

1. PKI Setup
2. Istiod - revisioned multi-cluster prep
3. Istio EastWest Gateway
4. MultiPrimary discovery

## Setup

```sh
export KUBECTX_CLUSTER1=aks-sw0-124-eastus-0
export KUBECTX_CLUSTER2=aks-sw0-124-eastus-1
```

### ArgoCD Install

Install ArgoCD in both clusters and update the password `Tetrate123`

#### Cluster1

```sh
# Install ArgoCD in Cluster1
kubectl create namespace argocd --context $KUBECTX_CLUSTER1
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml --context $KUBECTX_CLUSTER1

# Wait for all ArgoCD pods to be ready (timeout after 5 minutes)
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s --context $KUBECTX_CLUSTER1

# Update ArgoCD password (Tetrate123)
kubectl -n argocd patch secret argocd-secret --context $KUBECTX_CLUSTER1 \
  -p '{"stringData": {
    "admin.password": "$2a$10$GZ53dm6O8THQSqR7Mnrdo.UKkqyTVwM9PXPVj2ElPSCFH/owcwiOa",
    "admin.passwordMtime": "'$(date +%FT%T%Z)'"
  }}'
```

#### Cluster2

```sh
# Install ArgoCD in Cluster2
kubectl create namespace argocd --context $KUBECTX_CLUSTER2
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml --context $KUBECTX_CLUSTER2

# Wait for all ArgoCD pods to be ready (timeout after 5 minutes)
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s --context $KUBECTX_CLUSTER2

# Update ArgoCD password (Tetrate123)
kubectl -n argocd patch secret argocd-secret --context $KUBECTX_CLUSTER2 \
  -p '{"stringData": {
    "admin.password": "$2a$10$GZ53dm6O8THQSqR7Mnrdo.UKkqyTVwM9PXPVj2ElPSCFH/owcwiOa",
    "admin.passwordMtime": "'$(date +%FT%T%Z)'"
  }}'
```

### Stage Istio in Cluster1

```sh
kubectl apply -f apps/cluster1-infra.yaml -n argocd --context $KUBECTX_CLUSTER1
```