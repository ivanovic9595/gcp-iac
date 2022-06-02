terraform {
  source = "github.com/terraform-google-modules/terraform-google-vm.git//modules/instance_template?ref=v7.7.0"
}

## Dependencies:
dependencies {
  paths = [
    "${dirname(find_in_parent_folders())}/env/${local.region}/vpc",
    "${dirname(find_in_parent_folders())}/env/global/iam/service-accounts/${local.name}",
    "${dirname(find_in_parent_folders())}/env/${local.region}/ssh-keys"
  ]
}

dependency "vpc" {
  config_path = "${dirname(find_in_parent_folders())}/env/${local.region}/vpc"
}

dependency "iam" {
  config_path = "${dirname(find_in_parent_folders())}/env/global/iam/service-accounts/${local.name}"
}

dependency "ssh" {
  config_path = "${dirname(find_in_parent_folders())}/env/${local.region}/ssh-keys"
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
  _name        = lower("${local.project_name}-${local.env}-${local.name}")
  tagname      = try(local.global_vars.locals.gce_settings[local.env][local.name]["tagname"], "web")
  ssh_user     = try(local.global_vars.locals.ssh_users[local.env], "admin")
  prompt_color = try(local.global_vars.locals.gce_settings["${local.env}"]["prompt_color"], "32m")

  labels = merge(
    try(local.global_vars.locals.labels, {}),
    {
      name = local._name
      env  = lower(local.env_desc)
    }
  )
}

inputs = {
  name_prefix = local._name
  project_id  = local.project_id
  region      = local.region

  ## Disk and capacity:
  machine_type         = try(local.global_vars.locals.gce_settings[local.env][local.name]["machine_type"], "e2-micro")
  source_image_family  = try(local.global_vars.locals.gce_settings[local.env][local.name]["image_family"], "ubuntu-minimal-1804-lts")
  source_image_project = try(local.global_vars.locals.gce_settings[local.env][local.name]["image_project"], "ubuntu-os-cloud")
  disk_size_gb         = try(local.global_vars.locals.gce_settings[local.env][local.name]["disk_size"], "30")
  disk_type            = try(local.global_vars.locals.gce_settings[local.env][local.name]["disk_type"], "pd-standard")
  disk_labels          = local.labels
  auto_delete          = try(local.global_vars.locals.gce_settings[local.env]["auto_delete"], true)

  ## Network:
  tags       = [local.tagname]
  network    = dependency.vpc.outputs.network_name
  subnetwork = dependency.vpc.outputs.subnets_names[0]

  ## Service account:
  service_account = {
    email  = dependency.iam.outputs.email
    scopes = ["cloud-platform"]
  }

  ## Metadata:
  metadata = {
    ssh-keys = "${local.ssh_user}:${try(dependency.ssh.outputs.public_keys[lower("${local.project_name}-${local.env}")], "")}"
    user-data = templatefile(
      "${dirname(find_in_parent_folders())}/_templates/user-data/ubuntu.tpl",
      {
        ssh_user     = local.ssh_user
        hostname     = upper(local._name)
        prompt_color = local.prompt_color
      }
    )
  }

}
