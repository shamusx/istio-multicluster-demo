# Service Authorization Guide

This guide explains how to configure fine-grained access control for services in your multi-cluster Istio mesh.

## Architecture Overview
```mermaid
graph TD
    %% Internet entry point
    User[End User] -->|HTTP GET| EdgeGW[Edge Gateway]

    %% Edge Cluster (external.tetrate.io)
    subgraph Edge_Cluster["Edge Cluster (external.tetrate.io)"]
        spacer1[" "]:::invisible
        spacer2[" "]:::invisible
        spacer3[" "]:::invisible
        EdgeGW[Edge Gateway<br/>Host: edge-bookinfo.sandbox.tetrate.io]
        SleepEdge[Sleep App]
    end

    %% Backend Cluster (internal.tetrate.io)
    subgraph Backend_Cluster["Backend Cluster (internal.tetrate.io)"]
        subgraph Bookinfo_NS["bookinfo Namespace"]
            ProductPage[ProductPage Service]
            Reviews[Reviews Service]
            Details[Details Service]
            Ratings[Ratings Service]
            ProductPage --> Reviews
            ProductPage --> Details
            ProductPage --> Ratings
        end
        SleepBackend[Sleep App]
    end

    %% AuthZ Policy Paths
    SleepBackend -->|&check; Allowed<br/>internal.tetrate.io/*| ProductPage
    EdgeGW -->|&check; Allowed<br/>Host=edge-bookinfo.sandbox.tetrate.io<br/>SA=istio-edge-gw| ProductPage
    SleepEdge -->|&cross; Denied| ProductPage

    %% Link styling
    linkStyle 4 stroke:#4caf50,stroke-width:2px
    linkStyle 5 stroke:#4caf50,stroke-width:2px
    linkStyle 6 stroke:#f44336,stroke-width:2px,stroke-dasharray: 5

    %% Invisible class to pad subgraph labels
    classDef invisible fill:#ffffff00,stroke:#ffffff00
    class spacer1,spacer2,spacer3 invisible
```

## Prerequisites

- Two Kubernetes clusters set up with Istio multi-cluster
- `kubectl` configured with access to both clusters
- Cluster contexts set as follows:
  ```sh
  export KUBECTX_CLUSTER1=aks-sw0-124-eastus-0  # Backend Cluster
  export KUBECTX_CLUSTER2=aks-sw0-124-eastus-1  # Edge Cluster
  ```

## 0. Verify Workload Certificates

Before applying authorization policies, verify the workload certificates to ensure they're using the correct trust domains.

### Check Backend Cluster Certificate

```bash
# View the certificate details
istioctl pc secret -n sleep deploy/sleep --context $KUBECTX_CLUSTER1 -o json | \
jq -r '.dynamicActiveSecrets[0].secret.tlsCertificate.certificateChain.inlineBytes' | \
base64 --decode | \
openssl x509 -noout -text | \
grep -A 2 'X509v3 Subject Alternative Name'
```

### Check Edge Cluster Certificate

```bash
# View the certificate details
istioctl pc secret -n sleep deploy/sleep --context $KUBECTX_CLUSTER2 -o json | \
jq -r '.dynamicActiveSecrets[0].secret.tlsCertificate.certificateChain.inlineBytes' | \
base64 --decode | \
openssl x509 -noout -text | \
grep -A 2 'X509v3 Subject Alternative Name'
```

You should see different trust domains in the Subject Alternative Names:
- Backend cluster: `spiffe://internal.tetrate.io/...`
- Edge cluster: `spiffe://external.tetrate.io/...`

## 1. Internal Access Control

### Allow Internal Cluster Access

This policy allows access to the `bookinfo` namespace only from workloads within the `internal.tetrate.io` trust domain.

```sh
cat <<EOF | kubectl apply -f - --context $KUBECTX_CLUSTER1
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: allow-internal
  namespace: bookinfo
spec:
  action: ALLOW
  rules:
  - from:
    - source:
        principals: ["internal.tetrate.io/*"]
EOF
```

### Verify Internal Access

1. **From Backend Cluster**:
   ```sh
   kubectl exec -it $(kubectl get pod -l app=sleep -n sleep -o jsonpath='{.items[0].metadata.name}' --context $KUBECTX_CLUSTER1) \
     -n sleep --context $KUBECTX_CLUSTER1 -- \
     curl -I http://productpage.bookinfo:9080
   ```
   Expected: `HTTP/1.1 200 OK`

2. **From Edge Cluster**:
   ```sh
   kubectl exec -it $(kubectl get pod -l app=sleep -n sleep -o jsonpath='{.items[0].metadata.name}' --context $KUBECTX_CLUSTER2) \
     -n sleep --context $KUBECTX_CLUSTER2 -- \
     curl -I http://productpage.bookinfo:9080
   ```
   Expected: `HTTP/1.1 403 Forbidden`

## 2. External Access Control

### Allow External Access via Edge Gateway

This policy allows external access to the productpage service through the edge gateway, but only for GET requests to the specific hostname.

```sh
cat <<EOF | kubectl apply -f - --context $KUBECTX_CLUSTER1
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  namespace: bookinfo
  name: allow-ext-productpage
spec:
  selector:
    matchLabels:
      app: productpage
  action: ALLOW
  rules:
    - from:
      - source:
          principals: ["external.tetrate.io/ns/edge/sa/istio-edge-gw"]
      to:
      - operation:
          methods: ["GET"]
          hosts: ["edge-bookinfo.sandbox.tetrate.io"]
EOF
```

### Verify External Access

1. **Get Edge Gateway IP**:
   ```sh
   EDGE_IP=$(kubectl get svc -n edge -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}' --context $KUBECTX_CLUSTER2)
   echo "Edge Gateway IP: $EDGE_IP"
   ```

2. **Test Access**:
   ```sh
   curl -I http://edge-bookinfo.sandbox.tetrate.io \
       --resolve "edge-bookinfo.sandbox.tetrate.io:80:$EDGE_IP" \
       -X GET
   ```
   Expected: `HTTP/1.1 200 OK`

3. **Test Without GET Method**:
   ```sh
   curl -I http://edge-bookinfo.sandbox.tetrate.io \
       --resolve "edge-bookinfo.sandbox.tetrate.io:80:$EDGE_IP"
   ```
   Expected: `HTTP/1.1 403 Forbidden`

## 3. Cleanup (Optional)

To remove the authorization policies:

```sh
kubectl delete authorizationpolicy allow-internal -n bookinfo --context $KUBECTX_CLUSTER1
kubectl delete authorizationpolicy allow-ext-productpage -n bookinfo --context $KUBECTX_CLUSTER1
```

## Troubleshooting

- **403 Forbidden**: Verify the source principal and trust domain configuration
- **404 Not Found**: Check if the service and namespace exist
- **Connection Refused**: Verify the service is running and the port is correct

For more details, refer to the [Istio Authorization Documentation](https://istio.io/latest/docs/concepts/security/#authorization).