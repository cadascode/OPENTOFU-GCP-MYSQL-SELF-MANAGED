resource "random_id" "uuid" {
  count       = var.enable_uuid ? 1 : 0
  byte_length = 3

  keepers = {
    instance_name = var.instance_name
  }
}

locals {
  uuid                    = var.enable_uuid && length(random_id.uuid) > 0 ? random_id.uuid[0].hex : ""
  instance_name_with_uuid = var.enable_uuid ? "${var.instance_name}-${local.uuid}" : var.instance_name
  bucket_name             = var.bucket_name != "" ? var.bucket_name : "${local.instance_name_with_uuid}-storage"
}

resource "google_compute_instance" "vm_instance" {
  name         = "${local.instance_name_with_uuid}-vm"
  machine_type = var.machine_type
  zone         = var.zone
  project      = var.project_id

  description               = var.description != "" ? var.description : null
  hostname                  = var.hostname != "" ? "${var.hostname}-${local.uuid}" : null
  min_cpu_platform          = var.min_cpu_platform != "" ? var.min_cpu_platform : null
  allow_stopping_for_update = var.allow_stopping_for_update
  can_ip_forward            = var.can_ip_forward
  enable_display            = var.enable_display
  resource_policies         = var.resource_policies
  tags                      = var.tags
  labels                    = merge(var.labels, var.enable_uuid ? { uuid = local.uuid } : {})
  deletion_protection       = var.deletion_protection

  boot_disk {
    auto_delete = var.boot_disk_auto_delete
    device_name = "${local.instance_name_with_uuid}-boot-disk"
    initialize_params {
      image  = var.boot_disk_image
      size   = var.boot_disk_size
      type   = var.boot_disk_type
      labels = merge(var.boot_disk_labels, var.enable_uuid ? { uuid = local.uuid } : {})
    }
    mode = var.boot_disk_mode
  }

  dynamic "attached_disk" {
    for_each = var.attached_disk
    content {
      source      = lookup(attached_disk.value, "source", null)
      device_name = lookup(attached_disk.value, "device_name", null)
      mode        = lookup(attached_disk.value, "mode", null)
      # Add more fields as needed
    }
  }

  dynamic "scratch_disk" {
    for_each = var.enable_scratch_disk ? [1] : []
    content {
      interface = var.scratch_disk_interface
    }
  }

  network_interface {
    network     = var.network
    subnetwork  = var.subnetwork
    stack_type  = var.stack_type
    queue_count = var.queue_count

    dynamic "access_config" {
      for_each = var.access_config != null ? [var.access_config] : []
      content {
        nat_ip       = access_config.value.nat_ip
        network_tier = access_config.value.network_tier
      }
    }
    dynamic "ipv6_access_config" {
      for_each = var.ipv6_access_config != null ? var.ipv6_access_config : []
      content {
        network_tier                = lookup(ipv6_access_config.value, "network_tier", null)
        external_ipv6               = lookup(ipv6_access_config.value, "external_ipv6", null)
        external_ipv6_prefix_length = lookup(ipv6_access_config.value, "external_ipv6_prefix_length", null)
        name                        = lookup(ipv6_access_config.value, "name", null)
        public_ptr_domain_name      = lookup(ipv6_access_config.value, "public_ptr_domain_name", null)
      }
    }
    dynamic "alias_ip_range" {
      for_each = var.alias_ip_range != null ? var.alias_ip_range : []
      content {
        ip_cidr_range         = lookup(alias_ip_range.value, "ip_cidr_range", null)
        subnetwork_range_name = lookup(alias_ip_range.value, "subnetwork_range_name", null)
      }
    }
  }

  service_account {
    email  = var.service_account_email
    scopes = var.service_account_scopes
  }

  metadata = merge(
    var.metadata,
    var.metadata_startup_script != "" ? {
      startup-script = var.metadata_startup_script
    } : {}
  )

  scheduling {
    automatic_restart   = var.automatic_restart
    on_host_maintenance = var.on_host_maintenance
    preemptible         = var.preemptible
    provisioning_model  = var.provisioning_model
    # Node affinities, min_node_cpus, etc. can be added as needed
  }

  dynamic "shielded_instance_config" {
    for_each = var.enable_shielded_vm ? [1] : []
    content {
      enable_secure_boot          = var.enable_secure_boot
      enable_vtpm                 = var.enable_vtpm
      enable_integrity_monitoring = var.enable_integrity_monitoring
    }
  }

  dynamic "guest_accelerator" {
    for_each = var.guest_accelerator
    content {
      type  = guest_accelerator.value.type
      count = guest_accelerator.value.count
    }
  }

  dynamic "confidential_instance_config" {
    for_each = var.confidential_instance_config != null ? [var.confidential_instance_config] : []
    content {
      enable_confidential_compute = lookup(confidential_instance_config.value, "enable_confidential_compute", null)
      confidential_instance_type  = lookup(confidential_instance_config.value, "confidential_instance_type", null)
    }
  }

  dynamic "advanced_machine_features" {
    for_each = var.advanced_machine_features != null ? [var.advanced_machine_features] : []
    content {
      enable_nested_virtualization = lookup(advanced_machine_features.value, "enable_nested_virtualization", null)
      threads_per_core             = lookup(advanced_machine_features.value, "threads_per_core", null)
      turbo_mode                   = lookup(advanced_machine_features.value, "turbo_mode", null)
      visible_core_count           = lookup(advanced_machine_features.value, "visible_core_count", null)
      performance_monitoring_unit  = lookup(advanced_machine_features.value, "performance_monitoring_unit", null)
      enable_uefi_networking       = lookup(advanced_machine_features.value, "enable_uefi_networking", null)
    }
  }

  dynamic "network_performance_config" {
    for_each = var.network_performance_config != null ? [var.network_performance_config] : []
    content {
      total_egress_bandwidth_tier = lookup(network_performance_config.value, "total_egress_bandwidth_tier", null)
    }
  }

  dynamic "reservation_affinity" {
    for_each = var.reservation_affinity != null ? [var.reservation_affinity] : []
    content {
      type = lookup(reservation_affinity.value, "type", null)
      dynamic "specific_reservation" {
        for_each = lookup(reservation_affinity.value, "specific_reservation", null) != null ? [reservation_affinity.value.specific_reservation] : []
        content {
          key    = lookup(specific_reservation.value, "key", null)
          values = lookup(specific_reservation.value, "values", null)
        }
      }
    }
  }
}

# Cloud Storage Bucket
resource "google_storage_bucket" "vm_storage_bucket" {
  count    = var.enable_cloud_bucket_storage ? 1 : 0
  name     = local.bucket_name
  location = var.bucket_location
  project  = var.project_id

  storage_class               = var.bucket_storage_class
  uniform_bucket_level_access = var.bucket_uniform_bucket_level_access
  force_destroy               = var.bucket_force_destroy

  # Prevent public access
  public_access_prevention = var.public_access_prevention

  versioning {
    enabled = var.bucket_versioning_enabled
  }

  dynamic "lifecycle_rule" {
    for_each = var.bucket_lifecycle_rules
    content {
      action {
        type          = lifecycle_rule.value.action.type
        storage_class = lifecycle_rule.value.action.storage_class
      }
      condition {
        age                        = lifecycle_rule.value.condition.age
        created_before             = lifecycle_rule.value.condition.created_before
        with_state                 = lifecycle_rule.value.condition.with_state
        matches_storage_class      = lifecycle_rule.value.condition.matches_storage_class
        num_newer_versions         = lifecycle_rule.value.condition.num_newer_versions
        custom_time_before         = lifecycle_rule.value.condition.custom_time_before
        days_since_custom_time     = lifecycle_rule.value.condition.days_since_custom_time
        days_since_noncurrent_time = lifecycle_rule.value.condition.days_since_noncurrent_time
        noncurrent_time_before     = lifecycle_rule.value.condition.noncurrent_time_before
      }
    }
  }

  labels = merge(
    var.bucket_labels,
    var.labels,  # Include all VM labels for consistency
    var.enable_uuid ? { uuid = local.uuid } : {},
    {
      environment = "managed-by-opentofu"
      vm-instance = local.instance_name_with_uuid
    }
  )
}

# IAM binding to give VM instance access to the bucket
resource "google_storage_bucket_iam_member" "vm_bucket_access" {
  count  = var.enable_cloud_bucket_storage ? 1 : 0
  bucket = google_storage_bucket.vm_storage_bucket[0].name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${var.service_account_email}"

  depends_on = [google_storage_bucket.vm_storage_bucket]
}

# Additional IAM members for the bucket
resource "google_storage_bucket_iam_member" "additional_bucket_access" {
  count  = var.enable_cloud_bucket_storage ? length(var.bucket_iam_members) : 0
  bucket = google_storage_bucket.vm_storage_bucket[0].name
  role   = var.bucket_iam_members[count.index].role
  member = var.bucket_iam_members[count.index].member

  depends_on = [google_storage_bucket.vm_storage_bucket]
}
