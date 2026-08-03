#!/bin/bash

source "$HOME/.base_dir.conf"
source $HOME/.svn_mysql_config

BASE_URL="http://192.168.1.150/svn/sabreGroupRM/"
CURRENT_URL="$BASE_URL"
CHECKOUT_BASE="$BASE_DIR"

# ── Helpers ───────────────────────────────────────────────────────────────────

# Escape a value for safe use as a sed replacement string
sed_escape_replacement() {
    printf '%s' "$1" | sed -e 's/[\/&]/\\&/g'
}

list_mysql_databases() {
    mysql -h "$MYSQL_HOSTNAME" -u"$MYSQL_USERNAME" -p"$MYSQL_PASSWORD" -sN -e "SHOW DATABASES;" 2>/dev/null \
        | grep -vE '^(information_schema|performance_schema|mysql|sys)$'
}

prompt_database_selection() {
    local db_list
    db_list=$(list_mysql_databases)

    if [[ -z "$db_list" ]]; then
        rofi -e "Could not fetch database list from MySQL host: $MYSQL_HOSTNAME"
        echo ""
        return
    fi

    echo "$db_list" | rofi -dmenu -i -p "Select Database"
}

update_ini_value() {
    local ini_file="$1" key="$2" value="$3"
    local escaped_value
    escaped_value=$(sed_escape_replacement "$value")
    sed -i -E "s/^([[:space:]]*${key}[[:space:]]*=).*/\1${escaped_value}/" "$ini_file"
}

update_ini_config() {
    local ini_file="$1" db_name="$2"

    update_ini_value "$ini_file" "hostName" "$MYSQL_HOSTNAME"
    update_ini_value "$ini_file" "userName" "$MYSQL_USERNAME"
    update_ini_value "$ini_file" "password" "$MYSQL_PASSWORD"
    update_ini_value "$ini_file" "dataBaseName" "$db_name"

    echo "Updated database config in: $ini_file"
}

# Update a single $CFG['db']['<key>'] assignment in a config.database.php file.
# Only the last *uncommented* line for that key is touched, since these files
# commonly keep old values around as commented-out lines.
update_php_config_value() {
    local php_file="$1" key="$2" value="$3"
    local pattern="^[[:space:]]*\\\$CFG\['db'\]\['${key}'\][[:space:]]*=[[:space:]]*[\"'].*[\"']"

    local line_no
    line_no=$(grep -nE "$pattern" "$php_file" | grep -v ':[[:space:]]*//' | tail -n 1 | cut -d: -f1)
    [[ -z "$line_no" ]] && return

    local escaped_value
    escaped_value=$(sed_escape_replacement "$value")
    sed -i -E "${line_no}s/=([[:space:]]*)['\"][^'\"]*['\"]/=\1'${escaped_value}'/" "$php_file"
}

update_php_config() {
    local php_file="$1" db_name="$2"

    update_php_config_value "$php_file" "hostName" "$MYSQL_HOSTNAME"
    update_php_config_value "$php_file" "userName" "$MYSQL_USERNAME"
    update_php_config_value "$php_file" "password" "$MYSQL_PASSWORD"
    update_php_config_value "$php_file" "dataBaseName" "$db_name"

    echo "Updated database config in: $php_file"
}

update_database_config() {
    local dest="$1"
    local ini_file="${dest%/}/environments/config.ini"
    local php_file="${dest%/}/config/config.database.php"

    if [[ ! -e "$ini_file" && ! -e "$php_file" ]]; then
        rofi -e "Database config not found in:\n  $ini_file\n  $php_file"
        return
    fi

    local db_name
    db_name=$(prompt_database_selection)
    if [[ -z "$db_name" ]]; then
        rofi -e "No database selected. Skipping database configuration update."
        return
    fi

    if [[ -e "$ini_file" ]]; then
        update_ini_config "$ini_file" "$db_name"
    elif [[ -e "$php_file" ]]; then
        update_php_config "$php_file" "$db_name"
    fi
}

while true; do

    # Fetch full HTML content
    HTML=$(curl -u "${SVN_USERNAME}:${SVN_PASSWORD}" -s "$CURRENT_URL")

    # Check for index.php (to identify is it project root)
    if echo "$HTML" | grep -q 'index.php'; then
        # Offer selection of this folder
        CONFIRM=$(echo -e "Yes\nNo" | rofi -dmenu -i -p "Checkout $CURRENT_URL ?")

        if [[ "$CONFIRM" == "Yes" ]]; then

            DEST=$(zenity --file-selection --directory --title="Choose your web root directory" --filename="$BASE_DIR/")

            # Check if DEST is empty (user cancelled or didn't select a directory)
            if [ -z "$DEST" ]; then
                echo "No directory selected. Exiting..."
                exit 1
            fi

            # rofi -e "Checking out $CURRENT_URL to $DEST"
            svn checkout --username "$SVN_USERNAME" --password "$SVN_PASSWORD" "$CURRENT_URL" "$DEST"

            # Grant full permissions on the checked-out project by default
            chmod -R 777 "$DEST"
            echo "Permissions set to 777 for: $DEST"

            # Update the application's database configuration
            update_database_config "$DEST"

            # Run cleanup script if exists
            if [[ -f "$DEST/$CLEANUP_SCRIPT" ]]; then
                (cd "$DEST" && bash "$CLEANUP_SCRIPT")
            else
                rofi -e "No $CLEANUP_SCRIPT in $DEST"
            fi
            exit 0
        fi
    fi

    # Fetch and parse links from the current SVN directory
    # ENTRIES=$(curl -u nanthakrishnan.j:uT2jG7pA4z -s "$CURRENT_URL" | grep -oP '(?<=<li><a href=")[^"]+(?=")' | sed 's:/$::')

    # Parse folder names from HTML
    ENTRIES=$(echo "$HTML" | grep -oP '(?<=<li><a href=")[^"]+(?=/")' | sed 's:/$::' | sort | uniq)

    # Show the entries in rofi and get user selection
    CHOICE=$(echo "$ENTRIES" | rofi -dmenu -i -p "$CURRENT_URL")

    [[ -z "$CHOICE" ]] && exit 0  # User cancelled

    if [[ "$CHOICE" == ".." ]]; then
        # Go one level up
        CURRENT_URL=$(dirname "${CURRENT_URL%/}")/
    else
        # Go deeper into the selected folder
        CURRENT_URL="${CURRENT_URL%/}/$CHOICE/"
    fi
done
