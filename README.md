# Terragrunt/Terraform
Terragrunt and terraform template for GCP

## Requirements:
1. [Terraform](https://www.terraform.io/): version ~> v1.0.10
2. [Terragrunt](https://terragrunt.gruntwork.io/): version ~> v0.35.6
3. [Google Cloud SDK](https://cloud.google.com/sdk/docs/install): version ~> 363.0.0
4. Edit $HOME/[.terraformrc](https://www.terraform.io/docs/commands/cli-config.html):
```bash
mkdir -p $HOME/.terraform.d/plugins
tee $HOME/.terraformrc <<-EOF
plugin_cache_dir = "\$HOME/.terraform.d/plugins"
disable_checkpoint = true
EOF
```
5. Roles for terraform:
```
roles/cloudsql.admin
roles/compute.admin
roles/compute.networkAdmin
roles/compute.storageAdmin
roles/monitoring.admin
roles/resourcemanager.projectIamAdmin
roles/iam.serviceAccountAdmin
roles/iam.serviceAccountUser
roles/storage.admin
```

## Alias:
```bash
alias tg='terragrunt'
alias tgh='tg hclfmt'
alias tga='tgh && tg apply'
alias tgp='tgh && tg plan'
```

## Steps to provision:

### Set default login:
```bash
gcloud auth application-default login
```

### Active services' API:
```bash
(cd common/global/project-services && tg apply)
```

### Get gcp-data info:
get gcp-data
```bash
(cd common/asia-northeast1/gcp-data && tg apply)
```

### Set environment from ENV before provisoning env's resources (Default is 'dev'):
```
## Test env:
export ENV=test

## Staging env:
export ENV=stage

## Production env:
export ENV=prod
```

### Env's resources:
```bash
(cd env/asia-northeast1/<resource-dir> && tg apply)
```
