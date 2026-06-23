module "loki_s3" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.14.1"

  bucket        = var.bucket_name

  # Keep ACLs disabled for S3 Object Ownership = BucketOwnerEnforced.
  control_object_ownership = true
  object_ownership         = "BucketOwnerEnforced"

  force_destroy = true

  # Block public access
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  tags = var.tags
}

resource "kubectl_manifest" "monitoring_namespace" {
  yaml_body = <<-YAML
apiVersion: v1
kind: Namespace
metadata:
  name: monitoring
YAML
}

# IAM policy for Loki object storage access via IRSA.
resource "aws_iam_policy" "loki_irsa_policy" {
  name        = "loki-irsa-policy-${var.cluster_name}"
  description = "Policy for Loki pods to access S3 bucket using IRSA"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = module.loki_s3.s3_bucket_arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:AbortMultipartUpload",
          "s3:ListBucketMultipartUploads",
          "s3:ListMultipartUploadParts"
        ]
        Resource = "${module.loki_s3.s3_bucket_arn}/*"
      }
    ]
  })
}

# IAM role bound to the Loki service account in monitoring namespace.
resource "aws_iam_role" "loki_irsa_role" {
  name = "loki-irsa-role-${var.cluster_name}"

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
            "${replace(var.cluster_oidc_provider_url, "https://", "")}:sub" = "system:serviceaccount:monitoring:loki-sa"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "loki_irsa_attach" {
  role       = aws_iam_role.loki_irsa_role.name
  policy_arn = aws_iam_policy.loki_irsa_policy.arn
}

resource "kubectl_manifest" "loki_service_account" {
  yaml_body = <<-YAML
apiVersion: v1
kind: ServiceAccount
metadata:
  name: loki-sa
  namespace: monitoring
  annotations:
    eks.amazonaws.com/role-arn: "${aws_iam_role.loki_irsa_role.arn}"
YAML

  depends_on = [
    kubectl_manifest.monitoring_namespace,
    aws_iam_role_policy_attachment.loki_irsa_attach
  ]
}

resource "helm_release" "loki" {
  name             = "loki"
  repository       = "https://grafana-community.github.io/helm-charts"
  chart            = "loki"
  version          = var.loki_chart_version != "" ? var.loki_chart_version : null
  namespace        = "monitoring"
  create_namespace = true

  values = [
    templatefile("${path.module}/values-loki.yaml", {
      s3_bucket                 = module.loki_s3.s3_bucket_id
      region                    = var.aws_region
      loki_service_account_name = "loki-sa"
    })
  ]

  depends_on = [kubectl_manifest.loki_service_account]
}

output "loki_bucket" {
  value = module.loki_s3.s3_bucket_id
}
