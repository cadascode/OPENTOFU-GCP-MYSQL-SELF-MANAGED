# MySQL Self-Managed Infrastructure - Implementation Stack

This Terraform configuration deploys a production-ready Google Cloud Platform (GCP) VM instance with enhanced security features, integrated Cloud Storage, and secure MySQL 8.0 installation for web applications requiring dedicated database hosting.

## 🔒 Remote Backend Configuration

This infrastructure uses Google Cloud Storage (GCS) as the remote backend for Terraform state management, following enterprise security best practices.

### Backend Features
- **State Locking**: Automatic state locking prevents concurrent modifications
- **Encryption**: State files encrypted at rest using Google-managed keys
- **Versioning**: Complete state history with rollback capabilities
- **Team Collaboration**: Shared state accessible by authorized team members
- **Backup & Recovery**: Automatic versioning with 30-day retention policy

### Backend Setup Process

#### 1. Bootstrap the State Bucket (One-time setup)

⚠️ **Important**: This must be done BEFORE enabling the remote backend configuration.

```bash
# Step 1: Create a separate bootstrap configuration for the state bucket
# Create bootstrap.tf with the bucket configuration

# Step 2: Apply the bootstrap configuration
tofu init
tofu apply -target=google_storage_bucket.terraform_state
tofu apply -target=google_storage_bucket_iam_member.terraform_state_admin

# Step 3: Verify bucket creation
gsutil ls gs://terraform-state-mysql-infrastructure
```

#### 2. Initialize Remote Backend

```bash
# After bucket is created, initialize the remote backend
tofu init -migrate-state

# When prompted, confirm to migrate existing state to the remote backend
# Answer 'yes' to copy existing state to the new backend
```

#### 3. Comment Out Bootstrap Resources

```bash
# Comment out the bootstrap resources in bootstrap.tf
# This prevents managing the state bucket within the same configuration
# The bucket will now be managed outside of this Terraform configuration
```

### Backend Configuration Details

```hcl
backend "gcs" {
  bucket  = "terraform-state-mysql-infrastructure"
  prefix  = "environment/prod"
}
```

#### Security Considerations

| Feature | Implementation | Security Benefit |
|---------|----------------|------------------|
| **Bucket Access** | IAM-based with least privilege | Only authorized service accounts can access state |
| **Encryption** | Google-managed keys | State files encrypted at rest |
| **Versioning** | Enabled with lifecycle management | State history with automatic cleanup |
| **Access Logging** | Cloud Audit Logs integration | Complete audit trail of state access |

#### Troubleshooting Backend Issues

```bash
# If backend initialization fails, check service account permissions
gcloud projects get-iam-policy PROJECT_ID --flatten="bindings[].members" --filter="bindings.members:SERVICE_ACCOUNT_EMAIL"

# Verify bucket exists and is accessible
gsutil ls -b gs://terraform-state-mysql-infrastructure

# Force backend reconfiguration if needed
tofu init -reconfigure

# Import existing state (if state was lost)
tofu import google_storage_bucket.terraform_state terraform-state-mysql-infrastructure
```

### Multi-Environment State Management

The backend uses environment-specific prefixes for state isolation:

- **Production**: `environment/prod/`
- **Staging**: `environment/staging/`
- **Development**: `environment/dev/`

This ensures complete isolation between environments while using the same state bucket.

## 🛡️ Security Features

This deployment implements security best practices for cloud infrastructure:

### VM Security
- **Shielded VM**: Enabled with vTPM and integrity monitoring
- **Secure Boot**: Configurable (requires supported OS images)
- **OS Login**: Enabled for secure SSH access
- **Deletion Protection**: Enabled to prevent accidental VM deletion
- **Service Account**: Uses least-privilege principle with specific scopes

### Database Security
- **Google Secret Manager**: MySQL application user password stored securely
- **Random Password Generation**: 16-character complex password automatically generated
- **IAM-based Access**: Service account granted minimal permissions to access secret
- **No Hardcoded Credentials**: All sensitive data retrieved at runtime from Secret Manager
- **User Separation**: Dedicated application user separate from root user

### Storage Security
- **Public Access Prevention**: Enforced on Cloud Storage bucket
- **Uniform Bucket-Level Access**: Enabled for simplified IAM management
- **Versioning**: Enabled for data protection and recovery
- **Encryption**: Google-managed encryption (customer-managed KMS optional)
- **Lifecycle Management**: Automated cost optimization rules

### Network Security
- **Premium Network Tier**: Enhanced performance and security
- **IP Forwarding**: Disabled by default for security
- **Configurable Public IP**: Can be disabled for private deployments

## 🗄️ MySQL Database Configuration

### Automated Installation
The VM automatically installs MySQL 8.0 via startup script with the following features:

- **Secure Installation**: Password retrieved from Google Secret Manager
- **Latest Version**: MySQL 8.0.42 with all security patches
- **Automated Configuration**: Pre-configured with production-ready settings
- **Dependency Management**: Automatic handling of required system packages
- **Logging**: Complete installation logs available at `/var/log/startup-script.log`

### Password Management
```bash
# Password is automatically generated and stored in Secret Manager
# Secret name format: {project-prefix}-mysql-app-password-{uuid}
# Access via: gcloud secrets versions access latest --secret="secret-name"
```

### Database Access
After VM deployment, MySQL is accessible with:
- **User**: appuser (for applications)
- **Root User**: Local access only (passwordless for administration)
- **Password**: Retrieved from Secret Manager
- **Service**: mysql (systemd service enabled and started)
- **Configuration**: Default MySQL 8.0 settings with caching_sha2_password authentication

### Backup System
- **Automated Backups**: Daily backups to Cloud Storage at 2:00 AM UTC
- **Local Retention**: 3 most recent local backups
- **Cloud Retention**: 30 days in Cloud Storage
- **Compression**: Backups are compressed using gzip
- **Monitoring**: Comprehensive logging in `/opt/mysql-backup/backup.log`

## 🚀 Quick Start

1. **Prerequisites**:
   - OpenTofu >= 1.9.0
   - GCP CLI configured with appropriate permissions
   - Service account with necessary IAM roles:
     - `roles/secretmanager.secretAccessor`
     - `roles/compute.instanceAdmin`
     - `roles/storage.admin`

2. **Configure**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your project values
   ```

3. **Deploy**:
   ```bash
   tofu init
   tofu plan
   tofu apply
   ```

4. **Verify Deployment**:
   ```bash
   # Check VM status
   tofu output gcp_vm_output
   
   # Check MySQL secret information
   tofu output mysql_secret_info
   
   # Check backup configuration
   tofu output mysql_backup_info
   ```

5. **Access MySQL**:
   ```bash
   # SSH to the VM
   gcloud compute ssh [INSTANCE-NAME] --zone=[ZONE]
   
   # Get MySQL password
   MYSQL_PASSWORD=$(gcloud secrets versions access latest --secret="[SECRET-NAME]")
   
   # Connect to MySQL
   mysql -u appuser -p$MYSQL_PASSWORD
   ```

## 📋 Configuration

### Core VM Configuration

| Variable | Description | Default | Production Recommendation |
|----------|-------------|---------|---------------------------|
| `project_id` | GCP Project ID | - | Your project ID |
| `zone` | GCP Zone | - | `us-central1-a` or closest to users |
| `environment` | Environment name | - | `prod`, `staging`, `dev` |
| `machine_type` | VM machine type | `e2-small` | `e2-medium` for production |
| `boot_disk_size` | Boot disk size (GB) | `20` | `50-100` for production |
| `service_account_email` | Service account email | - | Dedicated SA with minimal permissions |

### Organization Structure

| Variable | Description | Example |
|----------|-------------|---------|
| `ou` | Organizational Unit | `myorg` |
| `bu` | Business Unit | `engineering` |
| `pu` | Product Unit | `webapp` |

### Advanced Configuration

```hcl
# High-performance configuration
machine_type = "n2-standard-4"
boot_disk_size = 100
boot_disk_type = "pd-ssd"

# Security-focused configuration
deletion_protection = true
enable_shielded_vm = true
```

## 🔧 Customization

### Startup Script Customization

The `startup_script.sh` file can be modified to:
- Change MySQL configuration
- Add additional software packages
- Modify backup schedules
- Add monitoring agents

### Backup Configuration

Edit the backup section in `startup_script.sh`:
```bash
# Change backup schedule (current: daily at 2 AM)
echo "0 2 * * * /opt/mysql-backup/mysql_backup.sh" | crontab -

# Modify retention (current: 30 days cloud, 3 local)
CLOUD_RETENTION_DAYS=30
LOCAL_BACKUP_COUNT=3
```

## 🏗️ Module Integration

This implementation uses the `../module-stack` directory as the source for the VM module. The module provides:

- **Reusable Components**: Standard VM configuration with best practices
- **Configurable Options**: Extensive customization through variables
- **Security Defaults**: Secure-by-default configuration
- **Cloud Storage Integration**: Automatic bucket creation and IAM setup

## 📊 Outputs

The configuration provides several useful outputs:

### VM Information
- Instance name, IP addresses, machine type
- Zone, deletion protection status
- Service account information

### MySQL Information
- Secret Manager secret name and ID
- Application username
- Connection information

### Backup Information
- Backup schedule and location
- Script paths and log locations
- Manual backup command

## 🔍 Monitoring and Maintenance

### Log Locations
- **Startup Script**: `/var/log/startup-script.log`
- **MySQL Backup**: `/opt/mysql-backup/backup.log`
- **Cron Jobs**: `/opt/mysql-backup/cron.log`
- **MySQL Error Log**: `/var/log/mysql/error.log`

### Health Checks
```bash
# Check VM status
gcloud compute instances describe INSTANCE_NAME --zone=ZONE

# Check MySQL service
sudo systemctl status mysql

# Check backup system
sudo crontab -l
ls -la /opt/mysql-backup/

# Test backup manually
sudo /opt/mysql-backup/mysql_backup.sh
```

### Maintenance Tasks
- **Regular Backups**: Automated via cron
- **Security Updates**: Apply OS updates regularly
- **MySQL Updates**: Monitor for MySQL security updates
- **Certificate Rotation**: Rotate service account keys periodically

## 🔒 Security Best Practices

### Pre-deployment Checklist
- [ ] Service account has minimal required permissions
- [ ] VPC and firewall rules are properly configured
- [ ] Backup retention policies meet compliance requirements
- [ ] Secret Manager access is properly restricted
- [ ] VM deletion protection is enabled for production

### Post-deployment Security
- [ ] Verify MySQL is not accessible from public internet
- [ ] Confirm backups are working and encrypted
- [ ] Set up monitoring and alerting
- [ ] Regular security assessments
- [ ] Keep OS and MySQL updated

## 🆘 Troubleshooting

### Common Issues and Solutions

1. **Startup Script Fails**
   ```bash
   # Check logs
   sudo tail -f /var/log/startup-script.log
   
   # Verify Secret Manager access
   gcloud auth list
   gcloud secrets versions access latest --secret="SECRET_NAME"
   ```

2. **MySQL Connection Issues**
   ```bash
   # Check MySQL status
   sudo systemctl status mysql
   
   # Verify user exists
   sudo mysql -e "SELECT User, Host FROM mysql.user WHERE User='appuser';"
   ```

3. **Backup System Problems**
   ```bash
   # Check cron service
   sudo systemctl status cron
   
   # Verify backup script
   ls -la /opt/mysql-backup/
   sudo /opt/mysql-backup/mysql_backup.sh
   ```

## 📚 Additional Resources

- [MySQL 8.0 Documentation](https://dev.mysql.com/doc/refman/8.0/en/)
- [Google Cloud Secret Manager](https://cloud.google.com/secret-manager/docs)
- [OpenTofu Google Provider](https://registry.opentofu.org/providers/hashicorp/google/latest/docs)
- [GCP Security Best Practices](https://cloud.google.com/security/best-practices)

---

**⚠️ Important**: This configuration is designed for educational and development purposes. For production deployments, additional security hardening, monitoring, and compliance measures should be implemented based on your specific requirements. 