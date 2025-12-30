resource "kubectl_manifest" "kube_downscaler_namespace" {
  yaml_body = <<-YAML
apiVersion: v1
kind: Namespace
metadata:
  name: kube-downscaler
YAML
}

resource "kubectl_manifest" "kube_downscaler" {
  for_each = fileset("${path.module}/deploy", "*.yaml")

  yaml_body = file("${path.module}/deploy/${each.value}")

  depends_on = [kubectl_manifest.kube_downscaler_namespace]
}
