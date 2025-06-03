module "gcp_vm" {
  source = "../module-stack"

  # Required parameters
  project_id            = var.project_id
  instance_name         = local.name_prefix
  subnetwork            = var.subnetwork
  service_account_email = var.service_account_email
  zone                  = var.zone

  enable_cloud_bucket_storage = local.enable_cloud_db_backup
  bucket_force_destroy        = local.bucket_force_destroy

  # For Non-Critical VM Keep This False
  deletion_protection = local.deletion_protection

  metadata_startup_script = local.startup_script

  # Machine configuration
  machine_type = var.machine_type

  # Disk configuration
  boot_disk_size = var.boot_disk_size

  # Labels and tags
  labels = merge(
    local.common_tags,
    {
      service = "vm"
    }
  )

  tags = [
    local.name_prefix,
    "vm",
    var.environment
  ]
}

output "gcp_vm_output" {
  description = "The complete VM instance details, including Cloud Storage bucket if enabled"
  value = merge(
    {
      # VM Instance Details
      name                = module.gcp_vm.instance_name
      self_link           = module.gcp_vm.instance_self_link
      machine_type        = module.gcp_vm.instance_machine_type
      zone                = module.gcp_vm.instance_zone
      cpu_platform        = module.gcp_vm.cpu_platform
      instance_id         = module.gcp_vm.instance_id
      deletion_protection = module.gcp_vm.instance_deletion_protection
      internal_ip         = module.gcp_vm.instance_internal_ip
      external_ip         = module.gcp_vm.instance_external_ip
    },
    # Conditionally include bucket details if enabled
    local.enable_cloud_db_backup ? {
      bucket = {
        name           = module.gcp_vm.bucket_name
        self_link      = module.gcp_vm.bucket_self_link
        url            = module.gcp_vm.bucket_url
        location       = module.gcp_vm.bucket_location
        storage_class  = module.gcp_vm.bucket_storage_class
        versioning     = module.gcp_vm.bucket_versioning
        labels         = module.gcp_vm.bucket_labels
        lifecycle_rule = module.gcp_vm.bucket_lifecycle_rule
      }
    } : {}
  )
}

# Output for MySQL secret information
output "mysql_secret_info" {
  description = "Information about the MySQL application user password secret"
  value = {
    secret_id   = google_secret_manager_secret.mysql_app_password.secret_id
    secret_name = google_secret_manager_secret.mysql_app_password.name
    username    = "appuser"
  }
}

# Output for MySQL backup system information
output "mysql_backup_info" {
  description = "Information about the MySQL backup system"
  value = local.enable_cloud_db_backup ? {
    backup_schedule    = "Daily at 2:00 AM UTC"
    backup_location    = "gs://${module.gcp_vm.bucket_name}/mysql-backups/"
    backup_script_path = "/opt/mysql-backup/mysql_backup.sh"
    backup_logs_path   = "/opt/mysql-backup/backup.log"
    cron_logs_path     = "/opt/mysql-backup/cron.log"
    retention_policy   = "30 days in GCS, 3 local backups"
    manual_backup_cmd  = "/opt/mysql-backup/mysql_backup.sh"
  } : null
}