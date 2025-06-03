# Generate a random password for MySQL application user
resource "random_password" "mysql_app_password" {
  length  = 16
  special = false
  upper   = true
  lower   = true
  numeric = true
}
# Generate a random UUID to ensure unique secret naming
resource "random_string" "mysql_secret_suffix" {
  length  = 6
  numeric = true
  upper   = false
  lower   = true
  special = false
}

# Create a local value for the unique secret name
locals {
  mysql_secret_name = "${local.name_prefix}-mysql-app-password-${random_string.mysql_secret_suffix.result}"
}

# Create a secret in Google Secret Manager for MySQL application user password
resource "google_secret_manager_secret" "mysql_app_password" {
  secret_id = local.mysql_secret_name

  labels = merge(
    local.common_tags,
    {
      service  = "mysql"
      type     = "database-credential"
      username = "appuser"
    }
  )

  replication {
    auto {}
  }

  depends_on = [google_project_service.secretmanager]
}

# Create a version of the secret with the generated password
resource "google_secret_manager_secret_version" "mysql_app_password" {
  secret      = google_secret_manager_secret.mysql_app_password.id
  secret_data = random_password.mysql_app_password.result
}

# IAM binding to allow the service account to access the secret
resource "google_secret_manager_secret_iam_binding" "mysql_password_access" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.mysql_app_password.secret_id
  role      = "roles/secretmanager.secretAccessor"

  members = [
    "serviceAccount:${var.service_account_email}"
  ]
} 