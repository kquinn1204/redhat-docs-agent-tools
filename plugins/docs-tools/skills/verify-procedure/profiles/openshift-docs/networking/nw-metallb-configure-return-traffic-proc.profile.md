---
procedure: ~/openshift-docs/modules/nw-metallb-configure-return-traffic-proc.adoc
description: Verify MetalLB symmetric routing with VRF, BGP peering, and EgressService on a kcli-based SNO
cluster: sno
timeout: 300
cleanup: manual
---

## Substitutions

| Placeholder | Value | Notes |
|---|---|---|
| `ens4` | _detect actual interface_ | Run `oc debug node/<node> -- chroot /host ip link show` and find the NIC on the 192.168.130.0/24 network. On kcli SNO with hot-added NIC, this was `ens11`. Replace all occurrences of `ens4` and `ens4vrf` accordingly. |
| `<external_ip_address>` | _from `oc get svc server1 -n test`_ | Use the `EXTERNAL-IP` column value |
| `<port_number>` | `80` | Default port for the LoadBalancer service |

## Prerequisites

### Assumed state

- Cluster is reachable and user has `cluster-admin`
- Kubernetes NMState Operator is installed (namespace `openshift-nmstate`, NMState CR created)
- MetalLB Operator is installed (namespace `metallb-system`, MetalLB CR created, FRR-K8s pods running in `openshift-frr-k8s`)
- A second NIC exists on the node, connected to a network on 192.168.130.0/24
- A BGP peer (FRR) is running at 192.168.130.1 with ASN 200, configured to peer with ASN 100 at 192.168.130.130
- Firewall allows port 179/tcp on the interface facing the node (libvirt zone if using kcli)
- Namespace `test` exists
- Target node is labeled `vrf=true`
- A LoadBalancer service named `server1` exists in namespace `test`

### Setup commands

```bash
# Create test namespace
oc create namespace test --dry-run=client -o yaml | oc apply -f -

# Label the node for VRF
NODE=$(oc get nodes -o jsonpath='{.items[0].metadata.name}')
oc label node $NODE vrf=true --overwrite

# Deploy test workload (agnhost — nginx images may CrashLoopBackOff)
oc apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: server1
  namespace: test
spec:
  replicas: 1
  selector:
    matchLabels:
      app: server1
  template:
    metadata:
      labels:
        app: server1
    spec:
      containers:
      - name: web
        image: registry.k8s.io/e2e-test-images/agnhost:2.39
        args: ["netexec", "--http-port=8080"]
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: server1
  namespace: test
spec:
  type: LoadBalancer
  selector:
    app: server1
  ports:
  - port: 80
    targetPort: 8080
EOF

# Wait for pod
oc rollout status deployment/server1 -n test --timeout=60s

# Start mock BGP router (requires sudo for port 179)
mkdir -p /tmp/frr-bgp-mock
cat > /tmp/frr-bgp-mock/frr.conf <<'FRRCONF'
frr version 8.5
frr defaults traditional
hostname bgp-mock
log stdout informational
router bgp 200
 bgp router-id 192.168.130.1
 neighbor 192.168.130.130 remote-as 100
 address-family ipv4 unicast
  neighbor 192.168.130.130 activate
  neighbor 192.168.130.130 route-map ACCEPT in
  neighbor 192.168.130.130 route-map ACCEPT out
 exit-address-family
route-map ACCEPT permit 10
line vty
FRRCONF

cat > /tmp/frr-bgp-mock/daemons <<'DAEMONS'
zebra=yes
bgpd=yes
ospfd=no
ospf6d=no
ripd=no
ripngd=no
isisd=no
pimd=no
ldpd=no
nhrpd=no
eigrpd=no
babeld=no
sharpd=no
pbrd=no
bfdd=no
fabricd=no
vrrpd=no
pathd=no
DAEMONS

cat > /tmp/frr-bgp-mock/vtysh.conf <<'VTYSH'
service integrated-vtysh-config
VTYSH

sudo podman rm -f frr-bgp-mock 2>/dev/null
sudo podman run -d --name frr-bgp-mock \
  --network host \
  --cap-add NET_ADMIN --cap-add NET_RAW --cap-add SYS_ADMIN \
  -v /tmp/frr-bgp-mock/frr.conf:/etc/frr/frr.conf:Z \
  -v /tmp/frr-bgp-mock/daemons:/etc/frr/daemons:Z \
  -v /tmp/frr-bgp-mock/vtysh.conf:/etc/frr/vtysh.conf:Z \
  quay.io/frrouting/frr:10.0.1

# Open firewall for BGP (kcli/libvirt environments)
sudo firewall-cmd --zone=libvirt --add-port=179/tcp 2>/dev/null || true
```

## Scope

| Control | Value |
|---|---|
| `mode` | `execute` |
| `steps` | `all` |

## Assertions

| Step | Type | Expected |
|---|---|---|
| `1.b` | `contains` | `vrfpolicy created` |
| `2.b` | `contains` | `frrviavrf created` |
| `3.b` | `contains` | `first-pool created` |
| `4.b` | `contains` | `first-adv created` |
| `5.b` | `contains` | `server1 created` |

## Cleanup

### Preserve

- `namespace/openshift-nmstate`
- `namespace/metallb-system`
- `namespace/openshift-frr-k8s`

### Additional

```bash
oc delete egressservice server1 -n test --ignore-not-found
oc delete bgpadvertisement first-adv -n metallb-system --ignore-not-found
oc delete ipaddresspool first-pool -n metallb-system --ignore-not-found
oc delete bgppeer frrviavrf -n metallb-system --ignore-not-found
oc delete nncp vrfpolicy --ignore-not-found
oc delete deployment server1 -n test --ignore-not-found
oc delete svc server1 -n test --ignore-not-found
oc delete namespace test --ignore-not-found
NODE=$(oc get nodes -o jsonpath='{.items[0].metadata.name}')
oc label node $NODE vrf- egress-service.k8s.ovn.org/test-server1- --overwrite 2>/dev/null
sudo podman rm -f frr-bgp-mock 2>/dev/null
```
