######################## this config will create one sg ##############################

data "aws_availability_zones" "available" {}
locals {
  # 0,2 if they are 2 az and 0,3 if they are 3 azs
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)
  efs_directories = [
    "nginx",
    "sonarqube",
  ]
}

module "efs" {
  source = "terraform-aws-modules/efs/aws"
  version = "~> 2.0.0"
  name           = "${var.name}"
  # creation_token = "example-token"
  encrypted      = true
  # kms_key_arn    = "arn:aws:kms:eu-west-1:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab"

  # performance_mode                = "maxIO"
  # NB! PROVISIONED TROUGHPUT MODE WITH 256 MIBPS IS EXPENSIVE ~$1500/month
  # throughput_mode                 = "provisioned"
  # provisioned_throughput_in_mibps = 256

  # lifecycle_policy = {
  #   transition_to_ia = "AFTER_30_DAYS"
  # }

  # File system policy (like in oman if you remember this is in case you want a specific ec2 roles for example to have the access to the efs (extra layer of security like not having the network access only but also iam access))
  # attach_policy                      = true
  # bypass_policy_lockout_safety_check = false
  # policy_statements = [
  #   {
  #     sid     = "Example"
  #     actions = ["elasticfilesystem:ClientMount"]
  #     principals = [
  #       {
  #         type        = "AWS"
  #         identifiers = ["arn:aws:iam::111122223333:role/EfsReadOnly"]
  #       }
  #     ]
  #   }
  # ]

  # Mount targets / security group
  mount_targets = { for k, v in zipmap(local.azs, var.private_subnets) : k => { subnet_id = v } }
  # mount_targets = {
  #   "eu-west-1a" = {
  #     subnet_id = "subnet-abcde012"
  #   }
  #   "eu-west-1b" = {
  #     subnet_id = "subnet-bcde012a"
  #   }
  #   "eu-west-1c" = {
  #     subnet_id = "subnet-fghi345a"
  #   }
  # }
  security_group_description = "EFS security group"
  security_group_vpc_id      = var.vpc_id # The VPC ID where the security group will be created

  security_group_ingress_rules = {
    for idx, cidr in var.private_subnets_cidr_blocks :
    "nfs_subnet_${idx}" => {
      description = "NFS ingress from private subnets ${cidr}"
      from_port   = 2049
      to_port     = 2049
      ip_protocol = "tcp"
      cidr_ipv4   = cidr
    }
  }


  access_points = {
    for dir in local.efs_directories : dir => {
      root_directory = {
        path = "/${dir}"
        creation_info = {
        owner_uid   = 1000
        owner_gid   = 1000
        permissions = "755"
        }
        tags = var.tags
      }
    }
  }

  # # Backup policy
  # enable_backup_policy = true

  # # Replication configuration
  # create_replication_configuration = true
  # replication_configuration_destination = {
  #   region = "eu-west-2"
  # }

  tags = var.tags
}
