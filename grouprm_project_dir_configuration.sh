#!/bin/bash

# Path to the configuration file (user-specific in home directory)
CONFIG_FILE="$HOME/.base_dir.conf"

# Function to select directory with validation
select_directory() {
    while true; do
        DEST=$(zenity --file-selection --directory --title="Choose your project directory" --filename="/var/www/html/")
        
        # If user cancels, exit the script
        if [ $? -ne 0 ]; then
            exit 0
        fi
        
        # Normalize by removing trailing slash if present
        DEST="${DEST%/}"
        
        # Check if it's exactly /var/www/html
        if [ "$DEST" = "/var/www/html" ]; then
            zenity --error --text="Please select a subdirectory under /var/www/html/, not the root itself."
            continue
        fi
        
        # Check if it's a subdirectory of /var/www/html/
        # if [[ ! "$DEST" =~ ^/var/www/html/ ]]; then
        #     zenity --error --text="Selected directory must be under /var/www/html/."
        #     continue
        # fi
        
        break
    done
    echo "$DEST"
}

# Check if config file already exists
if [ -f "$CONFIG_FILE" ]; then
    # Source the config to get current BASE_DIR
    source "$CONFIG_FILE"
    
    # Ask if user wants to override
    zenity --question --width=450 --text="$BASE_DIR is configured as the base directory. Would you like to override?"
    if [ $? -ne 0 ]; then
        # User chose No, exit
        exit 0
    fi
fi

# Proceed to select new directory
NEW_DIR=$(select_directory)

# Write to config file
echo "BASE_DIR=\"$NEW_DIR\"" > "$CONFIG_FILE"

# Notify success
zenity --info --text="Group rm project directory is set to $NEW_DIR"