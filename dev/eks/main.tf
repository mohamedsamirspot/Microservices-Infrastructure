######################## this config will create 4 sgs and one nacl ##############################

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = "${var.tags["env"]}-${var.cluster_name}"
  cluster_version = "1.32"  # Specify the version of your EKS cluster
  # Use the outputs from the 'network' module

  # always recommended to put the worker nodes in private subnets and the control plane enis also in the private subnet (“no idea what is the difference if I put the control plane enis in private or public subnets as if you enabled the public access you can access the api in both cases with no difference”)
  vpc_id = var.vpc_id
  subnet_ids               = var.subnet_ids # Use private subnets for worker nodes
  control_plane_subnet_ids = var.subnet_ids   # private subnets for the control plane


  cluster_endpoint_public_access  = true # Controls whether the EKS control plane (API server) is accessible over the internet via a public endpoint. --> Even when the control plane resides in private subnets, AWS provides a way to access it externally via a managed public endpoint. 
  cluster_endpoint_private_access = true # Controls whether the EKS control plane (API server) is accessible only from within the VPC using its private IP address.
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs # Specifies the allowed CIDR ranges for accessing the EKS control plane public endpoint when cluster_endpoint_public_access is true. Default: If not set explicitly, AWS defaults this to allow access from 0.0.0.0/0 (i.e., from anywhere).



  cluster_addons = {
      coredns = { most_recent = true }
      eks-pod-identity-agent = { most_recent = true }
      kube-proxy = { most_recent = true }
      vpc-cni = { most_recent = true }
      aws-ebs-csi-driver = { most_recent = true }
      aws-efs-csi-driver = { most_recent = true }
      metrics-server = { most_recent = true } 
    }

  # EKS Managed Node Group(s)

  eks_managed_node_groups = {
    initial-node-group = {
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = var.instance_type

      min_size     = var.min_size
      max_size     = var.max_size
      desired_size = var.desired_size

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

    ############## if you are gonna use karpenter ################
      # taints = {
      #   # This Taint aims to keep just EKS Addons and Karpenter running on this MNG
      #   # The pods that do not tolerate this taint should run on nodes created by Karpenter
      #   addons = {
      #     key    = "CriticalAddonsOnly"
      #     value  = "true"
      #     effect = "NO_SCHEDULE"
      #   },
      # }
  }
  }

  # Enable logs
  cluster_enabled_log_types = ["audit","api","authenticator"]

  node_security_group_tags = {
    # NOTE - if creating multiple security groups with this module, only tag the
    # security group that Karpenter should utilize with the following tag
    # (i.e. - at most, only one security group should have this tag in your account)
    "karpenter.sh/discovery" = "${var.tags["env"]}-${var.cluster_name}"
  }

  # IAM roles for service accounts (IRSA)
  enable_irsa = true  # Enable IAM roles for service accounts


  # Cluster access entry
  # To add the current caller identity as an administrator
  enable_cluster_creator_admin_permissions = true
  # access_entries = {
    # you can use users or roles arns only no groups so you need to put more than one user or just put one role and make all the users you want to assume it so they can have access from one access entry only
    # mohamed-emary = {
    #   principal_arn     = "arn:aws:iam::104725311182:user/mohamed-emary"
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
    #   principal_arn     = "arn:aws:iam::104725311182:user/moataznaguib"
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
  # }
  
  tags = var.tags

}








############################# Karpenter  requirments ################################
terraform {
  required_version = ">= 1.11.0" # Keep the minimum version constraint

  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
  }
}


## must be us-east-1 for the ecr association whatever the real region of the eks is
provider "aws" {
    region = "us-east-1"
    alias  = "virginia"
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      # This requires the awscli to be installed locally where Terraform is executed
      args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    }
  }
}

provider "kubectl" {
  apply_retry_count      = 5
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  load_config_file       = false

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

###############################################################################
# Data Sources
###############################################################################
data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.virginia
}

###############################################################################
# Karpenter
###############################################################################
module "karpenter" {
  source = "terraform-aws-modules/eks/aws//modules/karpenter"

  cluster_name = module.eks.cluster_name

  enable_v1_permissions = true

  enable_pod_identity             = true
  create_pod_identity_association = true

  # Attach additional IAM policies to the Karpenter node IAM role
  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
}

###############################################################################
# Karpenter Helm
###############################################################################
resource "helm_release" "karpenter" {
  namespace  = "kube-system"
  name       = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = "1.4.0"
  wait       = false

  values = [
    <<-EOT
    serviceAccount:
      name: ${module.karpenter.service_account}
    settings:
      clusterName: ${module.eks.cluster_name}
      clusterEndpoint: ${module.eks.cluster_endpoint}
      interruptionQueue: ${module.karpenter.queue_name}
    EOT
  ]
}

# Fetch the recommended EKS-optimized AL2 AMI for your cluster version
data "aws_ssm_parameter" "eks_ami" {
  name = "/aws/service/eks/optimized-ami/${module.eks.cluster_version}/amazon-linux-2023/x86_64/standard/recommended/image_id"
}



###############################################################################
# Karpenter Kubectl
###############################################################################
resource "kubectl_manifest" "karpenter_node_class" {
  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1
    kind: EC2NodeClass
    metadata:
      name: default
    spec:
      amiFamily: AL2023
      role: ${module.karpenter.node_iam_role_name}
      subnetSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${module.eks.cluster_name}
      securityGroupSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${module.eks.cluster_name}
      amiSelectorTerms:
        - id: "${data.aws_ssm_parameter.eks_ami.value}"  # dynamically injected
      blockDeviceMappings:
        - deviceName: /dev/xvda
          ebs:
            volumeSize: 50Gi  # Specify the disk size here
            volumeType: gp3
            encrypted: true
            deleteOnTermination: true
      tags:
        karpenter.sh/discovery: ${module.eks.cluster_name}
  YAML

  depends_on = [
    helm_release.karpenter
  ]
}

resource "kubectl_manifest" "karpenter_node_pool" {
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1
    kind: NodePool
    metadata:
      name: default
    spec:
      template:
        spec:
          nodeClassRef:
            name: default  # Reference to the NodeClass or EC2NodeClass
            kind: EC2NodeClass
            group: karpenter.k8s.aws
          requirements:
            - key: "node.kubernetes.io/instance-type"
              operator: In
              values:
                - "t3.small"
                - "t3.medium"
                - "c5.large"
                - "c5.xlarge"
                - "c6i.large"
                - "m5.large"
                - "m6i.large"
            - key: "karpenter.sh/capacity-type"  # Capacity type (on-demand or spot)
              operator: In
              values: ["on-demand"]
            - key: "kubernetes.io/arch"  # Architecture (amd64 or arm64)
              operator: In
              values: ["amd64"]
            # - key: "karpenter.k8s.aws/instance-cpu"  # CPU constraint
            #   operator: Lt
            #   values: ["10"]
            # - key: "karpenter.k8s.aws/instance-memory"  # Memory constraint
            #   operator: Lt
            #   values: ["10240"]  # 10 GB in MB
      limits:
        cpu: "20"
        memory: "50Gi"
      disruption:
        consolidationPolicy: WhenEmpty
        consolidateAfter: 30s
  YAML

  depends_on = [
    kubectl_manifest.karpenter_node_class
  ]
}

