#!/bin/bash

# Function to generate username from email address
generate_username() {
    local email=$1
    local first_name=$(echo "$email" | cut -d'.' -f1)
    local surname=$(echo "$email" | cut -d'.' -f2 | cut -d'@' -f1)
    echo "${first_name:0:1}${surname}"
}

# Function to create shared folder and set ownership
create_shared_folder() {
    local username=$1
    local shared_folder=$2
    if [ ! -d "$shared_folder" ]; then
        sudo mkdir -p "$shared_folder"
        echo "Shared folder $shared_folder created."
    fi
    sudo chown "$username" "$shared_folder"
    echo "Shared folder $shared_folder owned by $username."
}

# Function to add user to groups
add_user_to_groups() {
    local username=$1
    local groups=$2
    IFS=',' read -r -a group_array <<< "$groups"
    for group in "${group_array[@]}"; do
        if ! getent group "$group" > /dev/null; then
            sudo groupadd "$group"
            echo "Group $group created."
        fi
        sudo usermod -aG "$group" "$username"
        echo "User $username added to group $group."
    done
}

# Read user information from CSV file
while IFS=';' read -r email birth_date groups shared_folder; do
    # Skip header line
    if [[ $email == "e-mail" ]]; then
        continue
    fi
    # Check if email address or birth date is empty
    if [[ -z $email || -z $birth_date ]]; then
        echo "Skipping line with empty email address or birth date."
        continue
    fi
    username=$(generate_username "$email")
    if [ -n "$shared_folder" ]; then
        create_shared_folder "$username" "$shared_folder"
    fi
    if [ -n "$groups" ]; then
        add_user_to_groups "$username" "$groups"
    fi
done < users.csv  # Update this to match the path to your CSV file

# Function to show members of a group
show_group_members() {
    local group=$1
    echo "Members of group $group:"
    getent group "$group" | awk -F: '{print $4}'
}

# Show group members
show_group_members staff
show_group_members visitor

