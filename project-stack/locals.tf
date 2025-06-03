locals {
  # Common tags for all resources
  common_tags = {
    project_name = "${var.ou}-${var.bu}-${var.pu}"
    environment  = var.environment
    managed_by   = "opentofu"
    ou           = var.ou
    bu           = var.bu
    pu           = var.pu
  }

  # Resource naming prefix
  name_prefix = "${var.ou}-${var.bu}-${var.pu}-${var.environment}"

  enable_cloud_db_backup = true
  bucket_force_destroy   = true  //Non Prod
  deletion_protection    = false //Non Prod

  # Create startup script with implicit dependency on secret resources
  startup_script = templatefile("${path.module}/startup_script.sh", {
    project_id  = var.project_id
    secret_name = local.mysql_secret_name
    name_prefix = local.name_prefix
    bucket_name = local.enable_cloud_db_backup ? module.gcp_vm.bucket_name : ""
    # This creates an implicit dependency on the secret and IAM binding
    secret_version = google_secret_manager_secret_version.mysql_app_password.id
    iam_binding    = google_secret_manager_secret_iam_binding.mysql_password_access.id
  })
}
