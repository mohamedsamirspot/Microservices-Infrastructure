skip = !read_terragrunt_config(find_in_parent_folders("env.hcl")).locals.enable_network

terraform {
  source = "${find_in_parent_folders("aws-modules")}/aws-network"
}

# Without explicit include
#   Root config is applied
#   Locals are evaluated
#   But not exposed
# With explicit include + expose
#   Root config is applied
#   Locals are evaluated
#   And accessible
# So even you are not depening on the root.hcl locals, it is recommended to put the include block to all terragrunt.hcl files to avoid any unexpected behaviors in future.
include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

locals {
  account = read_terragrunt_config(find_in_parent_folders("account.hcl")).locals.account_alias
  env     = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals.env
}

inputs = {
  cluster_name = "${local.account}-${local.env}-eks"
  tags = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals.tags
}
