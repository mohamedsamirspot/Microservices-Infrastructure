resource "kubectl_manifest" "aws-load-balancer-controller_namespace" {
  yaml_body = <<-YAML
apiVersion: v1
kind: Namespace
metadata:
  name: aws-load-balancer-controller
YAML
}

module "aws_load_balancer_controller_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  version = "6.2.3"
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
  version    = "1.17.1"
  namespace  = "aws-load-balancer-controller"

  values = [
    templatefile("${path.module}/values-alb-ingress-controller.yaml", {
      vpcId      = var.vpcId
      clusterName = var.cluster_name
      roleArn     = module.aws_load_balancer_controller_irsa_role.arn
    })
  ]
  depends_on = [kubectl_manifest.aws-load-balancer-controller_namespace, module.aws_load_balancer_controller_irsa_role]

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
