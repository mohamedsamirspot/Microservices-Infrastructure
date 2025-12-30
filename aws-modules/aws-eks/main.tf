######################## this config will create 4 sgs and one nacl ##############################

module "ebs_csi_driver_irsa" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  name = "ebs-csi"
  version = "~> 6.0"
  attach_ebs_csi_policy = true
  oidc_providers = {
    this = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
  tags = var.tags
}

module "efs_csi_driver_irsa" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  name = "efs-csi"
  version = "~> 6.0"
  attach_efs_csi_policy = true
  oidc_providers = {
    this = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:efs-csi-controller-sa"]
    }
  }
  tags = var.tags
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"
  name    = "${var.cluster_name}"
  kubernetes_version  =  var.kubernetes_version

  # Use the outputs from the 'network' module
  # always recommended to put the worker nodes in private subnets and the control plane enis also in the private subnet (“no idea what is the difference if I put the control plane enis in private or public subnets as if you enabled the public access you can access the api in both cases with no difference”)
  vpc_id = var.vpc_id
  subnet_ids               = var.subnet_ids # Use private subnets for worker nodes
  control_plane_subnet_ids = var.subnet_ids   # private subnets for the control plane

  iam_role_name           = "${var.cluster_name}-role"
  iam_role_use_name_prefix = false

  endpoint_public_access  = true # Controls whether the EKS control plane (API server) is accessible over the internet via a public endpoint. --> Even when the control plane resides in private subnets, AWS provides a way to access it externally via a managed public endpoint.
  endpoint_private_access = true # Controls whether the EKS control plane (API server) is accessible only from within the VPC using its private IP address.
  endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs # Specifies the allowed CIDR ranges for accessing the EKS control plane public endpoint when cluster_endpoint_public_access is true. Default: If not set explicitly, AWS defaults this to allow access from 0.0.0.0/0 (i.e., from anywhere).


  addons = {
    # Automatically picks the version that matches the cluster version
    # before_compute = true --> means before node group creation
    coredns = {resolve_conflicts_on_update = "PRESERVE"}
    kube-proxy = {resolve_conflicts_on_update = "PRESERVE"}
    vpc-cni = {resolve_conflicts_on_update = "PRESERVE", before_compute = true ,resolve_conflicts_on_create = "OVERWRITE"}
    aws-ebs-csi-driver = {resolve_conflicts_on_update = "PRESERVE" , service_account_role_arn = module.ebs_csi_driver_irsa.arn}
    aws-efs-csi-driver = {resolve_conflicts_on_update = "PRESERVE" , service_account_role_arn = module.efs_csi_driver_irsa.arn}
    eks-pod-identity-agent = {resolve_conflicts_on_update = "PRESERVE", before_compute = true}
    metrics-server = {
      resolve_conflicts_on_update = "PRESERVE"
      configuration_values = jsonencode({
        containerPort = 4443
      })
    }
  }



  # EKS Managed Node Group(s)

  eks_managed_node_groups = {
    bootstrapping-node-group = {
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      name          = "${var.cluster_name}-bootstrapping-node-group"
      node_group_name_prefix = false
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = var.instance_type
      iam_role_name           = "${var.cluster_name}-node-group-role"
      iam_role_use_name_prefix = false

      min_size     = var.min_size
      max_size     = var.max_size
      desired_size = var.desired_size

      labels = {
        # Used to ensure Karpenter runs on nodes that it does not manage (the node group created by this module)
        "karpenter.sh/controller" = "true"
      }
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 50
            volume_type           = "gp3"
            iops                  = 3000
            throughput            = 125
            encrypted             = true
            delete_on_termination = true
          }
        }
      }

    ############################################### if you are gonna use karpenter ###############################################
      taints = {
          # This Taint aims to keep just EKS Addons and Karpenter running on this MNG
          # The pods that do not tolerate this taint should run on nodes created by Karpenter
          addons = {
            key    = "CriticalAddonsOnly"
            value  = "true"
            effect = "NO_SCHEDULE"
          },
      }
    }
  }

  # Enable logs
  enabled_log_types = ["audit","api","authenticator"]

  node_security_group_tags = {
    # NOTE - if creating multiple security groups with this module, only tag the
    # security group that Karpenter should utilize with the following tag
    # (i.e. - at most, only one security group should have this tag in your account)
    "karpenter.sh/discovery" = "${var.cluster_name}"
  }

  # IAM roles for service accounts (IRSA)
  enable_irsa = true  # Enable IAM roles for service accounts


  # Cluster access entry
  # To add the current caller identity as an administrator
  enable_cluster_creator_admin_permissions = true
  access_entries = {
    # you can use users or roles arns only no groups so you need to put more than one user or just put one role and make all the users you want to assume it so they can have access from one access entry only
    # mohamed-emary = {
    #   principal_arn     = "arn:aws:iam::948763340657:user/spot"
    #   policy_associations = {
    #     example = {
    #       policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
    #       access_scope = {
    #             type = "cluster"
    #       }
    #     }
    #   }
    # }
    # moataznaguib = {
    #   principal_arn     = "arn:aws:iam::948763340657:user/moataznaguib"
    #   policy_associations = {
    #     example = {
    #       policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
    #       access_scope = {
    #             type = "cluster"
    #       }
    #     }
    #   }
    # }
    # admins = {
    #   principal_arn     = var.principal_arn
    #   policy_associations = {
    #     example = {
    #       policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
    #       access_scope = {
    #             type = "cluster"
    #       }
    #     }
    #   }
    # }
  }

  tags = var.tags

  # [!CAUTION] Due to the current EKS Auto Mode API, to disable EKS Auto Mode you will have to explicity set:
  compute_config = {
    enabled = false
  }
}
