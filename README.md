# Infrastructure Installation (Terraform + Terragrunt)
These terraform components (modules and k8s-tools) can create the following so far:
![Image Description](screenshots/Diagram.jpg)
- AWS Modules
  - aws-network
  - aws-eks
  - aws-efs
- k8s-tools
  - alb-ingress-controller
  - argocd
  - argocd-image-updater
  - gha-runner
  - k8s-karpenter
  - stakater-reloader
# Notes
- This repo is authenticated with aws through OIDC Reference --> https://www.youtube.com/watch?v=Sdzd4N6L5Hg
- Push and commits pipelines are disabled so you need to run the pipeline manually and pass the env variable each time with the right value
  - Github Action
![Image Description](screenshots/3.png)
  - Gitlab-CI
![Image Description](screenshots/1.png)
![Image Description](screenshots/2.png)
