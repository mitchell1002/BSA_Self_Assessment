#!/bin/bash

# Function to log messages to a log file
log_message() {
    local log_file="script_log_$(date +%Y%m%d).txt"
    echo "$(date): $1" >> "$log_file"
}

# Function to generate username from email address
generate_username() {
    local email="$1"
    local first_name=$(echo "$email" | cut -d'.' -f1)
    local surname=$(echo "$email" | cut -d'.' -f2 | cut -d'@' -f1)
    echo "${first_name:0:1}${surname}"
}

# Function to generate default password from birth date
generate_password() {
    local birth_date="$1"
    local birth_month=$(date -d "$birth_date" +%m)
    local birth_year=$(date -d "$birth_date" +%Y)
    echo "${birth_month}${birth_year}00"
}

# Function to create user
create_user() {
    local username="$1"
    local password="$2"
    if id "$username" &>/dev/null; then
        log_message "User $username already exists. Skipping..."
        echo "User $username already exists. Skipping..."
    else
        sudo useradd -m -s /bin/bash "$username"
        if [ $? -eq 0 ]; then
            echo "$username:$password" | sudo chpasswd
            if [ $? -eq 0 ]; then
                log_message "User $username created with default password $password."
                echo "User $username created with default password $password."
                # Enforce password change at first login
                sudo chage -d 0 "$username"
                log_message "Password for $username set to expire at first login."
                echo "Password for $username set to expire at first login."
            else
                log_message "Failed to set password for $username."
                echo "Failed to set password for $username."
            fi
        else
            log_message "Failed to create user $username."
            echo "Failed to create user $username."
        fi
    fi
}

# Function to create shared folder and set ownership and permissions
create_shared_folder() {
    local shared_folder="$1"
    local group="$2"
    if [ ! -d "$shared_folder" ]; then
        sudo mkdir -p "$shared_folder"
        log_message "Shared folder $shared_folder created."
        echo "Shared folder $shared_folder created."
    fi
    sudo chgrp "$group" "$shared_folder"
    sudo chmod 2770 "$shared_folder"  # Full rwx permissions for the group
    log_message "Shared folder $shared_folder owned by group $group with permissions set."
    echo "Shared folder $shared_folder owned by group $group with permissions set."
}

# Function to add user to groups
add_user_to_groups() {
    local username="$1"
    local groups="$2"
    IFS=',' read -r -a group_array <<< "$groups"
    for group in "${group_array[@]}"; do
        if ! getent group "$group" > /dev/null; then
            sudo groupadd "$group"
            log_message "Group $group created."
            echo "Group $group created."
        fi
        sudo usermod -aG "$group" "$username"
        log_message "User $username added to group $group."
        echo "User $username added to group $group."
    done
}

# Function to process the CSV file
process_csv() {
    local csv_file="$1"
    local total_users=$(wc -l < "$csv_file")
    log_message "Total number of users to be added: $total_users"
    echo "Total number of users to be added: $total_users"

    # Dialog to confirm before proceeding
    read -p "Do you want to proceed with adding $total_users users? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        log_message "User chose not to proceed. Exiting..."
        echo "User chose not to proceed. Exiting..."
        exit 1
    fi

    while IFS=';' read -r email birth_date groups shared_folder; do
        # Skip header line
        if [[ $email == "e-mail" ]]; then
            continue
        fi
        # Check if email address or birth date is empty
        if [[ -z $email || -z $birth_date ]]; then
            log_message "Skipping line with empty email address or birth date."
            echo "Skipping line with empty email address or birth date."
            continue
        fi
        username=$(generate_username "$email")
        password=$(generate_password "$birth_date")
        create_user "$username" "$password"
        if [ -n "$groups" ]; then
            add_user_to_groups "$username" "$groups"
        fi
        if [ -n "$shared_folder" ]; then
            primary_group=$(echo "$groups" | cut -d',' -f1)
            create_shared_folder "$shared_folder" "$primary_group"
            # Create a symlink in the user's home directory
            sudo ln -s "$shared_folder" "/home/$username/$(basename $shared_folder)"
            sudo chown -h "$username:$primary_group" "/home/$username/$(basename $shared_folder)"
            log_message "Symlink to $shared_folder created in /home/$username."
            echo "Symlink to $shared_folder created in /home/$username."
        fi
        # Add alias for shutdown if the user is in the sudo group
        if [[ "$groups" == *"sudo"* ]]; then
            echo "alias shutdown='sudo shutdown -h now'" | sudo tee -a "/home/$username/.bashrc"
            log_message "Alias for shutdown added for $username."
            echo "Alias for shutdown added for $username."
        fi
    done < "$csv_file"
}

# Function to show members of a group
show_group_members() {
    local group="$1"
    echo "Members of group $group:"
    getent group "$group" | awk -F: '{print $4}'
}

# Check if the argument is a URL or a file path
input="$1"
if [[ $input == http* ]]; then
    csv_file="/tmp/users.csv"
    curl -o "$csv_file" "$input"
elif [[ -f $input ]]; then
    csv_file="$input"
else
    log_message "Invalid input: $input. Please provide a valid URI or file path."
    echo "Invalid input: $input. Please provide a valid URI or file path."
    exit 1
fi

if [ ! -f "$csv_file" ]; then
    log_message "CSV file not found: $csv_file"
    echo "CSV file not found: $csv_file"
    exit 1
fi

# Process the CSV file
process_csv "$csv_file"

# Show group members
show_group_members staff
    show_group_members visitor
    show_group_members sudo
}


# Entry point
main "$@"

