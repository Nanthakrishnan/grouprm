#!/bin/bash

source "$HOME/bashscripts/common.sh"
source $HOME/.svn_mysql_config

echo "selected project is $selected_project"

database=$(mysql -h "$MYSQL_HOSTNAME" -u"$MYSQL_USERNAME" -p"$MYSQL_PASSWORD" <<EOFMYSQL
show databases ;
EOFMYSQL
)

echo "$database"

echo "$database" > $HOME/database_list.txt

remove_column_name=$(sed '1d' $HOME/database_list.txt)
# echo "$remove_column_name" > $HOME/database_list.txt

selected_database=$(\
    cat $HOME/database_list.txt \
    | \
    rofi -dmenu -drun -i -p "select a database"
)

echo "selected database is $selected_database"

set -euo pipefail   # safer bash

# ------------------------------------------------------------------
# 1. Find the current database name (your original function)
# ------------------------------------------------------------------
find_database_name() {
    local DATABASE_FILE_PATH_1="${selected_project}config/config.database.php"
    local DATABASE_FILE_PATH_2="${selected_project}environments/config.ini"

    # config.ini present
    if [[ -e "$DATABASE_FILE_PATH_2" ]]; then
        DATABASE_NAME=$(grep -E '^\s*dataBaseName\s*=' "$DATABASE_FILE_PATH_2" |
                        tail -n1 |
                        cut -d'=' -f2 |
                        xargs)   # trim whitespace

    # config.database.php present
    elif [[ -e "$DATABASE_FILE_PATH_1" ]]; then
        # Grab the last uncommented $CFG['db']['dataBaseName'] = '...';
        DATABASE_NAME=$(grep -E '^\s*\$CFG\['"'"'db'"'"'\]\['"'"'dataBaseName'"'"'\]\s*=\s*["'"'"'].*["'"'"']' \
                        "$DATABASE_FILE_PATH_1" |
                        grep -v '^[[:space:]]*//' |
                        tail -n1 |
                        sed -E 's/^\s*\$CFG\['"'"'db'"'"'\]\['"'"'dataBaseName'"'"'\]\s*=\s*["'"'"']([^"'"'"']*)["'"'"'].*$/\1/')
    else
        zenity --error --title="Error" \
               --text="Database configuration not found:\n$DATABASE_FILE_PATH_1\n$DATABASE_FILE_PATH_2"
        exit 1
    fi

    echo "$DATABASE_NAME"
}

# ------------------------------------------------------------------
# 3. Replace the name in the config files
# ------------------------------------------------------------------
replace_in_ini() {
    local file="$1"
    # Escape slashes for sed
    local old_esc=$(printf '%s\n' "$old_name" | sed -e 's/[\/&]/\\&/g')
    local new_esc=$(printf '%s\n' "$selected_database" | sed -e 's/[\/&]/\\&/g')

    # Replace the *last* occurrence of dataBaseName=...
    sed -i "/^\s*dataBaseName\s*=/ {
        s/^\(\s*dataBaseName\s*=\s*\).*$/\1${new_esc}/
    }" "$file"
}

replace_in_php() {
    local file="$1"
    local old_esc=$(printf '%s\n' "$old_name" | sed -e 's/[\\/&]/\\&/g')
    local new_esc=$(printf '%s\n' "$selected_database" | sed -e 's/[\\/&]/\\&/g')

    # Replace the last uncommented assignment
    sed -i "/^\s*\$CFG\['db'\]\['dataBaseName'\]\s*=\s*['\"].*['\"];/ {
        s/^\(\s*\$CFG\['db'\]\['dataBaseName'\]\s*=\s*['\"]\)[^'\"]*\(['\"];.*\)$/\1${new_esc}\2/
    }" "$file"
}

# ------------------------------------------------------------------
# MAIN
# ------------------------------------------------------------------
main() {

    # Find current name
    old_name=$(find_database_name)

    if [[ "$old_name" == "$selected_database" ]]; then
        zenity --info --title="No change" \
               --text="Database name is already <b>$selected_database</b>."
        exit 0
    fi

    # Paths (same as in find_database_name)
    local php_file="${selected_project}config/config.database.php"
    local ini_file="${selected_project}environments/config.ini"

    # ---- Replace in the file(s) that actually exist ----
    if [[ -e "$ini_file" ]]; then
        replace_in_ini "$ini_file"
        zenity --info --title="Success" \
               --text="Database name in <b>config.ini</b> changed from <i>$old_name</i> to <b>$selected_database</b>."
    fi

    if [[ -e "$php_file" ]]; then
        replace_in_php "$php_file"
        zenity --info --title="Success" \
               --text="Database name in <b>config.database.php</b> changed from <i>$old_name</i> to <b>$selected_database</b>."
    fi

    # If neither file existed, find_database_name would have already errored.
}

# ------------------------------------------------------------------
# Run
# ------------------------------------------------------------------
main "$@"