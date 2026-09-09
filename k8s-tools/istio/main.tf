# https://istio.io/latest/docs/setup/install/helm/
# Official recommended install order: base (CRDs + cluster roles) -> istiod (control plane) -> gateway (data plane ingress)
# All 3 charts must be pinned to the same version (see variables.tf)

resource "kubectl_manifest" "istio_system_namespace" {
  yaml_body = <<-YAML
apiVersion: v1
kind: Namespace
metadata:
  name: istio-system
YAML
}

# CRDs and cluster-wide resources (ClusterRole, ClusterRoleBinding, etc.)
resource "helm_release" "istio_base" {
  name       = "istio-base"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "base"
  version    = var.istio_chart_version
  namespace  = "istio-system"

  depends_on = [kubectl_manifest.istio_system_namespace]
}

# Control plane (istiod): sidecar injection webhook, config validation, certificate authority
resource "helm_release" "istiod" {
  name       = "istiod"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "istiod"
  version    = var.istio_chart_version
  namespace  = "istio-system"

  values = [
    file("${path.module}/values-istiod.yaml")
  ]

  depends_on = [helm_release.istio_base]
}

# Mesh-wide STRICT mTLS by default (zero-trust). Workloads without a sidecar simply can't talk to meshed ones.
# Namespaces/workloads can still override this with their own PeerAuthentication if plaintext is ever required.
resource "kubectl_manifest" "default_peer_authentication" {
  yaml_body = <<-YAML
apiVersion: security.istio.io/v1
kind: PeerAuthentication
metadata:
  name: default
  namespace: istio-system
spec:
  mtls:
    mode: STRICT
YAML

  depends_on = [helm_release.istiod]
}

resource "kubectl_manifest" "istio_ingress_namespace" {
  yaml_body = <<-YAML
apiVersion: v1
kind: Namespace
metadata:
  name: istio-ingress
  labels:
    # The gateway chart's pod ships with a placeholder "image: auto" container,
    # istiod's injection webhook rewrites it to the real proxyv2 image on admission.
    istio-injection: enabled
YAML

  depends_on = [helm_release.istiod]
}

# Dedicated ingress gateway workload, deployed like any other app so it can be scaled/upgraded independently of istiod.
# This is the mesh's own ingress (mTLS/traffic-mgmt aware), separate from the cluster's Gateway API
# implementation (envoy-gateway-api) used for non-meshed north-south traffic.
resource "helm_release" "istio_ingressgateway" {
  name       = "istio-ingressgateway"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "gateway"
  version    = var.istio_chart_version
  namespace  = "istio-ingress"

  # The Service is type LoadBalancer, its external IP only gets provisioned once the (optional,
  # separately-flagged) aws-load-balancer-controller module is enabled and reconciles it. Without
  # wait=false here, Helm blocks waiting for that IP and the apply hangs until timeout if that
  # controller isn't running - the gateway pod itself comes up fine either way.
  wait = false

  values = [
    file("${path.module}/values-istio-ingressgateway.yaml")
  ]

  depends_on = [kubectl_manifest.istio_ingress_namespace]
}
