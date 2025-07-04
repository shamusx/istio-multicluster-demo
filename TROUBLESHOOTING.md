# Troubleshooting

## Cluster Configuration

### Cluster Contexts

```sh
export KUBECTX_CLUSTER1=aks-sw0-124-eastus-0  # Backend Cluster
export KUBECTX_CLUSTER2=aks-sw0-124-eastus-1  # Edge Cluster
```

## Cert Validation 

Validate CA for both clusters is the same.
```sh
diff \
   <(kubectl --context="${KUBECTX_CLUSTER1}" -n istio-system get secret cacerts -ojsonpath='{.data.root-cert\.pem}') \
   <(kubectl --context="${KUBECTX_CLUSTER2}" -n istio-system get secret cacerts -ojsonpath='{.data.root-cert\.pem}')
```