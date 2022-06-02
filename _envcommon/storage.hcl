terraform {
  source = "github.com/terraform-google-modules/terraform-google-cloud-storage.git//modules/simple_bucket?ref=v3.2.0"
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
  location     = try(local.global_vars.locals.storage_settings["locations"][local.env], local.region)

  labels = merge(
    try(local.global_vars.locals.labels, {}),
    {
      name = lower("${local.name-prefix}-${local.name}")
      env  = lower(local.env_desc)
    }
  )
}

inputs = {
  name          = lower("${local.name-prefix}-${local.name}-${local.location}")
  project_id    = local.project_id
  location      = local.location
  storage_class = try(local.global_vars.locals.storage_settins["class"], "STANDARD")
  labels        = local.labels
}
