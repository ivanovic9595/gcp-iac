terraform {
  source = "github.com/terraform-google-modules/terraform-google-cloud-nat.git?ref=v2.2.0"
}

## Dependencies:
dependencies {
  paths = [
    "${dirname(find_in_parent_folders())}/env/${local.region}/vpc"
  ]
}

dependency "vpc" {
  config_path = "${dirname(find_in_parent_folders())}/env/${local.region}/vpc"
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
  _name        = lower("${local.name-prefix}-${local.name}")

  labels = merge(
    try(local.global_vars.locals.labels, {}),
    {
      name = local._name
      env  = lower(local.env_desc)
    }
  )
}

inputs = {
  name          = local._name
  project_id    = local.project_id
  region        = local.region
  network       = dependency.vpc.outputs.network_name
  create_router = true
  router        = local._name
  subnetwork = {
    name                     = dependency.vpc.outputs.subnets_names[0]
    source_ip_ranges_to_nat  = dependency.vpc.outputs.subnets_ips[0]
    secondary_ip_range_names = null
  }
}
