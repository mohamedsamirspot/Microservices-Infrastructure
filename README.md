# Notes
## To add a new env just copy one of the directories and make sure to make change the following 2 env name variables
- `~/envs/${env}/provider.tf --> backend s3 key env name "${env}/eks-cluster/terraform.tfstate"`

```bash
  backend "s3" {
    bucket       = "terraform-state-multi-env-spot"
    key          = "prod/eks-cluster/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
```
## The push and commits pipelines are disabled so you need to run the pipeline manually and pass the env variable each time with the right value
![Image Description](screenshots/1.png)


![Image Description](screenshots/2.png)

## Infrastructure Installation (Terraform)
Running the terraform manifests that will create the following components in aws (terraform will use my aws credentials from my local creds)
- vpc
- subnets
- eks cluster with karpenter (optional usage) restricted from my ip only