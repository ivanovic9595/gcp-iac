include "root" {
  path = find_in_parent_folders()
}

include "envcommon" {
  path = "${dirname(find_in_parent_folders())}/_envcommon/instance-template.hcl"
}

## Dependencies:
dependencies {
  paths = [
    "${dirname(find_in_parent_folders())}/env/${local.region}/storage/cicd",
  ]
}

dependency "storage" {
  config_path = "${dirname(find_in_parent_folders())}/env/${local.region}/storage/cicd"
}

## Variables:
locals {
  global_vars = read_terragrunt_config(find_in_parent_folders("global.hcl"), {})
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"), {})
  env_vars    = read_terragrunt_config(find_in_parent_folders("env.hcl"), {})
  env         = local.env_vars.locals.env
  env_desc    = local.env_vars.locals.env_desc
  region      = local.region_vars.locals.region
  project_id  = local.global_vars.locals.project_id
  name        = basename(get_terragrunt_dir())
}

inputs = {
  startup_script = templatefile(
    "${dirname(find_in_parent_folders())}/_templates/startup-script/${local.name}.tpl",
    {
      webroot       = try(local.global_vars.locals.cicd_settings["webroot"], "/var/www/html")
      source_bucket = dependency.storage.outputs.bucket["id"]
    }
  )
}
