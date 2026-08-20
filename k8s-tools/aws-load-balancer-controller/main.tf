# https://github.com/kubernetes-sigs/aws-load-balancer-controller
# It satisfies Kubernetes Ingress resources by provisioning Application Load Balancers.
# It satisfies Kubernetes Service resources by provisioning Network Load Balancers.
# It satisfies Kubernetes Gateway resources by provisioning Network Load Balancers and Application Load Balancers.
# This project was formerly known as "AWS ALB Ingress Controller", we rebranded it to be "AWS Load Balancer Controller".

resource "kubectl_manifest" "aws-load-balancer-controller_namespace" {
  yaml_body = <<-YAML
apiVersion: v1
kind: Namespace
metadata:
  name: aws-load-balancer-controller
YAML
}

data "http" "aws_load_balancer_controller_gateway_crds" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v3.5.0/config/crd/gateway/gateway-crds.yaml"
}

# These are AWS Load Balancer Controller-specific Gateway CRDs (gateway.k8s.aws),
# such as LoadBalancerConfiguration/TargetGroupConfiguration/ListenerRuleConfiguration.
# They are different from the generic Gateway API CRDs (gateway.networking.k8s.io)
# installed by the shared gateway-api-crds module.
# Starting from controller v3.5.0, Gateway users should explicitly update/apply
# these AWS-specific CRDs because the controller moved from v1beta1-era CRDs to
# v1 storage/serving expectations for gateway.k8s.aws resources.
# Apply them before the Helm upgrade to keep Gateway features fully enabled and
# avoid API version/storage mismatches.
resource "kubectl_manifest" "aws_load_balancer_controller_gateway_crds" {
  for_each = { for idx, manifest in split("---", data.http.aws_load_balancer_controller_gateway_crds.response_body) :
    "${idx}-${md5(manifest)}" => manifest
    if trimspace(manifest) != "" && can(yamldecode(manifest))
  }

  yaml_body          = each.value
  server_side_apply = true
  force_conflicts   = true
}

module "aws_load_balancer_controller_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  version = "~> 6.0"
  name = "aws-load-balancer-controller"

  attach_load_balancer_controller_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["aws-load-balancer-controller:aws-load-balancer-controller"]
    }
  }
  depends_on = [kubectl_manifest.aws-load-balancer-controller_namespace]
}

resource "helm_release" "aws_load_balancer_controller" {
  name = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "3.5.0"
  namespace  = "aws-load-balancer-controller"

  values = [
    templatefile("${path.module}/values-aws-load-balancer-controller.yaml", {
      vpcId      = var.vpcId
      clusterName = var.cluster_name
      roleArn     = module.aws_load_balancer_controller_irsa_role.arn
    })
  ]
  depends_on = [
    kubectl_manifest.aws-load-balancer-controller_namespace,
    kubectl_manifest.aws_load_balancer_controller_gateway_crds,
    module.aws_load_balancer_controller_irsa_role
  ]

  # set {
  #   name  = "vpcId"
  #   value = var.vpcId
  # }

  # set {
  #   name  = "replicaCount"
  #   value = 1
  # }

  # set {
  #   name  = "clusterName"
  #   value = var.cluster_name
  # }

  # set {
  #   name  = "serviceAccount.name"
  #   value = "aws-load-balancer-controller"
  # }

  # set {
  #   name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
  #   value = module.aws_load_balancer_controller_irsa_role.arn
  # }
}
