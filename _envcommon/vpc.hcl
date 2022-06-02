terraform {
  source = "github.com/terraform-google-modules/terraform-google-network.git?ref=v5.0.0"
}

## Dependencies:
dependencies {
  paths = []
}

## Variables:
locals {
  global_vars = read_terragrunt_config(find_in_parent_folders("global.hcl"), {})
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"), {})
  env_vars    = read_terragrunt_config(find_in_parent_folders("env.hcl"), {})
  env         = local.env_vars.locals.env
  env_desc    = local.env_vars.locals.env_desc
  region      = local.region_vars.locals.region

  project_id   = local.global_vars.locals.project_id
  name         = lower("${local.global_vars.locals.project_name}-${local.env}")
  cidr         = try(local.global_vars.locals.vpc_settings["cidrs"][local.env][local.region], "10.200.0.0/20")
  cidr_newbits = try(local.global_vars.locals.vpc_settings["cidr_newbits"], "4")

  subnet_01 = "${local.name}-public"
  subnet_02 = "${local.name}-private"

}

inputs = {
  network_name = local.name
  project_id   = local.project_id
  routing_mode = try(local.global_vars.locals.vpc_settings["routing_mode"], "REGIONAL")

  subnets = [
    {
      subnet_name   = local.subnet_01
      subnet_ip     = "${cidrsubnet(local.cidr, local.cidr_newbits, 0)}"
      subnet_region = local.region
    },
    {
      subnet_name           = local.subnet_02
      subnet_ip             = "${cidrsubnet(local.cidr, local.cidr_newbits, 1)}"
      subnet_region         = local.region
      subnet_private_access = "true"
    }
  ]

  secondary_ranges = try(local.global_vars.locals.gke_settings, {}) == {} ? {} : {
    "${local.subnet_01}" = [
      {
        range_name    = try(local.global_vars.locals.gke_settings[local.env]["ip_range_pods"], "${local.name}-pod")
        ip_cidr_range = "172.16.16.0/20"
      },
      {
        range_name    = try(local.global_vars.locals.gke_settings[local.env]["ip_range_services"], "${local.name}-service")
        ip_cidr_range = "172.16.32.0/20"
      },
    ]
  }
}
