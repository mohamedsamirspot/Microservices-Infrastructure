skip = !read_terragrunt_config(find_in_parent_folders("env.hcl")).locals.enable_prometheus

terraform {
  source = "${find_in_parent_folders("k8s-tools")}/monitoring/prometheus"
}

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

# apply and destroy ordering
dependencies {
  paths = [
    "${get_terragrunt_dir()}/../../aws-eks",
    "${get_terragrunt_dir()}/../../karpenter"
  ]
}

dependency "eks" {
  config_path = "${get_terragrunt_dir()}/../../aws-eks"
    # Fix for run-all init
  mock_outputs = {
    cluster_name           = "eks-mock-cluster"
    cluster_endpoint       = "https://eks-mock-endpoint"
    cluster_certificate_authority_data = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURCVENDQWUyZ0F3SUJBZ0lJUUppa3IxaFhUdzB3RFFZSktvWklodmNOQVFFTEJRQXdGVEVUTUJFR0ExVUUKQXhNS2EzVmlaWEp1WlhSbGN6QWVGdzB5TlRFeE1qTXdPREF6TWpWYUZ3MHpOVEV4TWpFd09EQTRNalZhTUJVeApFekFSQmdOVkJBTVRDbXQxWW1WeWJtVjBaWE13Z2dFaU1BMEdDU3FHU0liM0RRRUJBUVVBQTRJQkR3QXdnZ0VLCkFvSUJBUUREb2RBSmlGbjhmb0lBWVpuTUNoYUNtYnNCT3l6QmZnRDJ1MGtrbzRqMFFFTnljOUNJa1VpT3ExQkcKT3ZESHIwTjB4RVhQaFV5N1BRb2poSlcwelVGRXNySzJ2eFR6TGdHQ0N2WlRiSVNYOXQxazZVSDVoOUh2V3BjTQoyTm9FSmtZSVArOTR4anFiQWEwa1JLcGxRd01sNS9oNmtIU2NGRHZDdFhvUUhmdml4aGJoTnJPSnIzVXYwZytOCkNteDVjQ1B3Wkw4RTNzUEd0K2taaFJwNVR4UzVzZXdNSllkMmVwMWloRDZsdWR5dGNUWlFnaHpIM0txUExReEwKZ3hUcHBJcEQvU2llSmRuM1ZJaFZaTmVOcUowQU95OE05WDFSSEZGZUdzRWFucnZ3YUtEMzdpdUV1c3c0Rjc5VgovNUN5cFc2M0xSdlNCQzBQb2FiNVlsTWhXTzVaQWdNQkFBR2pXVEJYTUE0R0ExVWREd0VCL3dRRUF3SUNwREFQCkJnTlZIUk1CQWY4RUJUQURBUUgvTUIwR0ExVWREZ1FXQkJSdC9RNXkwSmZYUFZ0M0FCZjVJU2hkV0xkSGdUQVYKQmdOVkhSRUVEakFNZ2dwcmRXSmxjbTVsZEdWek1BMEdDU3FHU0liM0RRRUJDd1VBQTRJQkFRQ1pzengxdWNXUApLNTh0OHZrNXVnSjNsd3VZYVFFTlRCY3I5TTBPZ2l5M0V4MzgzTGVpOXZ5VUd3MllZSldMR09qMTJsTTJFbHBVCnFlS0VWdjVON2FhaEVCVWZpRDRIQnk5WnEzM1FRWmpPaHdPUjIybWNzTFJ4T0xmMVZjM2ZtZ1U3RFVOemhRZWsKbmdGUUNLcUN2aWYwK0loeVBtOEpCeXV0QWw2ZnBoVzBOUzFXZHNuUVVYKzNyTEw5dEhGdFpFVGJiNnJueXFjZgpTVkVSWHR6SFErRFhOcWhHanExNFZTRVFDLzhhSFVCcG1ZOFV2WUNOR09HNjVBdFpPMWhGNEVnVzVQZURwcVErCkRTSm9zUkpZeVQrU2hET1FnbHR4ZmJSMUd0RGJoU1hvNmhVQjI4YzJ5QktEb3pyZlg0UVVScWxzRVFmSENSRDgKZWxYcUgwSitwTHRxCi0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K"
  }
}

dependency "karpenter" {
  config_path = "${get_terragrunt_dir()}/../../karpenter"
  skip_outputs = true
}

generate "provider-prometheus" {
  path      = "provider-prometheus.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF

provider "helm" {
  kubernetes {
    host                   = "${dependency.eks.outputs.cluster_endpoint}"
    cluster_ca_certificate = base64decode("${dependency.eks.outputs.cluster_certificate_authority_data}")
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", "${dependency.eks.outputs.cluster_name}"]
    }
  }
}
EOF
}
