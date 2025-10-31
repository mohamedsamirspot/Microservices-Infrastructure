######################## this config will create one sg ##############################

locals {
  # region = "eu-east-1"
  # name   = "ex-${basename(path.cwd)}"

  # 0,2 if they are 2 az and 0,3 if they are 3 azs
  azs = slice(data.aws_availability_zones.available.names, 0, 2)

  # tags = {
  #   Name       = local.name
  #   Example    = local.name
  #   Repository = "https://github.com/terraform-aws-modules/terraform-aws-efs"
  # }
}

data "aws_availability_zones" "available" {}
data "aws_caller_identity" "current" {}

module "efs" {
  source = "terraform-aws-modules/efs/aws"

  # File system
  name           = "${var.tags["env"]}-${var.name}"
  # creation_token = local.name
  encrypted      = true
  # kms_key_arn    = module.kms.key_arn

  # performance_mode = "maxIO"
  # NB! PROVISIONED TROUGHPUT MODE WITH 256 MIBPS IS EXPENSIVE ~$1500/month
  # throughput_mode                 = "provisioned"
  # provisioned_throughput_in_mibps = 256

  # lifecycle_policy = {
  #   transition_to_ia                    = "AFTER_30_DAYS"
  #   transition_to_primary_storage_class = "AFTER_1_ACCESS"
  # }

  # File system policy (like in oman if you remember this is in case you want a specific ec2 roles for example to have the access to the efs (extra layer of security like not having the network access but also iam access))
  # attach_policy                      = true
  # bypass_policy_lockout_safety_check = false
  # policy_statements = [
  #   {
  #     sid     = "Example"
  #     actions = ["elasticfilesystem:ClientMount"]
  #     principals = [
  #       {
  #         type        = "AWS"
  #         identifiers = [data.aws_caller_identity.current.arn]
  #       }
  #     ]
  #   }
  # ]

  # Mount targets / security group
  mount_targets              = { for k, v in zipmap(local.azs, var.private_subnets) : k => { subnet_id = v } }
  security_group_description = "EFS security group"
  security_group_vpc_id      = var.vpc_id # The VPC ID where the security group will be created
  security_group_rules = {
    vpc = {
      # relying on the defaults provdied for EFS/NFS (2049/TCP + ingress)
      description = "NFS ingress from VPC private subnets"
      cidr_blocks = var.private_subnets_cidr_blocks
      # The rule allows ingress (inbound) traffic on port 2049 (NFS) from the provided private subnet CIDR blocks.
      # Prevents Public Access:
      #   Only resources within the specified private subnet CIDR ranges can access the EFS mount targets.
      #   This ensures the EFS is not exposed to external or unauthorized traffic.
    }
  }
  tags = var.tags

  # Access point(s)
  # access_points = {
  #   posix_example = {
  #     name = "posix-example"
  #     posix_user = {
  #       gid            = 1001
  #       uid            = 1001
  #       secondary_gids = [1002]
  #     }

  #     tags = {
  #       Additionl = "yes"
  #     }
  #   }
  #   root_example = {
  #     root_directory = {
  #       path = "/example"
  #       creation_info = {
  #         owner_gid   = 1001
  #         owner_uid   = 1001
  #         permissions = "755"
  #       }
  #     }
  #   }
  # }

  # Backup policy
  # enable_backup_policy = true

  # Replication configuration
  # create_replication_configuration = true
  # replication_configuration_destination = {
  #   region = "eu-west-2"
  # }
}