#!/bin/bash

# Function to read and process the CSV file
process_csv() {
    local csv_file=$1

    while IFS=';' read -r email birthdate groups sharedFolder; do
        echo "Email: $email, Birthdate: $birthdate, Groups: $groups, Shared Folder: $sharedFolder"
    done < "$csv_file"
}

# Main script logic
csv_file="users.csv"
process_csv "$csv_file"

