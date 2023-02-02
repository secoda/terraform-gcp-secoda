resource "random_id" "db_name_suffix" {
  byte_length = 4
}

resource "random_password" "database_password" {
  length  = 16
  special = false
}

resource "google_sql_database_instance" "postgres" {
  name             = "postgres-${var.project_name}-${random_id.db_name_suffix.hex}"
  database_version = "POSTGRES_14"

  settings {
    tier = "db-custom-2-3840"
    backup_configuration {
      enabled            = true
      binary_log_enabled = false
      start_time         = "00:05"

      backup_retention_settings {
        retention_unit   = "COUNT"
        retained_backups = 14
      }
    }
    ip_configuration {
      ipv4_enabled = true
      require_ssl  = true
    }
  }
}

resource "google_sql_user" "users" {
  name     = "keycloak"
  instance = google_sql_database_instance.postgres.name
  password = random_password.database_password.result
}