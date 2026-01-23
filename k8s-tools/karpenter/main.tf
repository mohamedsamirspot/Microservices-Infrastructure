###############################################################################
# Karpenter terraform module
###############################################################################

module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 21.0"

  cluster_name          = var.cluster_name
  create_pod_identity_association = true
  namespace           = "karpenter"
  # Used to attach additional IAM policies to the Karpenter node IAM role
  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  tags = var.tags
}


# Fetch the recommended EKS-optimized AL2 AMI for your cluster version
data "aws_ssm_parameter" "eks_ami" {
  name = "/aws/service/eks/optimized-ami/${var.kubernetes_version}/amazon-linux-2023/x86_64/standard/recommended/image_id"
}

###############################################################################
# Karpenter Helm
###############################################################################

resource "helm_release" "karpenter" {
  name                = "karpenter"
  repository          = "oci://public.ecr.aws/karpenter"
  chart               = "karpenter"
  version             = "1.8.6"
  namespace           = "karpenter"
  create_namespace    = true
  wait                = false

  depends_on = [module.karpenter]

  values = [
    <<-EOT
    nodeSelector:
      karpenter.sh/controller: 'true'
    dnsPolicy: Default
    settings:
      clusterName: ${var.cluster_name}
      clusterEndpoint: ${var.cluster_endpoint}
      interruptionQueue: ${module.karpenter.queue_name}
    webhook:
      enabled: false
    controller:
      resources:
        requests:
          cpu: "0.5"
          memory: "0.5Gi"
        limits:
          cpu: "0.5"
          memory: "0.5Gi"
    EOT
  ]
}
# recommended minimum "1" for cpu and "1Gi" for memory per each karpenter controller replica which is 2 by default

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
            karpenter.sh/discovery: ${var.cluster_name}
      securityGroupSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${var.cluster_name}
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
        karpenter.sh/discovery: ${var.cluster_name}
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
        cpu: "6"
        memory: "8Gi"
      disruption:
        consolidationPolicy: WhenEmpty
        consolidateAfter: 30s
  YAML

  depends_on = [
    kubectl_manifest.karpenter_node_class
  ]
}
