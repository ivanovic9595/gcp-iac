terraform {
  source = "github.com/ivanovic9595/terraform-modules.git//ssh/ssh-keys?ref=0.3.0"
}

include "root" {
  path = "${find_in_parent_folders()}"
}

## Variables:
locals {
  global_vars = read_terragrunt_config(find_in_parent_folders("global.hcl"), {})
  env_vars    = read_terragrunt_config(find_in_parent_folders("env.hcl"), {})
  env         = local.env_vars.locals.env
  name        = lower("${local.global_vars.locals.project_name}-${local.env}")
}

inputs = {
  names    = [local.name]
  save_dir = get_terragrunt_dir()
}
