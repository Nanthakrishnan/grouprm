#!/bin/bash

# Configuration file path
CONFIG_FILE="$HOME/.svn_mysql_config"

# Function to check if zenity is installed
check_zenity() {
    if ! command -v zenity &> /dev/null; then
        echo "Zenity is not installed. Please install it using 'sudo apt install zenity' or equivalent."
        exit 1
    fi
}

# Function to create or update the config file
save_config() {
    local svn_user=$1
    local svn_pass=$2
    local mysql_user=$3
    local mysql_pass=$4
    local mysql_host=$5

    # Store the credentials in the config file
    cat << EOF > "$CONFIG_FILE"
SVN_USERNAME=$svn_user
SVN_PASSWORD=$svn_pass
MYSQL_USERNAME=$mysql_user
MYSQL_PASSWORD=$mysql_pass
MYSQL_HOSTNAME=$mysql_host
EOF

    # Set secure permissions for the config file
    chmod 600 "$CONFIG_FILE"
    zenity --info --title="Success" --text="Configuration saved successfully!" --width=300
}

# Function to load existing configuration
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
        echo "$SVN_USERNAME" "$SVN_PASSWORD" "$MYSQL_USERNAME" "$MYSQL_PASSWORD"
    else
        echo "" "" "" ""
    fi
}

# Function to display the input form using zenity
show_form() {
    local svn_user=$1
    local svn_pass=$2
    local mysql_user=$3
    local mysql_pass=$4

    # Display the zenity form with pre-filled values if available
    response=$(zenity --forms --title="SVN & MySQL Configuration" \
        --text="Enter or edit the configuration details:" \
        --add-entry="SVN Username"  \
        --add-password="SVN Password"  \
        --add-entry="MySQL Username"  \
        --add-password="MySQL Password"  \
        --add-entry="MySQL hostname"  \
        --separator="|" \
        --width=400)

    # Check if the user clicked OK or Cancel
    if [[ $? -eq 0 ]]; then
        # Split the response into variables
        IFS="|" read -r new_svn_user new_svn_pass new_mysql_user new_mysql_pass new_mysql_hostname <<< "$response"
        # Save the new configuration
        save_config "$new_svn_user" "$new_svn_pass" "$new_mysql_user" "$new_mysql_pass" "$new_mysql_hostname"
    else
        zenity --info --title="Cancelled" --text="No changes were made." --width=300
        exit 0
    fi
}

# Main script
check_zenity

# Check if config file exists and load existing values
if [[ -f "$CONFIG_FILE" ]]; then
    read svn_user svn_pass mysql_user mysql_pass < <(load_config)
    zenity --question --title="Configuration Found" \
        --text="A configuration file already exists.\nWould you like to edit it?" \
        --width=300
    if [[ $? -eq 0 ]]; then
        # Show form with existing values
        show_form "$svn_user" "$svn_pass" "$mysql_user" "$mysql_pass"
    else
        zenity --info --title="No Changes" --text="No changes were made." --width=300
        exit 0
    fi
else
    # No config file exists, show empty form
    show_form "" "" "" ""
fi
