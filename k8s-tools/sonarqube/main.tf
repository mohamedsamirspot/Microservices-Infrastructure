# https://artifacthub.io/packages/helm/sonarqube/sonarqube
# https://github.com/SonarSource/helm-chart-sonarqube/tree/master/charts/sonarqube
#---------------------------------- RDS Database Module ----------------------------------
module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "postgresql-db-sg"
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
  version = "7.0.1"

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

  storage_type         = "gp3"
  allocated_storage = 20
  max_allocated_storage = 100


  # NOTE: Do NOT use 'user' as the value for 'username' as it throws:
  # "Error creating DB Instance: InvalidParameterValue: MasterUsername
  # user cannot be used as it is a reserved word used by the engine"
  # Description: The DB name to create. If omitted, no database is created initially
  # So this will create aws secret with this username and a random password
  db_name  = "sonarqube"
  username = "sonarqube" # Username for the master DB user
  manage_master_user_password = true
  port     = 5432

  # publicly_accessible = true --> RDS gets both a private IP and a public IP
  # RDS always has a single endpoint (DNS name). --> That DNS name resolves to different IPs depending on where it’s queried from (the VPC or the internet).
  # Public subnet + publicly_accessible = true → RDS can be accessed from the internet (if SG/NACL allow).
  # Private subnet + publicly_accessible = true → RDS is NOT accessible from the internet.
  publicly_accessible = false

  db_subnet_group_name   = var.database_subnet_group_name
  vpc_security_group_ids = [module.security_group.security_group_id]

  skip_final_snapshot       = true

  tags = var.tags

  depends_on = [module.security_group]
}

#---------------------------------- SonarQube Helm Chart ----------------------------------
data "aws_secretsmanager_secret_version" "sonarpassword" {
  secret_id = module.db.db_instance_master_user_secret_arn
}

resource "helm_release" "sonarqube" {
  name             = "sonarqube"
  repository       = "https://SonarSource.github.io/helm-chart-sonarqube"
  chart            = "sonarqube"
  version          = var.sonarqube_chart_version
  namespace        = "sonarqube"
  create_namespace = true

  values = [
    templatefile("${path.module}/values-sonarqube.yaml", {
      sonarpassword      = jsondecode(data.aws_secretsmanager_secret_version.sonarpassword.secret_string)["password"]
      monitoringpasscode = jsondecode(data.aws_secretsmanager_secret_version.sonarpassword.secret_string)["password"]
      endpoint   = "jdbc:postgresql://${module.db.db_instance_endpoint}/sonarqube"
    })
  ]

  depends_on = [module.db]
  # Example of inline value override
  # set {
  #   name  = "server.service.type"
  #   value = "LoadBalancer"
  # }
}
