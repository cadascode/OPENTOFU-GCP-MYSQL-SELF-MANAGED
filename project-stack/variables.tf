variable "project_id" {
  description = "The GCP project ID where resources will be created"
  type        = string
}

variable "zone" {
  description = "The GCP zone where the VM instance will be created"
  type        = string
}

variable "environment" {
  description = "The environment (e.g., dev, staging, prod)"
  type        = string
}

variable "ou" {
  description = "Organizational Unit"
  type        = string
}

variable "bu" {
  description = "Business Unit"
  type        = string
}

variable "pu" {
  description = "Product Unit"
  type        = string
}

variable "machine_type" {
  description = "The machine type for the VM instance"
  type        = string
}

variable "boot_disk_size" {
  description = "The size of the boot disk in GB"
  type        = number
}

variable "boot_disk_type" {
  description = "The type of the boot disk"
  type        = string
  default     = "pd-standard"

  validation {
    condition     = contains(["pd-standard", "pd-ssd", "pd-balanced"], var.boot_disk_type)
    error_message = "Boot disk type must be one of: pd-standard, pd-ssd, pd-balanced."
  }
}

variable "service_account_email" {
  description = "The service account email to attach to the VM instance"
  type        = string
}

variable "subnetwork" {
  description = "The subnetwork to attach the VM instance to"
  type        = string
}

