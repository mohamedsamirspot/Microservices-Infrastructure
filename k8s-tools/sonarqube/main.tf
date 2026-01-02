#---------------------------------- RDS Database Module ----------------------------------

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = postgresql-db-sg
  vpc_id      = var.vpc_id

  # ingress
  ingress_with_cidr_blocks = [
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      description = "PostgreSQL access from within VPC"
      cidr_blocks = var.vpc_cidr_block
    },
  ]

  tags = var.tags
}

module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "7.0.0"

  identifier                     = "sonarqube-postgresql-db"
  instance_use_identifier_prefix = true

  create_db_option_group    = false
  create_db_parameter_group = false

  # All available versions: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html#PostgreSQL.Concepts
  engine               = "postgres"
  engine_version       = "17"
  family               = "postgres17" # DB parameter group
  major_engine_version = "17"         # DB option group
  instance_class       = "db.t3.medium"

  allocated_storage = 20
  max_allocated_storage = 100

  manage_master_user_password = true

  # NOTE: Do NOT use 'user' as the value for 'username' as it throws:
  # "Error creating DB Instance: InvalidParameterValue: MasterUsername
  # user cannot be used as it is a reserved word used by the engine"
  # Description: The DB name to create. If omitted, no database is created initially
  db_name  = "sonarqube"
  username = "sonarqube"
  port     = 5432

  db_subnet_group_name   = var.database_subnet_group_name
  vpc_security_group_ids = [module.security_group.security_group_id]

  tags = var.tags

  depends_on = [module.security_group]
}

#---------------------------------- SonarQube Helm Chart ----------------------------------
# data "aws_secretsmanager_secret_version" "monitoring_passcode" {
#   secret_id = "terraform/github-token"
# }

# resource "kubectl_manifest" "monitoring_passcode" {
#   yaml_body = <<-YAML
# apiVersion: v1
# kind: Secret
# metadata:
#   name: monitoringpasscode
#   namespace: sonarqube
# type: Opaque
# data:
#   pass-key: "${base64encode(jsondecode(data.aws_secretsmanager_secret_version.monitoring_passcode.secret_string)["github-token"])}"
# YAML
#   depends_on = [helm_release.sonarqube]
# }

# resource "helm_release" "sonarqube" {
#   name             = "sonarqube"
#   repository       = "https://SonarSource.github.io/helm-chart-sonarqube"
#   chart            = "sonarqube"
#   version          = var.sonarqube_chart_version
#   namespace        = "sonarqube"
#   create_namespace = true

#   values = [
#     file("${path.module}/values-sonarqube.yaml")
#   ]

#   depends_on = [module.db]
#   # Example of inline value override
#   # set {
#   #   name  = "server.service.type"
#   #   value = "LoadBalancer"
#   # }
# }
