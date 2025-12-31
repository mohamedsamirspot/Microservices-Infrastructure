skip = !read_terragrunt_config(find_in_parent_folders("env.hcl")).locals.enable_aws_efs

terraform {
  source = "${find_in_parent_folders("aws-modules")}/aws-efs"
}

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

locals {
  account = read_terragrunt_config(find_in_parent_folders("account.hcl")).locals.account_id
  env     = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals.env
}

# apply and destroy ordering
dependencies {
  paths = [
    "${get_terragrunt_dir()}/../network"
  ]
}

dependency "vpc" {
  config_path = "${get_terragrunt_dir()}/../network"
    # Fix for run-all init
  mock_outputs = {
    vpc_id                = "vpc-mock"
    private_subnet_ids    = ["subnet-mock1", "subnet-mock2"]
    private_subnets_cidr_blocks = ["10.0.1.0/24", "10.0.2.0/24"]
  }
}

inputs = {
  name                                 = "${local.account}-${local.env}-efs"
  vpc_id                               = dependency.vpc.outputs.vpc_id
  private_subnets                      = dependency.vpc.outputs.private_subnet_ids
  private_subnets_cidr_blocks          = dependency.vpc.outputs.private_subnets_cidr_blocks
  tags                                 = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals.tags
}
