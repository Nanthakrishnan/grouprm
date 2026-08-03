#!/bin/bash

source "$HOME/.base_dir.conf"

# Base directory to start the search
# BASE_DIR="/var/www/html/grouprm"

# Function to check if a directory is a project directory
is_project_directory() {
    local dir="$1"
    # Check if QUERY_FILE directory exists
    if [ -d "$dir/QUERY_FILE" ]; then
        return 0  # True, it's a project directory
    else
        return 1  # False, not a project directory
    fi
}

# Function to recursively search for project directories
find_projects() {
    local current_dir="$1"
    local depth="$2"

    # Skip if depth exceeds 4
    if [ "$depth" -gt 4 ]; then
        return
    fi

    # Check if current directory is a project directory
    if is_project_directory "$current_dir"; then
        echo "$current_dir"
        return  # Stop further recursion in this directory
    fi

    # Recursively search subdirectories
    for dir in "$current_dir"/*/ ; do
        # Check if it's a directory and not a symbolic link
        if [ -d "$dir" ] && [ ! -L "$dir" ]; then
            find_projects "${dir%/}" $((depth + 1))
        fi
    done
}

# Main execution
echo "Searching for project directories in $BASE_DIR"
echo "---------------------------------------------"

# Check if base directory exists
if [ ! -d "$BASE_DIR" ]; then
    echo "Error: Directory $BASE_DIR does not exist"
    exit 1
fi

# Store project directories in a variable
PROJECTS=$(find_projects "$BASE_DIR" 0)

# Check if any projects were found
if [ -z "$PROJECTS" ]; then
    echo "No project directories found"
    notify-send "No Projects" "No project directories found in $BASE_DIR"
    exit 1
fi

# Convert PROJECTS to an array for rofi
PROJECT_ARRAY=()
while IFS= read -r line; do
    PROJECT_ARRAY+=("$line")
done <<< "$PROJECTS"
