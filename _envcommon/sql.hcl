terraform {
  source = "github.com/terraform-google-modules/terraform-google-sql-db.git//modules/mysql?ref=v10.0.1"
}

## Dependencies:
dependencies {
  paths = [
    "${dirname(find_in_parent_folders())}/env/${local.region}/vpc",
    "${dirname(find_in_parent_folders())}/common/${local.region}/gcp-data",
    "${dirname(find_in_parent_folders())}/env/${local.region}/sql/private-access"
  ]
}

dependency "vpc" {
  config_path = "${dirname(find_in_parent_folders())}/env/${local.region}/vpc"
}

dependency "private" {
  config_path = "${dirname(find_in_parent_folders())}/env/${local.region}/sql/private-access"
}

dependency "data" {
  config_path = "${dirname(find_in_parent_folders())}/common/${local.region}/gcp-data"
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

  _flags = try(local.global_vars.locals.sql_settings["database_flags"], [])
  database_flags = [for k, v in local._flags : {
    name  = k
    value = v
  }]

  labels = merge(
    try(local.global_vars.locals.labels, {}),
    {
      name = local._name
      env  = lower(local.env_desc)
    }
  )
}

inputs = {
  name                = local._name
  project_id          = local.project_id
  database_version    = try(local.global_vars.locals.sql_settings["database_version"], "MYSQL_5_7") # "MYSQL_8_0"
  region              = local.region
  zone                = dependency.data.outputs.available_google_compute_zone_names[0]
  tier                = try(local.global_vars.locals.sql_settings[local.env]["tier"], "db-g1-small")
  activation_policy   = try(local.global_vars.locals.sql_settings["activation_policy"], "ALWAYS")
  availability_type   = local.env == "prod" ? "REGIONAL" : "ZONAL"
  disk_autoresize     = try(local.global_vars.locals.sql_settings["disk_autoresize"], true)
  disk_size           = try(local.global_vars.locals.sql_settings[local.env]["disk_size"], "10")
  disk_type           = try(local.global_vars.locals.sql_settings[local.env]["disk_type"], "PD_SSD")
  pricing_plan        = try(local.global_vars.locals.sql_settings["pricing_plan"], "PER_USE")
  database_flags      = local.database_flags
  deletion_protection = try(local.global_vars.locals.sql_settings["deletion_protection"], true)
  user_labels         = local.labels

  maintenance_window_day          = try(local.global_vars.locals.sql_settings["maintenance"]["day"], 1)
  maintenance_window_hour         = try(local.global_vars.locals.sql_settings["maintenance"]["hour"], 18)
  maintenance_window_update_track = try(local.global_vars.locals.sql_settings["maintenance"]["update_track"], "stable")
  backup_configuration            = try(local.global_vars.locals.sql_settings["backup"], {})

  ip_configuration = {
    ipv4_enabled        = try(local.global_vars.locals.sql_settings["assign_public_ip"], false)
    authorized_networks = []
    require_ssl         = try(local.global_vars.locals.sql_settings["require_ssl"], false)
    private_network     = dependency.vpc.outputs.network_id
    allocated_ip_range  = dependency.private.outputs.google_compute_global_address_name
  }

  db_name              = replace(local.name-prefix, "-", "_")
  db_charset           = try(local.global_vars.locals.sql_settings["db_charset"], "utf8mb4")
  db_collation         = try(local.global_vars.locals.sql_settings["db_collation"], "utf8mb4_unicode_ci")
  additional_databases = try(local.global_vars.locals.sql_settings["additional_databases"], [])
  user_name            = replace(local.name-prefix, "-", "_")
  user_host            = try(local.global_vars.locals.sql_settings["user_host"], "%")
  additional_users     = try(local.global_vars.locals.sql_settings["additional_users"], [])

  // Read replica
  read_replica_deletion_protection = try(local.global_vars.locals.sql_settings["deletion_protection"], true)
  read_replicas = local.env != "prod" ? [] : [
    {
      name            = "${local._name}-repl"
      tier            = try(local.global_vars.locals.sql_settings[local.env]["tier"], "db-g1-small")
      zone            = dependency.data.outputs.available_google_compute_zone_names[1]
      disk_type       = try(local.global_vars.locals.sql_settings[local.env]["disk_type"], "PD_SSD")
      disk_autoresize = try(local.global_vars.locals.sql_settings["disk_autoresize"], true)
      disk_size       = try(local.global_vars.locals.sql_settings[local.env]["disk_size"], "10")
      user_labels     = local.labels
      database_flags  = local.database_flags
      ip_configuration = {
        ipv4_enabled        = try(local.global_vars.locals.sql_settings["assign_public_ip"], false)
        authorized_networks = []
        require_ssl         = try(local.global_vars.locals.sql_settings["require_ssl"], false)
        private_network     = dependency.vpc.outputs.network_id
        allocated_ip_range  = dependency.private.outputs.google_compute_global_address_name
      }
      encryption_key_name = null
    }
  ]
}
