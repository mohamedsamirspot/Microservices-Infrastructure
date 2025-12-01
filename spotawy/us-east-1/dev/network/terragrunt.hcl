terraform {
  source = "${find_in_parent_folders("modules")}/aws-network"
}

locals {
  account = include.root.locals.account_vars.locals.account_alias
  region  = include.root.locals.region_vars.locals.aws_region
  env     = include.root.locals.env_vars.locals.env
}


include "root" {
  path   = find_in_parent_folders()
  expose = true
}

inputs = {
 cluster_name = "${local.account}-${local.env}-eks"
 tags = include.root.locals.tags
}