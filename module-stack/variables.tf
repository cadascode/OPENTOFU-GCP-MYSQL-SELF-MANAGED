variable "enable_uuid" {
  description = "Whether to enable 6-character UUID for resource naming"
  type        = bool
  default     = true
}

variable "project_id" {
  description = "The ID of the project where the VM instance will be created"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "Project ID must be 6-30 characters, start with a letter, and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "instance_name" {
  description = "The name of the VM instance"
  type        = string

  validation {
    condition     = can(regex("^[a-z]([a-z0-9-]*[a-z0-9])?$", var.instance_name)) && length(var.instance_name) <= 63
    error_message = "Instance name must start with a lowercase letter, be 1-63 characters long, and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "machine_type" {
  description = "The machine type to use for the VM instance"
  type        = string
  default     = "e2-small"

  validation {
    condition = contains([
      "e2-micro", "e2-small", "e2-medium", "e2-standard-2", "e2-standard-4", "e2-standard-8", "e2-standard-16",
      "n1-standard-1", "n1-standard-2", "n1-standard-4", "n1-standard-8", "n1-standard-16",
      "n2-standard-2", "n2-standard-4", "n2-standard-8", "n2-standard-16", "n2-standard-32",
      "n2d-standard-2", "n2d-standard-4", "n2d-standard-8", "n2d-standard-16", "n2d-standard-32",
      "c2-standard-4", "c2-standard-8", "c2-standard-16", "c2-standard-30", "c2-standard-60"
    ], var.machine_type) || can(regex("^[a-z0-9]+-[a-z0-9]+-[0-9]+$", var.machine_type))
    error_message = "Machine type must be a valid GCP machine type."
  }
}

variable "zone" {
  description = "The zone where the VM instance will be created"
  type        = string

  validation {
    condition     = can(regex("^[a-z]+-[a-z0-9]+-[a-z]$", var.zone))
    error_message = "Zone must be a valid GCP zone format (e.g., us-central1-a)."
  }
}

variable "network" {
  description = "The name of the network to attach to the instance"
  type        = string
  default     = "default"
}

variable "subnetwork" {
  description = "The subnetwork to attach the VM instance to"
  type        = string
}

variable "service_account_email" {
  description = "The service account email to attach to the VM instance"
  type        = string
}

variable "enable_scratch_disk" {
  description = "Whether to attach a scratch disk to the instance"
  type        = bool
  default     = false
}

variable "scratch_disk_interface" {
  description = "The interface type for the scratch disk. Can be either 'SCSI' or 'NVME'"
  type        = string
  default     = "NVME"
}

variable "boot_disk_size" {
  description = "The size of the boot disk in GB"
  type        = number
  default     = 30
}

variable "boot_disk_type" {
  description = "The type of the boot disk"
  type        = string
  default     = "pd-standard"
}

variable "boot_disk_image" {
  description = "The image to use for the boot disk"
  type        = string
  default     = "projects/ubuntu-os-cloud/global/images/ubuntu-minimal-2410-oracular-amd64-v20250527"
}

variable "boot_disk_auto_delete" {
  description = "Whether the boot disk should be auto-deleted when the instance is deleted"
  type        = bool
  default     = true
}

variable "boot_disk_mode" {
  description = "The mode of the boot disk"
  type        = string
  default     = "READ_WRITE"
}

variable "boot_disk_labels" {
  description = "Labels to apply to the boot disk"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Network tags to attach to the VM instance"
  type        = list(string)
  default     = []
}

variable "labels" {
  description = "Labels to attach to the VM instance"
  type        = map(string)
  default     = {}
}

variable "metadata" {
  description = "Metadata key/value pairs to make available from within the VM instance"
  type        = map(string)
  default = {
    enable-oslogin     = "false"
    enable-osconfig    = "true"
    serial-port-enable = "false"
  }
}

variable "service_account_scopes" {
  description = "The list of scopes to attach to the service account"
  type        = list(string)
  default = [
    "https://www.googleapis.com/auth/devstorage.read_write",
    "https://www.googleapis.com/auth/logging.write",
    "https://www.googleapis.com/auth/monitoring.write",
    "https://www.googleapis.com/auth/service.management.readonly",
    "https://www.googleapis.com/auth/servicecontrol",
    "https://www.googleapis.com/auth/trace.append",
    "https://www.googleapis.com/auth/compute",
    "https://www.googleapis.com/auth/cloud-platform"
  ]
}

variable "deletion_protection" {
  description = "Whether to enable deletion protection for the VM instance"
  type        = bool
  default     = true
}

variable "enable_shielded_vm" {
  description = "Whether to enable Shielded VM features"
  type        = bool
  default     = true
}

variable "enable_secure_boot" {
  description = "Whether to enable secure boot for the VM instance"
  type        = bool
  default     = false
}

variable "enable_vtpm" {
  description = "Whether to enable vTPM for the VM instance"
  type        = bool
  default     = true
}

variable "enable_integrity_monitoring" {
  description = "Whether to enable integrity monitoring for the VM instance"
  type        = bool
  default     = true
}

variable "network_tier" {
  description = "The network tier to use for the VM instance"
  type        = string
  default     = "PREMIUM"
}

variable "automatic_restart" {
  description = "Whether the instance should be automatically restarted if it was terminated by Compute Engine"
  type        = bool
  default     = true
}

variable "on_host_maintenance" {
  description = "Describes maintenance behavior for the instance"
  type        = string
  default     = "MIGRATE"
}

variable "preemptible" {
  description = "Whether the instance is preemptible"
  type        = bool
  default     = false
}

variable "provisioning_model" {
  description = "The provisioning model for the instance"
  type        = string
  default     = "STANDARD"
}

variable "metadata_startup_script" {
  description = "The startup script to run when the instance boots up"
  type        = string
  default     = ""
}

variable "access_config" {
  description = "Configuration for the access config block"
  type = object({
    nat_ip       = optional(string)
    network_tier = optional(string)
  })
  default = {
    network_tier = "PREMIUM"
  }
}

variable "allow_stopping_for_update" {
  description = "Allows Terraform to stop the instance to update its properties. Highly recommended for production."
  type        = bool
  default     = true
}

variable "can_ip_forward" {
  description = "Whether to allow sending/receiving packets with non-matching source/destination IPs. Defaults to false for security."
  type        = bool
  default     = false
}

variable "description" {
  description = "A brief description of this resource."
  type        = string
  default     = ""
}

variable "hostname" {
  description = "A custom hostname for the instance. Must be RFC-1035 valid."
  type        = string
  default     = ""
}

variable "guest_accelerator" {
  description = "List of guest accelerator blocks (GPU, TPU, etc). Each item is a map with 'type' and 'count'."
  type = list(object({
    type  = string
    count = number
  }))
  default = []
}

variable "enable_display" {
  description = "Enable Virtual Displays on this instance."
  type        = bool
  default     = false
}

variable "resource_policies" {
  description = "A list of self_links of resource policies to attach to the instance."
  type        = list(string)
  default     = []
}

variable "reservation_affinity" {
  description = "Reservation affinity block. See GCP docs for structure."
  type        = any
  default     = null
}

variable "confidential_instance_config" {
  description = "Confidential instance config block. See GCP docs for structure."
  type        = any
  default     = null
}

variable "min_cpu_platform" {
  description = "Specifies a minimum CPU platform for the VM instance."
  type        = string
  default     = ""
}

variable "advanced_machine_features" {
  description = "Advanced machine features block. See GCP docs for structure."
  type        = any
  default     = null
}

variable "network_performance_config" {
  description = "Network performance config block. See GCP docs for structure."
  type        = any
  default     = null
}

variable "ipv6_access_config" {
  description = "IPv6 access config block. See GCP docs for structure."
  type        = any
  default     = null
}

variable "alias_ip_range" {
  description = "Alias IP range block. See GCP docs for structure."
  type        = any
  default     = null
}

variable "stack_type" {
  description = "The stack type for this network interface. Values: IPV4_IPV6, IPV6_ONLY, IPV4_ONLY."
  type        = string
  default     = "IPV4_ONLY"
}

variable "queue_count" {
  description = "Networking queue count for the network interface."
  type        = number
  default     = null
}

variable "security_policy" {
  description = "A full or partial URL to a security policy to add to this instance."
  type        = string
  default     = ""
}

variable "network_attachment" {
  description = "The URL of the network attachment for this interface."
  type        = string
  default     = ""
}

variable "instance_encryption_key" {
  description = "Instance encryption key block. See GCP docs for structure."
  type        = any
  default     = null
}

variable "attached_disk" {
  description = "List of attached_disk blocks. Each item is a map. See GCP docs for structure."
  type        = list(any)
  default     = []
}

variable "params" {
  description = "Additional instance parameters. See GCP docs for structure."
  type        = any
  default     = null
}

variable "resource_manager_tags" {
  description = "Resource manager tags for the instance."
  type        = map(string)
  default     = {}
}

variable "termination_time" {
  description = "Specifies the timestamp, when the instance will be terminated, in RFC3339 text format."
  type        = string
  default     = ""
}

variable "max_run_duration" {
  description = "The duration of the instance. Structure: { seconds = number, nanos = number }"
  type = object({
    seconds = optional(number)
    nanos   = optional(number)
  })
  default = {}
}

variable "on_instance_stop_action" {
  description = "Action to be performed when the instance is terminated using max_run_duration. Structure: { discard_local_ssd = bool }"
  type = object({
    discard_local_ssd = optional(bool)
  })
  default = {}
}

variable "local_ssd_recovery_timeout" {
  description = "Specifies the maximum amount of time a Local Ssd Vm should wait while recovery of the Local Ssd state is attempted. Structure: { seconds = number, nanos = number }"
  type = object({
    seconds = optional(number)
    nanos   = optional(number)
  })
  default = {}
}

variable "graceful_shutdown" {
  description = "Settings for the instance to perform a graceful shutdown. Structure: { enabled = bool, max_duration = object({ seconds = number, nanos = number }) }"
  type = object({
    enabled      = optional(bool)
    max_duration = optional(object({ seconds = number, nanos = number }))
  })
  default = {}
}

# Cloud Storage Bucket Configuration
variable "enable_cloud_bucket_storage" {
  description = "Whether to create a Cloud Storage bucket and attach it to the VM instance"
  type        = bool
  default     = true
}

variable "bucket_name" {
  description = "The name of the Cloud Storage bucket. If not provided, will use instance name"
  type        = string
  default     = ""

  validation {
    condition = var.bucket_name == "" || (
      can(regex("^[a-z0-9][a-z0-9._-]*[a-z0-9]$", var.bucket_name)) &&
      length(var.bucket_name) >= 3 &&
      length(var.bucket_name) <= 63 &&
      !can(regex("\\.\\.|\\.\\-|\\-\\.", var.bucket_name)) &&
      !can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+$", var.bucket_name))
    )
    error_message = "Bucket name must be 3-63 characters, contain only lowercase letters, numbers, dots, and hyphens, and follow GCS naming conventions."
  }
}

variable "bucket_location" {
  description = "The location of the Cloud Storage bucket"
  type        = string
  default     = "US"

  validation {
    condition = contains([
      "US", "EU", "ASIA",
      "us-central1", "us-east1", "us-east4", "us-west1", "us-west2", "us-west3", "us-west4",
      "europe-west1", "europe-west2", "europe-west3", "europe-west4", "europe-west6", "europe-north1",
      "asia-east1", "asia-east2", "asia-northeast1", "asia-northeast2", "asia-northeast3", "asia-south1", "asia-southeast1", "asia-southeast2"
    ], var.bucket_location)
    error_message = "Bucket location must be a valid GCS region or multi-region."
  }
}

variable "bucket_storage_class" {
  description = "The storage class of the Cloud Storage bucket"
  type        = string
  default     = "STANDARD"

  validation {
    condition     = contains(["STANDARD", "NEARLINE", "COLDLINE", "ARCHIVE"], var.bucket_storage_class)
    error_message = "Storage class must be one of: STANDARD, NEARLINE, COLDLINE, ARCHIVE."
  }
}

variable "bucket_versioning_enabled" {
  description = "Whether to enable versioning for the Cloud Storage bucket"
  type        = bool
  default     = false
}

variable "bucket_lifecycle_rules" {
  description = "Lifecycle rules for the Cloud Storage bucket"
  type = list(object({
    action = object({
      type          = string
      storage_class = optional(string)
    })
    condition = object({
      age                        = optional(number)
      created_before             = optional(string)
      with_state                 = optional(string)
      matches_storage_class      = optional(list(string))
      num_newer_versions         = optional(number)
      custom_time_before         = optional(string)
      days_since_custom_time     = optional(number)
      days_since_noncurrent_time = optional(number)
      noncurrent_time_before     = optional(string)
    })
  }))
  default = [
    {
      action = {
        type = "Delete"
      }
      condition = {
        age = 365
      }
    }
  ]
}

variable "bucket_labels" {
  description = "Labels to apply to the Cloud Storage bucket"
  type        = map(string)
  default     = {}
}

variable "bucket_iam_members" {
  description = "Additional IAM members to grant access to the bucket"
  type = list(object({
    role   = string
    member = string
  }))
  default = []
}

variable "public_access_prevention" {
  description = "Whether to enable public access prevention for the Cloud Storage bucket"
  type        = string
  default     = "enforced"
}

variable "bucket_uniform_bucket_level_access" {
  description = "Whether to enable uniform bucket level access for the Cloud Storage bucket"
  type        = bool
  default     = true
}

variable "bucket_force_destroy" {
  description = "Whether to force destroy the Cloud Storage bucket"
  type        = bool
  default     = false
}

