# References:
#   https://www.youtube.com/watch?v=EonWeoFPpvM
#   https://external-secrets.io/latest/getting-started/quickstart/
#   https://github.com/external-secrets/external-secrets/tree/main/deploy/charts/external-secrets

resource "helm_release" "external-secrets-operator" {
  name             = "external-secrets-operator"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  version          = var.external-secrets-operator_chart_version
  namespace        = "external-secrets-operator"
  create_namespace = true
}

#------------------------------------------To give aws access to pod uisng IRSA--------------------------------------------------------------
# AWS IAM policy
resource "aws_iam_policy" "external-secrets-operator_policy" {
  name        = "external-secrets-operator-policy-${var.cluster_name}"
  description = "Policy for the external-secrets-operator to access AWS resources (secrets from secrets manager) uisng IRSA"
  policy = jsonencode({

    "Version": "2012-10-17",
    "Statement": [ {
        "Effect": "Allow",
        "Action": ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret", "secretsmanager:GetResourcePolicy", "secretsmanager:ListSecretVersionIds"],
        "Resource": ["arn:*:secretsmanager:*:*:secret:*"]
    } ]
  })
  tags = var.tags
  depends_on = [ helm_release.external-secrets-operator ]
}

# AWS IAM role for the service account (IRSA)
resource "aws_iam_role" "external-secrets-operator_role" {
  name = "external-secrets-operator-role-${var.cluster_name}"

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
          StringLike = {
            "${replace(var.cluster_oidc_provider_url, "https://", "")}:sub" = [
              "system:serviceaccount:external-secrets-operator:external-secrets-operator-sa"
            ]
          }
          StringEquals = {
            "${replace(var.cluster_oidc_provider_url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
  tags       = var.tags
  depends_on = [aws_iam_policy.external-secrets-operator_policy]
}

resource "aws_iam_role_policy_attachment" "external-secrets-operator_attach" {
  role       = aws_iam_role.external-secrets-operator_role.name
  policy_arn = aws_iam_policy.external-secrets-operator_policy.arn
  depends_on = [ aws_iam_policy.external-secrets-operator_policy, aws_iam_role.external-secrets-operator_role ]
}

# Kubernetes ServiceAccount annotated with IAM role "this will be used for the whole cluster"
resource "kubectl_manifest" "external-secrets-operator-sa" {
  yaml_body = <<-YAML
apiVersion: v1
kind: ServiceAccount
metadata:
  name: external-secrets-operator-sa
  namespace: external-secrets-operator
  annotations:
    eks.amazonaws.com/role-arn: "${aws_iam_role.external-secrets-operator_role.arn}"
YAML
  depends_on = [aws_iam_role.external-secrets-operator_role]
}

resource "kubectl_manifest" "ClusterSecretStore" {
  yaml_body = <<-YAML
apiVersion: external-secrets.io/v1
kind: ClusterSecretStore
metadata:
  name: clustersecretstore
spec:
  provider:
    aws:
      service: SecretsManager
      region: "${var.aws_region}"
      auth:
        jwt:
          serviceAccountRef:
            name: external-secrets-operator-sa
            namespace: external-secrets-operator
YAML
  depends_on = [aws_iam_role.external-secrets-operator_role]
}

#--------------------------------------------------------------------------------------------------------
# Example secret
module "secrets_manager" {
  source = "terraform-aws-modules/secrets-manager/aws"
  version = "2.1.0"

  # Secret
  name             = "microservices-secret-2"
  recovery_window_in_days = 0

  ignore_secret_changes = true

  # Policy
  create_policy       = false
  block_public_policy = true

  # This creates an "empty" secret
  secret_string            = jsonencode({})

  tags = var.tags
}
