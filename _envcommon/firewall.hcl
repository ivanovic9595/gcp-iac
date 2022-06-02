terraform {
  source = "github.com/terraform-google-modules/terraform-google-network.git//modules/firewall-rules?ref=v5.0.0"
}

## Dependencies:
dependencies {
  paths = ["${dirname(find_in_parent_folders())}/env/${local.region}/vpc"]
}

dependency "vpc" {
  config_path = "${dirname(find_in_parent_folders())}/env/${local.region}/vpc"
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
  name        = lower("${local.global_vars.locals.project_name}-${local.env}")
  mnt_ips     = try(local.global_vars.locals.mnt_ips, {})
  web_tagname = try(local.global_vars.locals.gce_settings[local.env]["web"]["tagname"], "web")
  bst_tagname = try(local.global_vars.locals.gce_settings[local.env]["bastion"]["tagname"], "bastion")
}

inputs = {
  project_id   = local.project_id
  network_name = dependency.vpc.outputs.network_name

  rules = [
    {
      name                    = "${local.name}-bastion-access"
      description             = "Allow access to bastion"
      direction               = "INGRESS"
      priority                = 200
      source_tags             = null
      source_service_accounts = null
      target_tags             = [local.bst_tagname]
      target_service_accounts = null
      ranges                  = [for k, v in local.mnt_ips : v]
      allow = [{
        protocol = "tcp"
        ports    = ["22", "8080"]
      }]
      deny = []
      log_config = {
        metadata = "INCLUDE_ALL_METADATA"
      }
    },
    {
      name                    = "${local.name}-web-ssh"
      description             = "Allow access SSH to webapp from bastion"
      direction               = "INGRESS"
      priority                = 300
      source_tags             = [local.bst_tagname]
      source_service_accounts = null
      target_tags             = [local.web_tagname]
      target_service_accounts = null
      ranges                  = []
      allow = [{
        protocol = "tcp"
        ports    = ["22", "80"]
      }]
      deny = []
      log_config = {
        metadata = "INCLUDE_ALL_METADATA"
      }
    },
    {
      name                    = "${local.name}-db-mysql"
      description             = "Allow access to DB"
      direction               = "INGRESS"
      priority                = 100
      source_tags             = [local.bst_tagname, local.web_tagname]
      source_service_accounts = null
      target_tags             = ["database"]
      target_service_accounts = null
      ranges                  = []
      allow = [{
        protocol = "tcp"
        ports    = ["3306"]
      }]
      deny = []
      log_config = {
        metadata = "INCLUDE_ALL_METADATA"
      }
    }
  ]
}
