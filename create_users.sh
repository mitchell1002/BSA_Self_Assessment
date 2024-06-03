#!/bin/bash

# Check if the CSV file is provided
if [ $# -eq 0 ]; then
    echo "No CSV file provided. Usage: $0 <csvfile>"
    exit 1
fi

CSV_FILE=$1

# Read the CSV file
while IFS=';' read -r email birth_date groups shared_folder; do
    # Skip the header line
    if [ "$email" == "e-mail" ]; then
        continue
    fi

    # Extract the username from the email
    username=$(echo $email | cut -d '@' -f 1)

    # Create the user
    sudo useradd -m -c "$username" "$username"

    # Set the user's birth date (custom attribute, not standard on Unix systems)
    sudo chfn -o "BirthDate=$birth_date" "$username"

    # Add user to specified groups
    if [ -n "$groups" ]; then
        IFS=',' read -r -a group_array <<< "$groups"
        for group in "${group_array[@]}"; do
            sudo usermod -aG "$group" "$username"
        done
    fi

    # Create the shared folder if specified
    if [ -n "$shared_folder" ]; then
        sudo mkdir -p "$shared_folder"
        sudo chown "$username":"$username" "$shared_folder"
    fi

done < "$CSV_FILE"

echo "User creation and configuration complete."

