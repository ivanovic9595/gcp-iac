terraform {
  source = "github.com/terraform-google-modules/terraform-google-service-accounts.git?ref=v4.1.1"
}

## Variables:
locals {
  global_vars  = read_terragrunt_config(find_in_parent_folders("global.hcl"), {})
  region_vars  = read_terragrunt_config(find_in_parent_folders("region.hcl"), {})
  env_vars     = read_terragrunt_config(find_in_parent_folders("env.hcl"), {})
  env          = local.env_vars.locals.env
  env_desc     = local.env_vars.locals.env_desc
  region       = local.region_vars.locals.region
  project_id   = local.global_vars.locals.project_id
  project_name = local.global_vars.locals.project_name
  name         = basename(get_terragrunt_dir())
  name-prefix  = lower("${local.project_name}-${local.env}")

}

inputs = {
  names         = [lower("${local.name-prefix}-${local.name}")]
  description   = "Service accounts for ${local.name-prefix}-${local.name}"
  display_name  = "Service accounts for ${local.name-prefix}-${local.name}"
  project_id    = local.project_id
  project_roles = try(local.global_vars.locals.iam_settings[local.name], ["${local.project_id}=>roles/viewer"])
}
