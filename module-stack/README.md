# GCP Compute Engine VM Instance OpenTofu Module

This OpenTofu module creates a Google Cloud Platform (GCP) Compute Engine VM instance with best practices for security and configuration.

## Features

- **UUID-based Resource Naming**: Automatic 6-character UUID generation for unique resource naming
- **Configurable VM Instance**: Full support for all GCP compute instance configurations
- **Shielded VM Security**: Secure boot, vTPM, and integrity monitoring support
- **Cloud Storage Integration**: Automatic bucket creation with VM access (similar to S3-EC2 integration in AWS)
- **Flexible Disk Configuration**: Boot disk, attached disks, and scratch disk support
- **Advanced Network Features**: IPv4/IPv6 support, alias IP ranges, multiple access configs
- **Service Account Integration**: Comprehensive scopes for Cloud Storage and monitoring
- **Security Best Practices**: Deletion protection, uniform bucket access, public access prevention
- **Enterprise Features**: Confidential computing, advanced machine features, reservation affinity
- **Lifecycle Management**: Graceful shutdown, local SSD recovery, termination controls

## Usage

### Basic Usage

```hcl
module "gcp_vm" {
  source = "github.com/your-org/opentofu-gcp-mysql-self-managed//module-stack"

  project_id            = "your-project-id"
  instance_name         = "web-server"
  zone                  = "us-central1-a"
  subnetwork           = "projects/your-project/regions/us-central1/subnetworks/your-subnet"
  service_account_email = "your-service-account@your-project.iam.gserviceaccount.com"
  
  # Cloud Storage Integration (enabled by default)
  enable_cloud_bucket_storage = true
  bucket_location            = "us-central1"
  bucket_storage_class       = "STANDARD"
  
  # Optional: Custom machine type and disk
  machine_type = "e2-medium"
  boot_disk_size = 50
  boot_disk_type = "pd-ssd"
}
```

### Advanced Usage with Security Features

```hcl
module "production_vm" {
  source = "github.com/your-org/opentofu-gcp-mysql-self-managed//module-stack"

  project_id            = "production-project-id"
  instance_name         = "secure-app-server"
  zone                  = "us-central1-a"
  subnetwork           = "projects/production-project-id/regions/us-central1/subnetworks/secure-subnet"
  service_account_email = "secure-vm-sa@production-project-id.iam.gserviceaccount.com"
  
  # Security Configuration
  enable_shielded_vm           = true
  enable_secure_boot          = true
  enable_vtpm                 = true
  enable_integrity_monitoring = true
  deletion_protection         = true
  
  # Cloud Storage Configuration
  enable_cloud_bucket_storage      = true
  bucket_location                 = "us-central1"
  bucket_storage_class            = "STANDARD"
  bucket_versioning_enabled       = false
  bucket_uniform_bucket_level_access = true
  bucket_force_destroy            = false
  public_access_prevention        = "enforced"
  
  # Advanced VM Configuration
  machine_type = "n2-standard-4"
  boot_disk_size = 100
  boot_disk_type = "pd-ssd"
  
  # Network Configuration
  access_config = {
    network_tier = "PREMIUM"
  }
  
  # Advanced Features
  confidential_instance_config = {
    enable_confidential_compute = true
  }
  
  advanced_machine_features = {
    enable_nested_virtualization = true
    threads_per_core = 2
  }
  
  # Lifecycle Management
  graceful_shutdown = {
    enabled = true
    max_duration = {
      seconds = 300
    }
  }
  
  # Labels and Tags
  labels = {
    environment = "production"
    compliance  = "sox"
    team        = "security"
  }
  
  tags = ["secure-vm", "production"]
}
```

### With Additional Storage and Networking

```hcl
module "vm_with_storage" {
  source = "github.com/your-org/opentofu-gcp-mysql-self-managed//module-stack"

  project_id            = "your-project-id"
  instance_name         = "data-processing-vm"
  zone                  = "us-central1-a"
  subnetwork           = "projects/your-project/regions/us-central1/subnetworks/your-subnet"
  service_account_email = "data-vm-sa@your-project.iam.gserviceaccount.com"
  
  # Machine Configuration
  machine_type = "n2-highmem-8"
  
  # Storage Configuration
  boot_disk_size = 200
  boot_disk_type = "pd-ssd"
  enable_scratch_disk = true
  scratch_disk_interface = "NVME"
  
  # Cloud Storage
  enable_cloud_bucket_storage = true
  bucket_storage_class = "NEARLINE"
  bucket_lifecycle_rules = [
    {
      action = {
        type = "SetStorageClass"
        storage_class = "COLDLINE"
      }
      condition = {
        age = 30
      }
    },
    {
      action = {
        type = "Delete"
      }
      condition = {
        age = 365
      }
    }
  ]
  
  # Additional IAM for bucket
  bucket_iam_members = [
    {
      role   = "roles/storage.objectViewer"
      member = "group:data-team@your-company.com"
    }
  ]
  
  # Network Performance
  network_performance_config = {
    total_egress_bandwidth_tier = "TIER_1"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| opentofu | >= 1.9.0 |
| google | >= 6.36.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| enable_uuid | Whether to enable 6-character UUID for resource naming | `bool` | `true` | no |
| project_id | The ID of the project where the VM instance will be created | `string` | n/a | yes |
| instance_name | The name of the VM instance | `string` | n/a | yes |
| machine_type | The machine type to use for the VM instance | `string` | `"e2-small"` | no |
| zone | The zone where the VM instance will be created | `string` | n/a | yes |
| network | The name of the network to attach to the instance | `string` | `"default"` | no |
| subnetwork | The subnetwork to attach the VM instance to | `string` | n/a | yes |
| service_account_email | The service account email to attach to the VM instance | `string` | n/a | yes |
| enable_scratch_disk | Whether to attach a scratch disk to the instance | `bool` | `false` | no |
| scratch_disk_interface | The interface type for the scratch disk | `string` | `"NVME"` | no |
| boot_disk_size | The size of the boot disk in GB | `number` | `30` | no |
| boot_disk_type | The type of the boot disk | `string` | `"pd-standard"` | no |
| boot_disk_image | The image to use for the boot disk | `string` | `"projects/ubuntu-os-cloud/global/images/ubuntu-minimal-2410-oracular-amd64-v20250527"` | no |
| boot_disk_auto_delete | Whether the boot disk should be auto-deleted | `bool` | `true` | no |
| boot_disk_mode | The mode of the boot disk | `string` | `"READ_WRITE"` | no |
| boot_disk_labels | Labels to apply to the boot disk | `map(string)` | `{}` | no |
| tags | Network tags to attach to the VM instance | `list(string)` | `[]` | no |
| labels | Labels to attach to the VM instance | `map(string)` | `{}` | no |
| metadata | Metadata key/value pairs | `map(string)` | `{ enable-oslogin = "false", enable-osconfig = "true", serial-port-enable = "false" }` | no |
| service_account_scopes | The list of scopes to attach to the service account | `list(string)` | See variables.tf | no |
| deletion_protection | Whether to enable deletion protection | `bool` | `true` | no |
| enable_shielded_vm | Whether to enable Shielded VM features | `bool` | `true` | no |
| enable_secure_boot | Whether to enable secure boot | `bool` | `false` | no |
| enable_vtpm | Whether to enable vTPM | `bool` | `true` | no |
| enable_integrity_monitoring | Whether to enable integrity monitoring | `bool` | `true` | no |
| automatic_restart | Whether to automatically restart the instance | `bool` | `true` | no |
| on_host_maintenance | Describes maintenance behavior | `string` | `"MIGRATE"` | no |
| preemptible | Whether the instance is preemptible | `bool` | `false` | no |
| provisioning_model | The provisioning model for the instance | `string` | `"STANDARD"` | no |
| metadata_startup_script | The startup script to run | `string` | `""` | no |
| access_config | Configuration for the access config block | `object` | `{ network_tier = "PREMIUM" }` | no |
| allow_stopping_for_update | Allows Terraform to stop the instance for updates | `bool` | `true` | no |
| can_ip_forward | Whether to allow IP forwarding | `bool` | `false` | no |
| description | A brief description of this resource | `string` | `""` | no |
| hostname | A custom hostname for the instance | `string` | `""` | no |
| guest_accelerator | List of guest accelerator blocks | `list(object)` | `[]` | no |
| enable_display | Enable Virtual Displays | `bool` | `false` | no |
| resource_policies | List of resource policies to attach | `list(string)` | `[]` | no |
| reservation_affinity | Reservation affinity block | `any` | `null` | no |
| confidential_instance_config | Confidential instance config block | `any` | `null` | no |
| min_cpu_platform | Specifies a minimum CPU platform | `string` | `""` | no |
| advanced_machine_features | Advanced machine features block | `any` | `null` | no |
| network_performance_config | Network performance config block | `any` | `null` | no |
| ipv6_access_config | IPv6 access config block | `any` | `null` | no |
| alias_ip_range | Alias IP range block | `any` | `null` | no |
| stack_type | The stack type for network interface | `string` | `"IPV4_ONLY"` | no |
| queue_count | Networking queue count | `number` | `null` | no |
| attached_disk | List of attached_disk blocks | `list(any)` | `[]` | no |
| resource_manager_tags | Resource manager tags | `map(string)` | `{}` | no |
| termination_time | Instance termination timestamp | `string` | `""` | no |
| max_run_duration | The duration of the instance | `object` | `{}` | no |
| on_instance_stop_action | Action on instance stop | `object` | `{}` | no |
| local_ssd_recovery_timeout | Local SSD recovery timeout | `object` | `{}` | no |
| graceful_shutdown | Graceful shutdown settings | `object` | `{}` | no |

### Cloud Storage Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| enable_cloud_bucket_storage | Whether to create a Cloud Storage bucket and attach it to the VM instance | `bool` | `true` | no |
| bucket_name | The name of the Cloud Storage bucket. If not provided, will use instance name | `string` | `""` | no |
| bucket_location | The location of the Cloud Storage bucket | `string` | `"US"` | no |
| bucket_storage_class | The storage class of the Cloud Storage bucket | `string` | `"STANDARD"` | no |
| bucket_versioning_enabled | Whether to enable versioning for the Cloud Storage bucket | `bool` | `false` | no |
| bucket_lifecycle_rules | Lifecycle rules for the Cloud Storage bucket | `list(object)` | Default 365-day deletion rule | no |
| bucket_labels | Labels to apply to the Cloud Storage bucket | `map(string)` | `{}` | no |
| bucket_iam_members | Additional IAM members to grant access to the bucket | `list(object)` | `[]` | no |
| public_access_prevention | Whether to enable public access prevention for the Cloud Storage bucket | `string` | `"enforced"` | no |
| bucket_uniform_bucket_level_access | Whether to enable uniform bucket level access for the Cloud Storage bucket | `bool` | `true` | no |
| bucket_force_destroy | Whether to force destroy the Cloud Storage bucket | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| instance_name | The name of the VM instance |
| instance_name_with_uuid | The instance name with UUID (if enabled) |
| uuid | The UUID used for resource naming (if enabled) |
| instance_self_link | The URI of the VM instance |
| instance_id | The server-assigned unique identifier of the VM instance |
| instance_zone | The zone where the VM instance is located |
| instance_machine_type | The machine type of the VM instance |
| instance_current_status | Current status of the VM instance |
| instance_internal_ip | The internal IP address of the VM instance |
| instance_external_ip | The external IP address of the VM instance (if any) |
| cpu_platform | The CPU platform used by the VM instance |
| instance_metadata_fingerprint | The unique fingerprint of the metadata |
| instance_tags_fingerprint | The unique fingerprint of the tags |
| instance_label_fingerprint | The unique fingerprint of the labels |
| instance_can_ip_forward | Whether the VM instance can send packets with source IP addresses other than its own |
| instance_deletion_protection | Whether deletion protection is enabled for the VM instance |
| instance_enable_display | Whether the VM instance has a display device |
| instance_min_cpu_platform | The minimum CPU platform for the VM instance |
| instance_shielded_instance_config | The shielded instance configuration |
| instance_service_account | The service account configuration |
| boot_disk_name | The name of the boot disk |
| boot_disk_size | The size of the boot disk |
| boot_disk_type | The type of the boot disk |
| bucket_name | The name of the Cloud Storage bucket (if created) |
| bucket_self_link | The URI of the Cloud Storage bucket (if created) |
| bucket_url | The base URL of the Cloud Storage bucket (if created) |
| bucket_location | The location of the Cloud Storage bucket (if created) |
| bucket_storage_class | The storage class of the Cloud Storage bucket (if created) |
| bucket_versioning | The versioning configuration of the Cloud Storage bucket (if created) |
| bucket_lifecycle_rule | The lifecycle rules of the Cloud Storage bucket (if created) |
| bucket_labels | The labels of the Cloud Storage bucket (if created) |
| bucket_effective_labels | All labels present on the bucket, including inherited ones (if created) |
| project_id | The project ID where the resources are created |
| region | The region extracted from the zone |

## Security Features

This module implements several security best practices:

### 1. Shielded VM Features
- **Secure Boot**: Optional UEFI secure boot (disabled by default for compatibility)
- **vTPM**: Virtual Trusted Platform Module (enabled by default)
- **Integrity Monitoring**: Boot and kernel integrity monitoring (enabled by default)

### 2. Instance Security
- **Deletion Protection**: Enabled by default to prevent accidental deletion
- **UUID-based Naming**: Automatic unique resource naming to prevent conflicts
- **Metadata Security**: Disabled OS Login and serial port by default, enabled OS Config
- **Network Security**: IP forwarding disabled by default

### 3. Cloud Storage Security
- **Uniform Bucket-Level Access**: Enforced by default for consistent IAM
- **Public Access Prevention**: Enforced by default to prevent public exposure
- **Automatic IAM Binding**: VM service account gets objectAdmin role on bucket
- **Configurable Lifecycle Rules**: Default 365-day deletion rule
- **Force Destroy Protection**: Disabled by default for production safety

### 4. Service Account Integration
- **Comprehensive Scopes**: Includes Cloud Storage, Logging, Monitoring, and Compute scopes
- **Least Privilege**: Only necessary scopes for VM and storage operations
- **Automatic Bucket Access**: Service account automatically gets bucket permissions

### 5. Advanced Security Options
- **Confidential Computing**: Support for confidential VM instances
- **Advanced Machine Features**: Nested virtualization and thread control
- **Network Security**: Premium network tier and configurable access controls
- **Encryption**: Google-managed encryption by default

## Resource Naming Convention

When `enable_uuid` is `true` (default), resources are named as follows:
- VM Instance: `{instance_name}-{uuid}-vm`
- Boot Disk: `{instance_name}-{uuid}-boot-disk`
- Storage Bucket: `{instance_name}-{uuid}-storage` (or custom `bucket_name`)

This ensures unique resource names and prevents conflicts in shared projects.

## Best Practices

1. **Always use deletion protection in production**
2. **Enable Shielded VM features for enhanced security**
3. **Use premium network tier for better performance and security**
4. **Configure appropriate service account scopes**
5. **Use uniform bucket-level access for consistent IAM**
6. **Implement lifecycle rules for cost optimization**
7. **Use labels for resource organization and cost tracking**
8. **Enable versioning only when needed to control costs**

## License

This module is released under the MIT License. See the LICENSE file for details.