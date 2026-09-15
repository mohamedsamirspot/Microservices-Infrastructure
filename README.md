# Infrastructure Installation (Terraform + Terragrunt)
These terraform components (modules and k8s-tools) can create the following so far:
![Image Description](screenshots/Diagram.jpg)
- AWS Modules
  - aws-network
  - aws-eks
  - aws-efs
- k8s-tools
  - argocd
  - argocd-image-updater
  - aws-load-balancer-controller
  - envoy-gateway-api
  - external-secrets-operator
  - gateway-api-crds
  - gha-runner
  - istio
  - karpenter
  - kube-downscaler
  - monitoring
    - blackbox-exporter
    - grafana-alloy
    - grafana
    - kiali (optional Istio dashboard)
    - loki
    - prometheus
  - secrets-store-csi-driver
  - sonarqube
  - stakater-reloader
# Notes
- This repo is authenticated with aws through OIDC Reference --> https://www.youtube.com/watch?v=Sdzd4N6L5Hg
- All of these components are flagable which means you can easily enable or disable any module or tool that you don't want through the env.hcl file for example --> "./aws-accounts/{account-id}/us-east-1/dev/env.hcl"
- Push and commits pipelines are disabled so you need to run the pipeline manually and pass the env variable each time with the right value
  - Github Action
![Image Description](screenshots/3.png)
  - Gitlab-CI
![Image Description](screenshots/1.png)
![Image Description](screenshots/2.png)

## Updating provider lockfiles
This repository commits `.terraform.lock.hcl` files alongside each Terraform root module (e.g. `aws-modules/*`, `k8s-tools/*`) to ensure reproducible provider versions across all environments. Because the team works across macOS (Apple Silicon), Linux (CI/CD pipelines), and Windows, each lockfile must include checksums for all three platforms.

**Whenever you add, remove, or change a provider (or a provider version constraint) in `root.hcl` or in any module,** regenerate the lockfiles and commit them. Terragrunt copies the generated `.terraform.lock.hcl` back into each module's source directory automatically (`copy_terraform_lock_file` defaults to `true`), so the file you commit lives next to the module code, not in the gitignored `.terragrunt-cache/`. Use Terragrunt for the lock command because it supplies the generated provider configuration used by CI.

Steps (run locally, from the repo root or the affected environment directory, e.g. `aws-accounts/948763340657/us-east-1/dev`):

1. Initialize all modules in that environment so Terragrunt generates/refreshes each module's lockfile:
   ```
   terragrunt run-all init
   ```
   (Requires valid AWS credentials configured locally, since this touches the real S3/DynamoDB backend.)

2. Regenerate the lockfile in every enabled stack. From the environment directory, run this macOS/Linux shell loop:
   ```
   find . -name terragrunt.hcl -not -path '*/.terragrunt-cache/*' -print0 | while IFS= read -r -d '' config; do
     module_dir=${config%/terragrunt.hcl}
     if [ -f "$module_dir/.terraform.lock.hcl" ]; then
       echo "Locking $module_dir"
       (cd "$module_dir" && terragrunt providers lock -platform=linux_amd64 -platform=darwin_arm64 -platform=windows_amd64) || exit
     fi
   done
   ```
   This runs Terragrunt from each enabled module directory and only processes directories that received a lockfile during step 1. Do not run plain `terraform providers lock` from the source module directories; those do not contain Terragrunt's generated provider configuration.

3. Confirm the lockfiles cannot be changed during initialization:
   ```
   terragrunt init --all --backend-bootstrap --non-interactive -- -lockfile=readonly
   ```

4. Review and commit the updated `.terraform.lock.hcl` files:
   ```
   git status --short
   git diff --check
   git add .
   git commit -m "Update portable Terraform provider lockfiles"
   git push
   ```

⚠️ Do **not** run a plain `terraform init` (or only `terragrunt run-all init`) and commit the resulting lockfile without the `terraform providers lock -platform=...` step above — that only records checksums for your own machine's platform and can break CI (Linux) or a colleague's machine (Windows/macOS) with a provider checksum mismatch.

Normal `terraform init` reuses the provider versions selected in the lockfile, so the pipeline remains version-safe without `-lockfile=readonly`. It may take longer because Terraform can download providers and add missing platform checksums to its temporary CI copy. Versions change only when the constraints or lockfile change, or when `-upgrade` is explicitly used.

For a one-time full-stack refresh, set every `enable_*` flag in `env.hcl` to `true` before step 1. Restore the flags afterward if those stacks should remain disabled; otherwise CI will attempt to provision every enabled module during apply.

Reference: https://developer.hashicorp.com/terraform/cli/commands/providers/lock
