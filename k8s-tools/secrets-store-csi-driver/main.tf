resource "helm_release" "secrets-store-csi-driver" {
  name             = "secrets-store-csi-driver"
  repository       = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
  chart            = "secrets-store-csi-driver"
  version          = var.secrets-store-csi-driver_chart_version
  namespace        = "secrets-store-csi-driver"
  create_namespace = true
}

resource "helm_release" "secrets-store-csi-driver-provider-aws" {
  name             = "secrets-store-csi-driver-provider-aws"
  repository       = "https://aws.github.io/secrets-store-csi-driver-provider-aws"
  chart            = "secrets-store-csi-driver-provider-aws"
  version          = var.secrets-store-csi-driver-provider-aws_chart_version
  namespace        = "secrets-store-csi-driver"
  create_namespace = true
  depends_on = [ helm_release.secrets-store-csi-driver ]
}

# AWS IAM policy
resource "aws_iam_policy" "csi-eks-secrets-manager" {
  name        = "csi-eks-secrets-manager-${var.cluster_name}"
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
  depends_on = [ aws_iam_policy.csi-eks-secrets-manager ]
}

resource "aws_iam_role_policy_attachment" "csi-eks-secrets-manager_attach" {
  role       = aws_iam_role.csi-eks-secrets-manager_role.name
  policy_arn = aws_iam_policy.csi-eks-secrets-manager_policy.arn
  depends_on = [ aws_iam_policy.csi-eks-secrets-manager, aws_iam_role.csi-eks-secrets-manager_role ]
}

module "secrets_manager" {
  source = "terraform-aws-modules/secrets-manager/aws"

  # Secret
  name             = "microservices-secrets"
  recovery_window_in_days = 30

  # Policy
  create_policy       = false
  block_public_policy = true

  tags = var.tags
}
