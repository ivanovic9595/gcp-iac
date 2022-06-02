terraform {
  source = "github.com/terraform-google-modules/terraform-google-address.git?ref=v3.1.1"
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
  names        = ["bastion"]
}

inputs = {
  names        = formatlist("${local.project_name}-${local.env}-%s", local.names)
  project_id   = local.project_id
  region       = local.region
  global       = false
  subnetwork   = ""
  address_type = "EXTERNAL"
  network_tier = "PREMIUM"
}
