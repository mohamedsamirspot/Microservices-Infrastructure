# Shared provider configurations for Terragrunt units that explicitly include this file.
# Add provider blocks here only when their configuration is common across those units maybe for helm and kubectl also if you want to avoid repeating the same configuration in multiple Terragrunt units but that depends on the specific use case because maybe setting helm be different for each unit.
generate "aws-provider" {
  path      = "provider-aws.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "${read_terragrunt_config(find_in_parent_folders("region.hcl")).locals.aws_region}"
}
EOF
}