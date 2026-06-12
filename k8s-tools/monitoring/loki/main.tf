module "loki_s3" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.14.0"

  bucket        = var.bucket_name

  acl = "private"

  force_destroy = false

  # Block public access
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  tags = var.tags
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
      s3_bucket = module.loki_s3.bucket
      region    = var.aws_region
    })
  ]

  depends_on = [kubectl_manifest.monitoring_namespace]
}

output "loki_bucket" {
  value = module.loki_s3.bucket
}
