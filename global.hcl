locals {
  project_name   = get_env("PROJECT_NAME", "hbl-terra")
  project_id     = get_env("PROJECT_ID", "hbl-terra")
  operation_team = get_env("OPERATION_TEAM", "")
  noti_user      = get_env("NOTI_USER", "infra")
  noti_domain    = get_env("NOTI_DOMAIN", "")
  time_zone      = get_env("TIME_ZONE", "Asia/Tokyo")
  ssh_user       = get_env("SSH_USER", local.project_name)
  main_region    = get_env("MAIN_REGION", "asia-northeast1")
  state_region   = get_env("STATE_REGION", local.main_region)

  mnt_ips = {
    "${local.operation_team}_fpt"           = "xxx.xxx.xxx.xxx/32",
    "${local.operation_team}_cmc"           = "xxx.xxx.xxx.xxx/32",
    "${local.operation_team}_gitlab_runner" = "xxx.xxx.xxx.xxx/32",
  }

  ## Project services:
  activate_apis = [
    "compute.googleapis.com",
    "servicenetworking.googleapis.com",
    "container.googleapis.com", # For GKE
    "cloudbuild.googleapis.com"
  ]

  ## For VPCs:
  vpc_settings = {
    routing_mode = "REGIONAL"
    cidr_newbits = 4
    cidrs = {
      dev   = { "${local.main_region}" = "10.1.0.0/16" }
      test  = { "${local.main_region}" = "10.2.0.0/16" }
      stage = { "${local.main_region}" = "10.3.0.0/16" }
      prod  = { "${local.main_region}" = "10.8.0.0/16" }
    }
  }

  ## GCE:
  gce_settings = {
    dev = {
      web = {
        tagname       = "web"
        target_size   = 2
        min           = 2
        max           = 8
        target_cpu    = "0.6"
        machine_type  = "e2-micro"
        disk_type     = "pd-standard"
        image_family  = "dev-web-20220506-v1"
        image_project = local.project_name
      }

      bastion = {
        machine_type  = "e2-micro"
        tagname       = "bastion"
        disk_size     = 20
        disk_type     = "pd-standard"
        image_family  = "bastion-20220505-v1"
        image_project = local.project_name
      }
    }

    prod = {
      prompt_color = "31m"

      web = {
        tagname      = "web"
        target_size  = 2
        min          = 2
        max          = 10
        target_cpu   = "0.6"
        machine_type = "e2-micro"
        disk_type    = "pd-ssd"
      }

      bastion = {
        machine_type = "e2-micro"
        tagname      = "bastion"
        disk_size    = 20
        disk_type    = "pd-ssd"
      }
    }
  }

  ## GKE Settings:
  gke_settings = {
    dev = {
      ip_range_pods     = lower("${local.project_name}-dev-pod")
      ip_range_services = lower("${local.project_name}-dev-service")
      node_pools = [
        {
          name         = "default"
          autoscaling  = false
          min_count    = 1
          max_count    = 20
          image_type   = "COS_CONTAINERD"
          machine_type = "e2-small"
          disk_size_gb = 100
          disk_type    = "pd-standard"
        }
      ]
    }
  }

  ## SSH User:
  ssh_users = {
    dev   = lower(local.operation_team)
    stage = lower(local.operation_team)
    test  = lower(local.operation_team)
    prod  = lower(local.operation_team)
  }

  ## cloud sql settings:
  sql_settings = {
    database_version    = "MYSQL_5_7"
    deletion_protection = true
    db_charset          = "utf8mb4"
    db_collation        = "utf8mb4_unicode_ci"

    database_flags = {
      log_output           = "FILE"
      long_query_time      = ".5"
      slow_query_log       = "on"
      max_connections      = "3000"
      default_time_zone    = "+09:00"
      character_set_server = "utf8mb4"
    }

    maintenance = {
      day          = 1
      hour         = 18
      update_track = "stable"
    }

    backup = {
      binary_log_enabled             = true
      enabled                        = true
      start_time                     = "17:05"
      location                       = local.main_region
      point_in_time_recovery_enabled = true
      transaction_log_retention_days = 7
      retained_backups               = 14
      retention_unit                 = "COUNT"
    }
  }

  ## IAM:
  iam_settings = {
    build = [
      "${local.project_id}=>roles/viewer",
      "${local.project_id}=>roles/compute.admin",
      "${local.project_id}=>roles/storage.admin",
      "${local.project_id}=>roles/logging.logWriter",
      "${local.project_id}=>roles/iam.serviceAccountUser",
    ]
  }

  ## Domains: for using clouddns
  domain_locals = {
    "${local.main_region}" = "tokyo.local"
  }

  root_domain = "your-domain"
  domain_names = {
    dev  = "dev-${local.project_name}.${local.root_domain}"
    test = "test.${local.root_domain}"
    stg  = "stg.${local.root_domain}"
    prd  = "prd.${local.root_domain}"
  }

  ## Bucket locations:
  #  https://cloud.google.com/storage/docs/locations
  storage_settings = {
    force_destroy = false
    versioning    = false
    class         = "STANDARD"
    locations = {
      prod = "asia1"
    }
  }

  ## Backup and maintenance:
  maintenance_start_time = "19:00" # UTC

  ## GLOBAL labels:
  labels = {
    namespace = lower(local.project_name)
    managedby = lower(local.operation_team)
  }
}
