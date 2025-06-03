#!/bin/bash

set -e

# -----------------------------
# Set timezone to Asia/Kolkata
# -----------------------------
echo "Setting timezone to Asia/Kolkata..."
sudo timedatectl set-timezone Asia/Kolkata
echo "Timezone set to Asia/Kolkata"

# -----------------------------
# Create temporary directory
# -----------------------------

touch /tmp/startup-script-started

# -----------------------------
# Logging setup
# -----------------------------
exec > >(tee /var/log/startup-script.log) 2>&1

# -----------------------------
# Start MySQL installation script
# -----------------------------
echo "Starting MySQL installation script..."

# -----------------------------
# Variables (from Terraform template)
# -----------------------------
PROJECT_ID="${project_id}"
SECRET_NAME="${secret_name}"
NAME_PREFIX="${name_prefix}"
BUCKET_NAME="${bucket_name}"

# -----------------------------
# Retrieve MySQL password from Secret Manager
# -----------------------------
echo "Retrieving MySQL application user password from Secret Manager..."
MYSQL_APP_PASSWORD=$(gcloud secrets versions access latest --secret="$SECRET_NAME" --project="$PROJECT_ID")

if [ -z "$MYSQL_APP_PASSWORD" ]; then
    echo "Error: Failed to retrieve MySQL application user password from Secret Manager"
    exit 1
fi

echo "Successfully retrieved MySQL password from Secret Manager"

# -----------------------------
# Update system & install tools
# -----------------------------
echo "Updating system and installing required tools..."
sudo apt update -y
sudo apt install -y wget lsb-release gnupg htop nano cron

# -----------------------------
# Start and enable cron service
# -----------------------------
echo "Starting and enabling cron service..."
sudo systemctl start cron
sudo systemctl enable cron
echo "Cron service started and enabled"

# -----------------------------
# Setup Swap Memory (2GB)
# -----------------------------
echo "Setting up swap memory..."

# Check if swap is already configured
if sudo swapon --show | grep -q "/swapfile"; then
    echo "Swap file already exists and is active"
else
    echo "Creating 2GB swap file..."
    
    # Create 2GB swap file
    sudo fallocate -l 2G /swapfile
    
    # Set proper permissions for security
    sudo chmod 600 /swapfile
    
    # Initialize the swap file
    sudo mkswap /swapfile
    
    # Enable the swap file
    sudo swapon /swapfile
    
    # Backup fstab before modification
    sudo cp /etc/fstab /etc/fstab.bak
    
    # Add swap to fstab for persistence across reboots
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
    
    # Configure swap optimization parameters
    echo "Configuring swap optimization parameters..."
    
    # Add swap optimization settings to sysctl.conf
    sudo tee -a /etc/sysctl.conf << EOF

# Swap optimization settings
vm.swappiness=10
vm.vfs_cache_pressure=50
EOF
    
    # Apply sysctl settings immediately
    sudo sysctl -p
    
    echo "Swap configuration completed successfully!"
    echo "Swap status:"
    sudo swapon --show
    free -h
fi

# -----------------------------
# Download MySQL .tar and libaio1 dependency
# -----------------------------
echo "Downloading MySQL bundle and dependencies..."
cd /tmp
wget -q https://dev.mysql.com/get/Downloads/MySQL-8.0/mysql-server_8.0.42-1ubuntu24.10_amd64.deb-bundle.tar
wget -q http://archive.ubuntu.com/ubuntu/pool/main/liba/libaio/libaio1_0.3.112-5_amd64.deb

# -----------------------------
# Install libaio1 manually
# -----------------------------
echo "Installing libaio1 dependency..."
sudo dpkg -i libaio1_0.3.112-5_amd64.deb

# -----------------------------
# Extract MySQL bundle
# -----------------------------
echo "Extracting MySQL bundle..."
tar -xvf mysql-server_8.0.42-1ubuntu24.10_amd64.deb-bundle.tar

# -----------------------------
# Install remaining dependencies
# -----------------------------
echo "Installing MySQL dependencies..."
sudo apt install -y libmecab2 perl psmisc libjson-perl mecab-ipadic-utf8 mecab-utils mecab-ipadic

# -----------------------------
# Install all MySQL .deb packages
# -----------------------------
echo "Installing MySQL packages..."
sudo dpkg -i *.deb || true

# -----------------------------
# Fix broken dependencies and configure
# -----------------------------
echo "Fixing dependencies and configuring packages..."
sudo apt --fix-broken install -y
sudo dpkg --configure -a

# -----------------------------
# Start and enable MySQL
# -----------------------------
echo "Starting and enabling MySQL service..."
sudo systemctl start mysql
sudo systemctl enable mysql

# -----------------------------
# Fix root user authentication
# -----------------------------

echo "Creating application user for remote access with read/write privileges..."
sudo mysql -e "CREATE USER IF NOT EXISTS 'appuser'@'%' IDENTIFIED BY '$MYSQL_APP_PASSWORD';"
sudo mysql -e "GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER, CREATE TEMPORARY TABLES, LOCK TABLES, PROCESS ON *.* TO 'appuser'@'%';"
sudo mysql -e "FLUSH PRIVILEGES;"

echo "Application user 'appuser' created successfully with read/write privileges"
echo "Root user remains local-only passwordless for server administration"
echo "MySQL configuration completed with separate user roles"

# -----------------------------
# Setup MySQL Backup System
# -----------------------------
echo "Setting up MySQL backup system..."

# Create backup directory
sudo mkdir -p /opt/mysql-backup
sudo chown -R $(whoami):$(whoami) /opt/mysql-backup

# Create MySQL backup script
cat << EOF > /opt/mysql-backup/mysql_backup.sh
#!/bin/bash

# Set strict error handling
set -e

# Variables
PROJECT_ID="${project_id}"
SECRET_NAME="${secret_name}"
NAME_PREFIX="${name_prefix}"
BUCKET_NAME="${bucket_name}"
BACKUP_DIR="/opt/mysql-backup"
LOG_FILE="\$BACKUP_DIR/backup.log"

# Logging function
log() {
    echo "\`date '+%Y-%m-%d %H:%M:%S'\` - \$1" | tee -a "\$LOG_FILE"
}

log "Starting MySQL backup process..."

# Retrieve MySQL app user password from Secret Manager
log "Retrieving MySQL credentials from Secret Manager..."
MYSQL_APP_PASSWORD=\`gcloud secrets versions access latest --secret="\$SECRET_NAME" --project="\$PROJECT_ID"\`

if [ -z "\$MYSQL_APP_PASSWORD" ]; then
    log "ERROR: Failed to retrieve MySQL password from Secret Manager"
    exit 1
fi

log "Successfully retrieved MySQL credentials"

# Generate timestamped filename
TIMESTAMP=\`date '+%d-%b-%Y-%I-%M-%p' | tr '[:upper:]' '[:lower:]'\`
BACKUP_FILE="\$TIMESTAMP-\$NAME_PREFIX-vmdb-backup.sql"
BACKUP_PATH="\$BACKUP_DIR/\$BACKUP_FILE"

log "Creating backup: \$BACKUP_FILE"

# Create MySQL dump
mysqldump -u appuser -p"\$MYSQL_APP_PASSWORD" \\
    --single-transaction \\
    --routines \\
    --triggers \\
    --all-databases > "\$BACKUP_PATH"

if [ \$? -eq 0 ]; then
    log "MySQL dump completed successfully"
    
    # Compress the backup
    gzip "\$BACKUP_PATH"
    BACKUP_PATH="\$BACKUP_PATH.gz"
    BACKUP_FILE="\$BACKUP_FILE.gz"
    
    log "Backup compressed: \$BACKUP_FILE"
    
    # Upload to GCS bucket
    log "Uploading backup to GCS bucket: gs://\$BUCKET_NAME/mysql-backups/"
    
    if gsutil cp "\$BACKUP_PATH" "gs://\$BUCKET_NAME/mysql-backups/\$BACKUP_FILE"; then
        log "Backup successfully uploaded to GCS"
        
        # Clean up local backup file (keep only last 3 local backups)
        find "\$BACKUP_DIR" -name "*.sql.gz" -type f | sort | head -n -3 | xargs -r rm -f
        log "Local cleanup completed"
        
        # Verify upload
        if gsutil ls "gs://\$BUCKET_NAME/mysql-backups/\$BACKUP_FILE" > /dev/null 2>&1; then
            log "Backup verification successful: gs://\$BUCKET_NAME/mysql-backups/\$BACKUP_FILE"
        else
            log "WARNING: Backup verification failed"
        fi
        
    else
        log "ERROR: Failed to upload backup to GCS"
        exit 1
    fi
    
else
    log "ERROR: MySQL dump failed"
    exit 1
fi

log "MySQL backup process completed successfully"

# Optional: Clean up old backups in GCS (keep last 30 days)
log "Cleaning up old backups in GCS..."
CUTOFF_DATE=\`date -d '30 days ago' '+%Y-%m-%d'\`
gsutil ls "gs://\$BUCKET_NAME/mysql-backups/" | while read backup; do
    if [[ "\$backup" < "gs://\$BUCKET_NAME/mysql-backups/\$CUTOFF_DATE" ]]; then
        log "Removing old backup: \$backup"
        gsutil rm "\$backup" || log "WARNING: Failed to remove \$backup"
    fi
done

log "Backup cleanup completed"
EOF

# Make backup script executable
chmod +x /opt/mysql-backup/mysql_backup.sh

# Create mysql-backups directory in GCS bucket
echo "Creating mysql-backups directory in GCS bucket..."
echo "This directory will store MySQL backups" | gsutil cp - "gs://${bucket_name}/mysql-backups/.gitkeep"

# Setup cron job for daily backups at 2 AM
echo "Setting up cron job for daily MySQL backups..."

# Create a temporary cron file to avoid pipe issues
TEMP_CRON=$(mktemp)

# Get existing crontab (if any) and add new job
sudo crontab -l 2>/dev/null > "$TEMP_CRON" || true
echo "0 2 * * * /opt/mysql-backup/mysql_backup.sh >> /opt/mysql-backup/cron.log 2>&1" >> "$TEMP_CRON"

# Install the new crontab
sudo crontab "$TEMP_CRON"

# Clean up temporary file
rm -f "$TEMP_CRON"

# Verify cron installation
if sudo crontab -l | grep -q "mysql_backup.sh"; then
    echo "✓ Cron job installed successfully"
else
    echo "✗ Warning: Cron job installation may have failed"
fi

# Test backup script execution
echo "Running initial backup test..."
if /opt/mysql-backup/mysql_backup.sh; then
    echo "Initial backup test successful!"
else
    echo "WARNING: Initial backup test failed. Check logs at /opt/mysql-backup/backup.log"
fi

echo "MySQL backup system setup completed!"
echo "- Backup script: /opt/mysql-backup/mysql_backup.sh"
echo "- Backup logs: /opt/mysql-backup/backup.log"
echo "- Cron logs: /opt/mysql-backup/cron.log"
echo "- GCS location: gs://${bucket_name}/mysql-backups/"
echo "- Schedule: Daily at 2:00 AM"
echo "- Check cron status: sudo crontab -l"

# -----------------------------
# Show MySQL version & status
# -----------------------------
echo "MySQL installation completed successfully!"
mysql --version
sudo systemctl status mysql --no-pager

# -----------------------------
# Cleanup
# -----------------------------
echo "Cleaning up installation files..."
cd /
rm -rf /tmp/mysql-server_8.0.42-1ubuntu24.10_amd64.deb-bundle.tar
rm -rf /tmp/libaio1_0.3.112-5_amd64.deb
rm -rf /tmp/*.deb
touch /tmp/mysql-installation-completed

echo "MySQL installation and configuration completed successfully!" 