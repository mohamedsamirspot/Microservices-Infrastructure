# ARC = community-driven, flexible, Kubernetes-based autoscaling.
# GHA Runner Scale Sets = GitHub-native, centralized autoscaling, modern, recommended. (we are using this one)

resource "kubectl_manifest" "gha-runner_namespace" {
  yaml_body = <<-YAML
apiVersion: v1
kind: Namespace
metadata:
  name: gha-runner
YAML
}

#------------------------------------------To give aws access to pod uisng IRSA--------------------------------------------------------------
# IAM policy
resource "aws_iam_policy" "gha_runner_policy" {
  name        = "gha-runner-policy-${var.cluster_name}"
  description = "Policy for GitHub Actions runners to access AWS resources uisng IRSA"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM role for the service account (IRSA)
resource "aws_iam_role" "gha_runner_role" {
  name = "gha-runner-role-${var.cluster_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(var.cluster_oidc_provider_url, "https://", "")}:sub" = "system:serviceaccount:gha-runner:gha-runner-sa"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "gha_runner_attach" {
  role       = aws_iam_role.gha_runner_role.name
  policy_arn = aws_iam_policy.gha_runner_policy.arn
}

# Kubernetes ServiceAccount annotated with IAM role
resource "kubectl_manifest" "gha_runner_sa" {
  yaml_body = <<-YAML
apiVersion: v1
kind: ServiceAccount
metadata:
  name: gha-runner-sa
  namespace: gha-runner
  annotations:
    eks.amazonaws.com/role-arn: "${aws_iam_role.gha_runner_role.arn}"
YAML
  depends_on = [kubectl_manifest.gha-runner_namespace]
}

#----------------------------------------To create github runners dynamically using githup app-----------------------------------------------------------
# Reference: https://medium.com/@bhrth.dsra1/deploy-gha-self-hosted-runners-on-aws-eks-with-terraform-and-helm-6624815738b6 and ask chatgpt about the github app creation steps for your case
data "aws_secretsmanager_secret_version" "github_privatekey" {
  secret_id = "terraform/github-app-privatekey"
}

resource "kubectl_manifest" "gha_runner_secret" {
  yaml_body = <<-YAML
apiVersion: v1
kind: Secret
metadata:
  name: gha-runner-secret
  namespace: gha-runner
type: Opaque
data:
  github_app_id: "${base64encode(var.github_app_id)}"
  github_app_installation_id: "${base64encode(var.github_app_installation_id)}"
  github_app_private_key: "${base64encode(
    replace(
      data.aws_secretsmanager_secret_version.github_privatekey.secret_string,
      "\r",
      ""
    )
  )}"
YAML
  depends_on = [kubectl_manifest.gha-runner_namespace]
}
# github_app_private_key: "${base64encode(file("${path.module}/samirspot-gha-runner.2025-11-18.private-key.pem"))}"

resource "helm_release" "gha-runner-scale-set-controller" {
  name       = "gha-runner-scale-set-controller"
  namespace  = "gha-runner"
  chart      = "gha-runner-scale-set-controller"
  repository = "oci://ghcr.io/actions/actions-runner-controller-charts"
  version    = "0.14.0"
  values = [
    file("${path.module}/values-scale-set-controller.yaml")
  ]
  depends_on = [ kubectl_manifest.gha-runner_namespace ]
}


resource "helm_release" "gha_runner_scale_set" {
  for_each  = toset(var.runner_sizes)

  name       = "gha-runner-scale-set-${each.key}"
  namespace  = "gha-runner"
  chart      = "gha-runner-scale-set"
  repository = "oci://ghcr.io/actions/actions-runner-controller-charts"
  version    = "0.13.1"

  # Optional: if you have a default values.yaml for all sizes
  values = [file("${path.module}/values-scale-set-${each.key}.yaml")]

  depends_on = [
    kubectl_manifest.gha-runner_namespace,
    kubectl_manifest.gha_runner_secret,
    helm_release.gha-runner-scale-set-controller
  ]
}
