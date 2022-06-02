terraform {
  source = "github.com/terraform-google-modules/terraform-google-lb-http.git?ref=v6.2.0"
}

## Dependencies:
dependencies {
  paths = [
    "${dirname(find_in_parent_folders())}/env/${local.region}/gce/migs/${local.name}",
  ]
}

dependency "mig" {
  config_path = "${dirname(find_in_parent_folders())}/env/${local.region}/gce/migs/${local.name}"
}

dependency "template" {
  config_path = "${dirname(find_in_parent_folders())}/env/${local.region}/gce/templates/${local.name}"
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
  domain_name  = try(local.global_vars.locals.domain_names[local.env], "")

  labels = merge(
    try(local.global_vars.locals.labels, {}),
    {
      name = lower("${local.name-prefix}-${local.name}")
      env  = lower(local.env_desc)
    }
  )
}

inputs = {
  name           = "${local.name-prefix}-${local.name}"
  project        = local.project_id
  target_tags    = dependency.template.outputs.tags
  https_redirect = true

  ssl                             = true
  managed_ssl_certificate_domains = [local.domain_name]
  firewall_networks               = [dependency.vpc.outputs.network_name]

  backends = {
    default = {
      description             = null
      protocol                = "HTTP"
      port                    = 80
      port_name               = "http"
      timeout_sec             = 10
      enable_cdn              = false
      custom_request_headers  = null
      custom_response_headers = null
      security_policy         = null

      connection_draining_timeout_sec = null
      session_affinity                = null
      affinity_cookie_ttl_sec         = null

      health_check = {
        check_interval_sec  = null
        timeout_sec         = null
        healthy_threshold   = null
        unhealthy_threshold = null
        request_path        = "/"
        port                = 80
        host                = null
        logging             = null
      }

      log_config = {
        enable      = true
        sample_rate = 1.0
      }

      groups = [
        {
          # Each node pool instance group should be added to the backend.
          group                        = dependency.mig.outputs.instance_group
          balancing_mode               = null
          capacity_scaler              = null
          description                  = null
          max_connections              = null
          max_connections_per_instance = null
          max_connections_per_endpoint = null
          max_rate                     = null
          max_rate_per_instance        = null
          max_rate_per_endpoint        = null
          max_utilization              = null
        },
      ]

      iap_config = {
        enable               = false
        oauth2_client_id     = null
        oauth2_client_secret = null
      }
    }
  }
}
