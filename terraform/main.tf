terraform {
  required_providers {
    aiven = {
      source  = "aiven/aiven"
      version = "~> 4.0"
    }
  }
}

provider "aiven" {
  api_token = var.aiven_api_token
}

locals {
  free_plan = startswith(var.pg_plan, "free-")
}

resource "aiven_pg" "dashboard_db" {
  project                 = var.aiven_project
  cloud_name              = local.free_plan ? null : var.cloud_name
  plan                    = var.pg_plan
  service_name            = var.service_name
  maintenance_window_dow  = local.free_plan ? null : "sunday"
  maintenance_window_time = local.free_plan ? null : "03:00:00"

  lifecycle {
    precondition {
      condition     = local.free_plan || trimspace(var.cloud_name) != ""
      error_message = "Informe cloud_name ao selecionar um plano pago."
    }
  }
}

resource "aiven_pg_database" "dashboard" {
  project       = var.aiven_project
  service_name  = aiven_pg.dashboard_db.service_name
  database_name = var.database_name
}

resource "aiven_pg_user" "app_user" {
  project      = var.aiven_project
  service_name = aiven_pg.dashboard_db.service_name
  username     = var.db_username
}
