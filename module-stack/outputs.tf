# VM Instance Outputs
output "instance_name" {
  description = "The name of the VM instance"
  value       = google_compute_instance.vm_instance.name
}

output "instance_name_with_uuid" {
  description = "The instance name with UUID (if enabled)"
  value       = local.instance_name_with_uuid
}

output "uuid" {
  description = "The UUID used for resource naming (if enabled)"
  value       = local.uuid
  sensitive   = false
}

output "instance_self_link" {
  description = "The URI of the VM instance"
  value       = google_compute_instance.vm_instance.self_link
}

output "instance_id" {
  description = "The server-assigned unique identifier of the VM instance"
  value       = google_compute_instance.vm_instance.instance_id
}

output "instance_zone" {
  description = "The zone where the VM instance is located"
  value       = google_compute_instance.vm_instance.zone
}

output "instance_machine_type" {
  description = "The machine type of the VM instance"
  value       = google_compute_instance.vm_instance.machine_type
}

output "instance_current_status" {
  description = "Current status of the VM instance"
  value       = google_compute_instance.vm_instance.current_status
}

output "instance_internal_ip" {
  description = "The internal IP address of the VM instance"
  value       = google_compute_instance.vm_instance.network_interface[0].network_ip
}

output "instance_external_ip" {
  description = "The external IP address of the VM instance (if any)"
  value       = length(google_compute_instance.vm_instance.network_interface[0].access_config) > 0 ? google_compute_instance.vm_instance.network_interface[0].access_config[0].nat_ip : null
}

output "cpu_platform" {
  description = "The CPU platform used by the VM instance"
  value       = google_compute_instance.vm_instance.cpu_platform
}

output "instance_metadata_fingerprint" {
  description = "The unique fingerprint of the metadata"
  value       = google_compute_instance.vm_instance.metadata_fingerprint
}

output "instance_tags_fingerprint" {
  description = "The unique fingerprint of the tags"
  value       = google_compute_instance.vm_instance.tags_fingerprint
}

output "instance_label_fingerprint" {
  description = "The unique fingerprint of the labels"
  value       = google_compute_instance.vm_instance.label_fingerprint
}

output "instance_can_ip_forward" {
  description = "Whether the VM instance can send packets with source IP addresses other than its own"
  value       = google_compute_instance.vm_instance.can_ip_forward
}

output "instance_deletion_protection" {
  description = "Whether deletion protection is enabled for the VM instance"
  value       = google_compute_instance.vm_instance.deletion_protection
}

output "instance_enable_display" {
  description = "Whether the VM instance has a display device"
  value       = google_compute_instance.vm_instance.enable_display
}

output "instance_min_cpu_platform" {
  description = "The minimum CPU platform for the VM instance"
  value       = google_compute_instance.vm_instance.min_cpu_platform
}

output "instance_shielded_instance_config" {
  description = "The shielded instance configuration"
  value       = google_compute_instance.vm_instance.shielded_instance_config
}

output "instance_service_account" {
  description = "The service account configuration"
  value       = google_compute_instance.vm_instance.service_account
}

# Boot Disk Outputs
output "boot_disk_name" {
  description = "The name of the boot disk"
  value       = google_compute_instance.vm_instance.boot_disk[0].device_name
}

output "boot_disk_size" {
  description = "The size of the boot disk"
  value       = google_compute_instance.vm_instance.boot_disk[0].initialize_params[0].size
}

output "boot_disk_type" {
  description = "The type of the boot disk"
  value       = google_compute_instance.vm_instance.boot_disk[0].initialize_params[0].type
}

# Cloud Storage Bucket Outputs
output "bucket_name" {
  description = "The name of the Cloud Storage bucket (if created)"
  value       = var.enable_cloud_bucket_storage ? google_storage_bucket.vm_storage_bucket[0].name : null
}

output "bucket_self_link" {
  description = "The URI of the Cloud Storage bucket (if created)"
  value       = var.enable_cloud_bucket_storage ? google_storage_bucket.vm_storage_bucket[0].self_link : null
}

output "bucket_url" {
  description = "The base URL of the Cloud Storage bucket (if created)"
  value       = var.enable_cloud_bucket_storage ? google_storage_bucket.vm_storage_bucket[0].url : null
}

output "bucket_location" {
  description = "The location of the Cloud Storage bucket (if created)"
  value       = var.enable_cloud_bucket_storage ? google_storage_bucket.vm_storage_bucket[0].location : null
}

output "bucket_storage_class" {
  description = "The storage class of the Cloud Storage bucket (if created)"
  value       = var.enable_cloud_bucket_storage ? google_storage_bucket.vm_storage_bucket[0].storage_class : null
}

output "bucket_versioning" {
  description = "The versioning configuration of the Cloud Storage bucket (if created)"
  value       = var.enable_cloud_bucket_storage ? google_storage_bucket.vm_storage_bucket[0].versioning : null
}

output "bucket_lifecycle_rule" {
  description = "The lifecycle rules of the Cloud Storage bucket (if created)"
  value       = var.enable_cloud_bucket_storage ? google_storage_bucket.vm_storage_bucket[0].lifecycle_rule : null
}

output "bucket_labels" {
  description = "The labels of the Cloud Storage bucket (if created)"
  value       = var.enable_cloud_bucket_storage ? google_storage_bucket.vm_storage_bucket[0].labels : null
}

output "bucket_effective_labels" {
  description = "All of the labels (key/value pairs) present on the bucket, including those inherited from the project and organization (if created)"
  value       = var.enable_cloud_bucket_storage ? google_storage_bucket.vm_storage_bucket[0].effective_labels : null
}

# Project and Zone Information
output "project_id" {
  description = "The project ID where the resources are created"
  value       = var.project_id
}

output "region" {
  description = "The region extracted from the zone"
  value       = join("-", slice(split("-", var.zone), 0, 2))
} 