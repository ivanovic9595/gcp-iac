terraform {
  source = "github.com/terraform-google-modules/terraform-google-kubernetes-engine.git?ref=v21.0.0"
}

## Dependencies:
dependencies {
  paths = [
    "${dirname(find_in_parent_folders())}/env/${local.region}/vpc",
    "${dirname(find_in_parent_folders())}/env/global/iam/service-accounts/gke-${local.bname}"
  ]
}

dependency "vpc" {
  config_path = "${dirname(find_in_parent_folders())}/env/${local.region}/vpc"
}

dependency "iam" {
  config_path = "${dirname(find_in_parent_folders())}/env/global/iam/service-accounts/gke-${local.bname}"
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
  bname        = basename(get_terragrunt_dir())
  name_prefix  = lower("${local.project_name}-${local.env}")
  name         = lower("${local.name_prefix}-${local.bname}")

  labels = merge(
    try(local.global_vars.locals.labels, {}),
    {
      name = local.name
      env  = lower(local.env_desc)
    }
  )
}

inputs = {
  name               = local.name
  description        = "${local.env_desc} GKE Cluster of ${local.project_name}"
  project_id         = local.project_id
  region             = local.region
  regional           = try(local.global_vars.locals.gke_settings["regional"], true)
  kubernetes_version = try(local.global_vars.locals.gke_settings["version"], "latest")
  resource_labels    = local.labels

  network           = dependency.vpc.outputs.network_name
  subnetwork        = dependency.vpc.outputs.subnets_names[try(local.global_vars.locals.gke_settings["subnet_num"], 1)]
  ip_range_pods     = try(local.global_vars.locals.gke_settings[local.env]["ip_range_pods"], "${local.name}-pod")
  ip_range_services = try(local.global_vars.locals.gke_settings[local.env]["ip_range_services"], "${local.name}-service")

  service_account = dependency.iam.outputs.email
  node_pools = try(local.global_vars.locals.gke_settings[local.env]["node_pools"], [
    {
      name         = "default"
      autoscaling  = false
      min_count    = 1
      max_count    = 3
      image_type   = "COS_CONTAINERD"
      machine_type = "e2-small"
      disk_size_gb = 100
      disk_type    = "pd-standard"
    }
  ])

  maintenance_start_time = try(local.global_vars.locals.gke_settings["maintenance_start_time"], "19:00")
  maintenance_exclusions = try(local.global_vars.locals.gke_settings["maintenance_exclusions"], [])

}
