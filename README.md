# Notes
## Just to add a new env just copy one of the directories and make sure to make change the following 2 env name variables
- ~/variables.tf --> change the env value
```bash
  backend "s3" {
    bucket       = "terraform-state-multi-env-spot"
    key          = "prod/eks-cluster/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
```
- ~/provider.tf --> backend s3 key env name
```bash
variable "env" {
  type        = string
  default     = "prod"
}
```
## The push and commits pipelines are disabled so you need to run the pipeline manually and pass the env variable each time with the right value
![Image Description](screenshots/1.png)
