module "network" {
  source       = "../../modules/aws-network"
  cluster_name = "${var.env}-${var.cluster_name}"
  tags = {
    env = local.env
  }
}

module "eks" {
  source                     = "../../modules/aws-eks"
  cluster_name               = var.cluster_name
  vpc_id                     = module.network.vpc_id
  subnet_ids                 = module.network.private_subnet_ids # Use private subnets for worker nodes
  # control_plane_subnet_ids = module.network.public_subnet_ids   # Public subnets for the control plane
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs
  depends_on = [ module.network ]
  tags = {
    env = local.env
  }
}

module "karpenter" {
  source = "../../k8s-tools/karpenter"
  # The key change is moving provider configurations to the root module provider.tf and passing them explicitly to the Karpenter module, which is the modern approach in Terraform.
  cluster_name    = module.eks.cluster_name
  kubernetes_version = module.eks.cluster_version
  cluster_endpoint = module.eks.cluster_endpoint
  cluster_certificate_authority_data = module.eks.cluster_certificate_authority_data
  tags = {
    env = local.env
  }
}

module "alb-ingress-controller" {
  source = "../../k8s-tools/alb-ingress-controller"
  # The key change is moving provider configurations to the root module provider.tf and passing them explicitly to the alb-ingress-controller module, which is the modern approach in Terraform.
  vpcId             = module.network.vpc_id
  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_certificate_authority_data = module.eks.cluster_certificate_authority_data
  oidc_provider_arn = module.eks.oidc_provider_arn
  
  tags = {
    env = local.env
  }
}

# module "efs" {
#   source                      = "../../modules/aws-efs"
#   vpc_id                      = module.network.vpc_id 
#   private_subnets             = module.network.private_subnet_ids # Use private subnets for worker nodes
#   private_subnets_cidr_blocks = module.network.private_subnets_cidr_blocks
#   depends_on = [ module.network ]
#   tags = {
#      env = local.env
#    }
# }