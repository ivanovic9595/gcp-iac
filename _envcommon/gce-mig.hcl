terraform {
  source = "github.com/terraform-google-modules/terraform-google-vm.git//modules/mig?ref=v7.7.0"
}

## Dependencies:
dependencies {
  paths = [
    "${dirname(find_in_parent_folders())}/env/${local.region}/gce/templates/${local.name}",
  ]
}

dependency "template" {
  config_path = "${dirname(find_in_parent_folders())}/env/${local.region}/gce/templates/${local.name}"
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

  labels = merge(
    try(local.global_vars.locals.labels, {}),
    {
      name = lower("${local.name-prefix}-${local.name}")
      env  = lower(local.env_desc)
    }
  )
}

inputs = {
  hostname   = lower("${local.name-prefix}-${local.name}")
  project_id = local.project_id
  region     = local.region

  instance_template = dependency.template.outputs.self_link
  target_size       = try(local.global_vars.locals.gce_settings[local.env][local.name]["target_size"], 1)
  target_pools      = []

  update_policy = [{
    type                         = "PROACTIVE"
    instance_redistribution_type = "PROACTIVE"
    minimal_action               = "REPLACE"
    max_surge_fixed              = 3
    max_unavailable_percent      = null
    max_surge_percent            = null
    max_unavailable_fixed        = 0
    min_ready_sec                = 50
    replacement_method           = "SUBSTITUTE"
  }]

  # health_check = {
  #   type                = "http"
  #   initial_delay_sec   = 10
  #   check_interval_sec  = 10
  #   healthy_threshold   = 1
  #   timeout_sec         = 5
  #   unhealthy_threshold = 1
  #   response            = ""
  #   proxy_header        = "NONE"
  #   port                = 80
  #   request             = ""
  #   request_path        = "/"
  #   host                = ""
  # }

  ## Autoscale:
  autoscaling_enabled = true
  max_replicas        = try(local.global_vars.locals.gce_settings[local.env][local.name]["max"], 2)
  min_replicas        = try(local.global_vars.locals.gce_settings[local.env][local.name]["min"], 1)
  autoscaling_cpu = [
    {
      target = try(local.global_vars.locals.gce_settings[local.env][local.name]["target_cpu"], "0.7")
    }
  ]
  autoscaling_metric = []
  autoscaling_lb     = []

  named_ports = [
    {
      name = "http"
      port = "80"
    }
  ]
}
