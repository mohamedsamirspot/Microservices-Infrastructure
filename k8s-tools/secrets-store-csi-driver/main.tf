# References: 
#   https://www.youtube.com/watch?v=MTnQW9MxnRI
#   https://secrets-store-csi-driver.sigs.k8s.io/getting-started/installation.html
#   https://github.com/aws/secrets-store-csi-driver-provider-aws

resource "helm_release" "secrets-store-csi-driver" {
  name             = "secrets-store-csi-driver"
  repository       = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
  chart            = "secrets-store-csi-driver"
  version          = var.secrets-store-csi-driver_chart_version
  namespace        = "secrets-store-csi-driver"
  create_namespace = true
  values = [
    file("${path.module}/values-secrets-store-csi-driver.yaml")
  ]
}

resource "helm_release" "secrets-store-csi-driver-provider-aws" {
  name             = "secrets-store-csi-driver-provider-aws"
  repository       = "https://aws.github.io/secrets-store-csi-driver-provider-aws"
  chart            = "secrets-store-csi-driver-provider-aws"
  version          = var.secrets-store-csi-driver-provider-aws_chart_version
  namespace        = "secrets-store-csi-driver"
  create_namespace = true
  values = [
    yamlencode({
      secrets-store-csi-driver = {
        install = false
      }
    })
  ]
  depends_on = [ helm_release.secrets-store-csi-driver ]
}

# AWS IAM policy
resource "aws_iam_policy" "csi-eks-secrets-manager_policy" {
  name        = "csi-eks-secrets-manager-policy-${var.cluster_name}"
  description = "Policy for the secrets-store-csi-driver-provider-aws to access AWS resources (secrets from secrets manager) uisng IRSA"
  policy = jsonencode({

    "Version": "2012-10-17",
    "Statement": [ {
        "Effect": "Allow",
        "Action": ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"],
        "Resource": ["arn:*:secretsmanager:*:*:secret:*"]
    } ]
  })
  tags = var.tags
  depends_on = [ helm_release.secrets-store-csi-driver-provider-aws ]
}

# AWS IAM role for the service account (IRSA)
resource "aws_iam_role" "csi-eks-secrets-manager_role" {
  name = "csi-eks-secrets-manager-role-${var.cluster_name}"

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
            "${replace(var.cluster_oidc_provider_url, "https://", "")}:sub" = "system:serviceaccount:secrets-store-csi-driver:csi-eks-secrets-manager-sa"
          }
        }
      }
    ]
  })
  tags = var.tags
  depends_on = [ aws_iam_policy.csi-eks-secrets-manager_policy ]
}

resource "aws_iam_role_policy_attachment" "csi-eks-secrets-manager_attach" {
  role       = aws_iam_role.csi-eks-secrets-manager_role.name
  policy_arn = aws_iam_policy.csi-eks-secrets-manager_policy.arn
  depends_on = [ aws_iam_policy.csi-eks-secrets-manager_policy, aws_iam_role.csi-eks-secrets-manager_role ]
}

# Kubernetes ServiceAccount annotated with IAM role
resource "kubectl_manifest" "csi-eks-secrets-manager-sa" {
  yaml_body = <<-YAML
apiVersion: v1
kind: ServiceAccount
metadata:
  name: csi-eks-secrets-manager-sa
  namespace: secrets-store-csi-driver
  annotations:
    eks.amazonaws.com/role-arn: "${aws_iam_role.csi-eks-secrets-manager_role.arn}"
YAML
  depends_on = [aws_iam_role.csi-eks-secrets-manager_role]
}

module "secrets_manager" {
  source = "terraform-aws-modules/secrets-manager/aws"

  # Secret
  name             = "microservices-secret"
  recovery_window_in_days = 30

  ignore_secret_changes = true

  # Policy
  create_policy       = false
  block_public_policy = true
  
  # This creates an "empty" secret
  secret_string            = jsonencode({})

  tags = var.tags
}
