resource "aws_eip" "nat" {
  count = 1
  domain = "vpc"
  tags = {
    Name = "${var.tags["env"]}-nat-eip"
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.21.0"

  name                 = "${var.tags["env"]}-${var.name}"
  cidr                 = var.cidr
  azs                  = var.azs
  private_subnets      = var.private_subnets
  public_subnets       = var.public_subnets

  enable_nat_gateway   = true
  single_nat_gateway   = true # Single NAT Gateway to reduce costs
  reuse_nat_ips        = true                    # <= Skip creation of EIPs for the NAT Gateways
  external_nat_ip_ids  = "${aws_eip.nat.*.id}"   # <= IPs specified here as input to the module
  # Note that in the example we allocate 3 IPs because we will be provisioning 3 NAT Gateways (due to single_nat_gateway = false and having 3 subnets). If, on the other hand, single_nat_gateway = true, then aws_eip.nat would only need to allocate 1 IP. Passing the IPs into the module is done by setting two variables reuse_nat_ips = true and external_nat_ip_ids = "${aws_eip.nat.*.id}".


  # The VPC must have DNS hostname and DNS resolution support. Otherwise, nodes can’t register to your cluster.
  enable_dns_support   = true
  enable_dns_hostnames = true


  tags = var.tags
  


  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1  # to the aws ingress controller public load balancers to be created
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1 # to the aws ingress controller internal load balancers to be created
    # Tags subnets for Karpenter auto-discovery
    "karpenter.sh/discovery" = var.cluster_name
  }
}


