#!/bin/bash

# Function to log messages to a log file
log_message() {
    local log_file="backup_log_$(date +%Y%m%d).txt"
    echo "$(date): $1" >> "$log_file"
}

# Function to create compressed tarball archive of a directory
create_tarball() {
    local directory="$1"
    local archive_name="$(basename "$directory").tar.gz"
    tar -czf "$archive_name" -C "$(dirname "$directory")" "$(basename "$directory")"
    echo "$archive_name"
}

# Function to upload the compressed tarball archive to a remote server
upload_to_remote() {
    local archive="$1"
    local remote_ip="$2"
    local port="$3"
    local remote_directory="$4"
    scp -P "$port" "$archive" "$remote_ip":"$remote_directory"
    if [ $? -eq 0 ]; then
        log_message "Successfully uploaded $archive to $remote_ip:$port/$remote_directory"
        echo "Successfully uploaded $archive to $remote_ip:$port/$remote_directory"
    else
        log_message "Failed to upload $archive to $remote_ip:$port/$remote_directory"
        echo "Failed to upload $archive to $remote_ip:$port/$remote_directory"
        exit 1
    fi
}

# Main function
main() {
    local directory="$1"

    # Check if directory argument is provided
    if [ -z "$directory" ]; then
        read -p "Enter the directory name to back up: " directory
    fi

    # Verify that the directory exists
    if [ ! -d "$directory" ]; then
        log_message "Error: Directory $directory not found."
        echo "Error: Directory $directory not found."
        exit 1
    fi

    # Create compressed tarball archive
    local archive="$(create_tarball "$directory")"

    # Prompt user for remote server details
    read -p "Enter the IP address or URL of the remote server: " remote_ip
    read -p "Enter the port number of the remote server: " port
    read -p "Enter the target directory on the remote server to save the archive: " remote_directory

    # Upload the archive to the remote server
    upload_to_remote "$archive" "$remote_ip" "$port" "$remote_directory"
}

# Entry point
main "$@"

