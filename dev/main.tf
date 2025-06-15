module "network" {
  source       = "./network"
  cluster_name = "${var.env}-${var.cluster_name}"
  tags = {
    env = var.env
  }
}

# module "eks" {
#   source                     = "./eks"
#   cluster_name               = var.cluster_name
#   vpc_id                     = module.network.vpc_id
#   subnet_ids                 = module.network.private_subnet_ids # Use private subnets for worker nodes
#   # control_plane_subnet_ids = module.network.public_subnet_ids   # Public subnets for the control plane
#   tags = {
#     env = var.env
#   }
# }



# module "efs" {
#   source                      = "./efs"
#   vpc_id                      = module.network.vpc_id 
#   private_subnets             = module.network.private_subnet_ids # Use private subnets for worker nodes
#   private_subnets_cidr_blocks = module.network.private_subnets_cidr_blocks
#   tags = {
#      env = var.env
#    }
# }