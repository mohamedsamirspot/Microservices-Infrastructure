locals {
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket = "${local.account_vars.locals.account_id}-${local.region_vars.locals.aws_region}-${local.env_vars.locals.env}-terraform-state"
    key = "${basename(get_terragrunt_dir())}/terraform.tfstate"
    region         = "${local.region_vars.locals.aws_region}"
    encrypt        = true
    use_lockfile = true

    skip_bucket_versioning = false
    skip_bucket_ssencryption = false
    skip_bucket_root_access = false
    skip_bucket_enforced_tls = false
    disable_bucket_update = false
  }
}

generate "terraform_version" {
  path      = "terraform-version.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = ">= 1.11.0" # Keep the minimum version constraint of terraform itself
}
EOF
}
