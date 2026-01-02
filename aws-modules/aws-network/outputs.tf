output "vpc_id" {
  value = module.vpc.vpc_id
}

output "private_subnet_ids" {
  value = module.vpc.private_subnets
}

output "private_subnets_cidr_blocks" {
  value = module.vpc.private_subnets_cidr_blocks
}

output "vpc_cidr_block" {
  value = module.vpc.vpc_cidr_block
}

output "database_subnet_group_name" {
  value = module.vpc.database_subnet_group_name
}

# output "public_subnet_ids" {
#   value = module.vpc.public_subnets
# }
