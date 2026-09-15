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
Terraform lockfiles remember the provider versions to use, such as AWS `6.61.0`. They also store checksums proving that downloaded providers are authentic. This repository includes checksums for Linux, macOS Apple Silicon, and Windows so the same lockfile works on every supported platform.

Whenever you add, remove, or change a provider or its version constraint, regenerate and commit the affected lockfiles. Use Terragrunt for this because it supplies the generated provider configuration used by CI and copies the lockfile back beside the module code.

Run these steps from the environment directory, for example `aws-accounts/948763340657/us-east-1/dev`:

1. Initialize the environment:
  ```bash
  terragrunt init --all --backend-bootstrap --non-interactive
  ```
  Requires valid AWS credentials configured locally, since this touches the real S3/DynamoDB backend.

2. Generate checksums for Linux, macOS Apple Silicon, and Windows in every enabled stack:
  ```bash
   find . -name terragrunt.hcl -not -path '*/.terragrunt-cache/*' -print0 | while IFS= read -r -d '' config; do
     module_dir=${config%/terragrunt.hcl}
     if [ -f "$module_dir/.terraform.lock.hcl" ]; then
       echo "Locking $module_dir"
       (cd "$module_dir" && terragrunt providers lock -platform=linux_amd64 -platform=darwin_arm64 -platform=windows_amd64) || exit
     fi
   done
   ```
  The loop only processes modules that received a lockfile during step 1. Do not run plain `terraform providers lock` from source directories; use Terragrunt so the generated CI configuration is included.

3. Verify that CI can initialize without changing the lockfiles:
  ```bash
   terragrunt init --all --backend-bootstrap --non-interactive -- -lockfile=readonly
   ```

4. Review, commit, and push the updated lockfiles:
  ```bash
   git status --short
   git diff --check
  git add README.md path/to/changed/.terraform.lock.hcl
   git commit -m "Update portable Terraform provider lockfiles"
   git push
   ```

Normal `terraform init` reuses the provider versions selected in the lockfile, so the pipeline remains version-safe without `-lockfile=readonly`. It may take longer because Terraform can download providers and add missing platform checksums to its temporary CI copy. It does not upgrade versions automatically.

Provider versions change only when the constraints or lockfile change, or when `-upgrade` is explicitly used. The `-lockfile=readonly` option is a strict check: it prevents temporary lockfile changes and makes CI fail if checksums or selections are incomplete.

### Intentional provider upgrade
You do not have to use `--upgrade` for every update. It selects the newest version allowed by the provider constraint, so use it only when that is intended:
```bash
terragrunt init --all --upgrade --backend-bootstrap --non-interactive
```
Then run step 2 again to generate Linux, macOS Apple Silicon, and Windows checksums, run step 3 to validate the lockfiles, and review the version changes before committing. Do not combine `--upgrade` with `-lockfile=readonly`.

To pin a specific version, update that provider's version constraint in `root.hcl`, or in the module's own `terraform { required_providers { ... } }` block when the module defines the constraint itself. Then run step 1 with `--upgrade`, followed by steps 2 and 3. Do not manually edit `.terraform.lock.hcl`; Terraform generates the selected version and platform checksums from the provider constraints.

**How version selection works:** provider constraints define which versions are allowed; the lockfile records the selected version and normal `init` reuses it while it remains valid. `--upgrade` tells Terraform to choose the newest version allowed by the constraints. For example, changing a constraint to `= 6.62.0` forces that exact version, while leaving `~> 6.0` and using `--upgrade` selects the newest compatible `6.x` version.

### Full-stack refresh

For a one-time full-stack refresh, set every `enable_*` flag in `env.hcl` to `true` before step 1. Restore the flags afterward if those stacks should remain disabled; otherwise CI will attempt to provision every enabled module during apply.

Reference: https://developer.hashicorp.com/terraform/cli/commands/providers/lock
