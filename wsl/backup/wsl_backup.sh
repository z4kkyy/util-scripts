#!/bin/bash

# Variable definitions
today=$(date +%Y%m%d)
target_dir=/mnt/d/backup/wsl
tmp_dir=/tmp/backup_wsl_tmp
origin_dir=/
target_today_dir=$target_dir/$today
target_today_tarfile=$target_today_dir/backup.tar.bz2
exclude_list=/wsl_backup/exclude_list.txt
error_log="$target_today_dir/backup_errors.log"
save_files_number=5

# Create target directory if it doesn't exist
mkdir -p $target_dir

# Start backup process
echo "Starting WSL backup at $(date)"
echo 'Creating WSL backup...'
echo '--------------------------'

# Create backup directory for today
mkdir -p $target_today_dir

# Execute backup with error handling
tar --warning=no-file-changed -cvpjf $target_today_tarfile -X $exclude_list $origin_dir 2>"$error_log"
tar_exit_code=$?

# Check and handle errors
if [ $tar_exit_code -ne 0 ]; then
    echo "Backup completed with warnings. Checking error types..."
    if grep -E "Permission denied|No space left|Cannot open" "$error_log"; then
        echo "Critical errors found in backup process!"
        echo "See details in: $error_log"
        exit 1
    else
        echo "Non-critical warnings occurred during backup:"
        cat "$error_log"
        echo "Backup completed successfully despite warnings."
    fi
fi

echo '--------------------------'

# Manage old backups (rotation)
echo 'Managing backup directories...'
rm -rf $tmp_dir
mkdir -p $tmp_dir
dir_str="${target_dir}/*/"
count=1

# Move recent backups to temporary directory
for dirname in $(ls -td $dir_str 2>/dev/null); do
    if [ -d "$dirname" ]; then
        mv "$dirname" $tmp_dir
        count=$((count + 1))
        if [ $count -gt $save_files_number ]; then
            break
        fi
    fi
done

# Update backup directory structure
if [ -d "$tmp_dir" ] && [ "$(ls -A $tmp_dir)" ]; then
    rm -rf $target_dir
    mv $tmp_dir $target_dir
    echo "Backup rotation completed successfully."
else
    echo "Warning: No previous backups found or backup rotation failed."
fi

# Display backup information
backup_size=$(du -h "$target_today_tarfile" 2>/dev/null | cut -f1)
echo "Backup size: $backup_size"

echo "Successfully created backup files at $(date)!"

# Final verification
if [ ! -f "$target_today_tarfile" ]; then
    echo "Error: Backup file was not created successfully!"
    exit 1
fi

# Set secure permissions for backup files
chmod 600 "$target_today_tarfile"
chmod 700 "$target_today_dir"

echo "Backup process completed successfully!"
