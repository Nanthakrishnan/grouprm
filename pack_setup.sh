#!/usr/bin/env bash
set -euo pipefail

source "$HOME/bashscripts/common.sh"
source "$HOME/.svn_mysql_config"

SUCCESS_MESSAGE_CONTENT=""

# ── Validate project ──────────────────────────────────────────────────────────
echo "Selected project: $selected_project"

if [[ ! -d "$selected_project" ]]; then
    rofi -e "Not a valid project directory: $selected_project"
    exit 1
fi

# ── Configuration (hardcoded; uncomment zenity block to make interactive) ─────
configuration="QUERY FILE,combine js and css,config delete"

# configuration=$(zenity --list --checklist \
#     --title="Configuration Options" \
#     --text="Select options:" \
#     --column="Select" --column="Option" \
#     TRUE "QUERY FILE" \
#     TRUE "combine js and css" \
#     TRUE "config delete" \
#     FALSE "rm lang files other than en" \
#     --separator=",")

echo "Configuration: $configuration"

# ── Helpers ───────────────────────────────────────────────────────────────────
prompt_airline_code() {
    local code
    code=$(zenity --entry \
        --title="Enter the airline code" \
        --text="Project: ${selected_project}\nAirline code must be two letters:" \
        --entry-text "eg: wn, ak, wy, y4")
    echo "$code"
}

echo "Excecuted here line number is ========> $LINENO"
find_database_name() {
    local db_ini="${selected_project}/environments/config.ini"
    local db_php="${selected_project}/config/config.database.php"

    if [[ -e "$db_ini" ]]; then
        grep "dataBaseName" "$db_ini" | cut -d'=' -f2 | tr -d '[:space:]'

    elif [[ -e "$db_php" ]]; then
        grep -E '^\s*\$CFG\['"'"'db'"'"'\]\['"'"'dataBaseName'"'"'\]\s*=\s*["'"'"'].*["'"'"']' "$db_php" \
            | grep -v '^[[:space:]]*//' \
            | tail -n 1 \
            | sed -E 's/^\s*\$CFG\['"'"'db'"'"'\]\['"'"'dataBaseName'"'"'\]\s*=\s*["'"'"']([^"'"'"']*)["'"'"'].*$/\1/'

    else
        rofi -e "Database config not found in:\n  $db_php\n  $db_ini"
        echo ""
    fi
}

echo "Excecuted here line number is ========> $LINENO"
find_airline_code_from_db() {
    local db_name="$1"
    [[ -z "$db_name" ]] && { echo ""; return; }

    local result
    result=$(mysql -h 127.0.0.1 -u"$MYSQL_USERNAME" -p"$MYSQL_PASSWORD" "$db_name" -sN 2>/dev/null <<'SQL'
SELECT airlines_code FROM corporate_details WHERE corporate_id = 1;
SQL
    ) || true

    # Trim whitespace; the -sN flag returns just the value
    echo "$result" | tr -d '[:space:]'
}

echo "Excecuted here line number is ========> $LINENO"
# Escape a value for safe use as a sed replacement string
sed_escape_replacement() {
    printf '%s' "$1" | sed -e 's/[\/&]/\\&/g'
}

echo "Excecuted here line number is ========> $LINENO"
# Rewrite a plain `key=value` line in an ini-style file
update_ini_value() {
    local ini_file="$1" key="$2" value="$3"
    local escaped_value
    escaped_value=$(sed_escape_replacement "$value")
    sed -i -E "s/^([[:space:]]*${key}[[:space:]]*=).*/\1${escaped_value}/" "$ini_file"
}

echo "Excecuted here line number is ========> $LINENO"
# Append an item to a comma-separated value if it isn't already present
add_to_csv_if_missing() {
    local csv="$1" item="$2"
    local part
    IFS=',' read -ra parts <<< "$csv"
    for part in "${parts[@]}"; do
        [[ "$(echo "$part" | tr -d '[:space:]')" == "$item" ]] && { echo "$csv"; return; }
    done
    echo "${csv},${item}"
}

echo "Excecuted here line number is ========> $LINENO"
# Derive the web sitePath for $selected_project from an existing sitePath value,
# keeping its scheme+host but swapping the path for selected_project's location
# relative to the web root (the parent of $BASE_DIR).
# eg. old="http://localhost/GRMTRUNK/", selected_project="/home/Staging/groupRm/ar_dev/"
#     => "http://localhost/groupRm/ar_dev/"
derive_site_path() {
    local old_value="$1"
    local scheme_host
    scheme_host=$(echo "$old_value" | grep -oE '^[a-zA-Z]+://[^/]+')
    [[ -z "$scheme_host" ]] && scheme_host="http://localhost"

    local web_root_parent rel_path
    web_root_parent="$(dirname "$BASE_DIR")"
    rel_path="${selected_project#"$web_root_parent"/}"

    echo "${scheme_host}/${rel_path}"
}

echo "Excecuted here line number is ========> $LINENO"
update_site_config_ini() {
    local ini_file="$1" airline_code="$2"

    local current_site_path new_site_path
    current_site_path=$(grep -E '^sitePath=' "$ini_file" | tail -n1 | cut -d'=' -f2-)
    new_site_path=$(derive_site_path "$current_site_path")

    local current_codes new_codes
    current_codes=$(grep -E '^possibleAirlineCodes=' "$ini_file" | tail -n1 | cut -d'=' -f2-)
    new_codes=$(add_to_csv_if_missing "$current_codes" "$airline_code")

    update_ini_value "$ini_file" "airlineCode" "$airline_code"
    update_ini_value "$ini_file" "possibleAirlineCodes" "$new_codes"
    update_ini_value "$ini_file" "pluginBasePath" "plugins/${airline_code}/"
    update_ini_value "$ini_file" "sitePath" "$new_site_path"

    echo "Updated site/airline config in: $ini_file"
}

echo "Excecuted here line number is ========> $LINENO"
# Add '<code>' to the $PossibleAirlineCodes = [...]; array in a cron config file,
# if it isn't already one of the array's elements (handles the array spanning
# multiple lines).
update_php_possible_airline_codes() {
    local php_file="$1" airline_code="$2"

    grep -q '\$PossibleAirlineCodes' "$php_file" || return

    local array_block
    array_block=$(awk '/\$PossibleAirlineCodes/{f=1} f{print; if (/\];/) exit}' "$php_file")

    if grep -qF "'${airline_code}'" <<< "$array_block"; then
        return
    fi

    local insert=", '${airline_code}'];"
    awk -v ins="$insert" '
        /\$PossibleAirlineCodes/ { in_arr = 1 }
        in_arr && /\];/ && !done {
            sub(/\];/, ins)
            done = 1
        }
        { print }
    ' "$php_file" > "${php_file}.tmp" && mv "${php_file}.tmp" "$php_file"

    echo "Added '${airline_code}' to \$PossibleAirlineCodes in: $php_file"
}

echo "Excecuted here line number is ========> $LINENO"
update_cron_config() {
    local php_file="$1" airline_code="$2"

    # $sitePath assignment lives above the `$CFG['path']['sitePath'] = $sitePath;` line
    local anchor_line
    anchor_line=$(grep -nE "\\\$CFG\['path'\]\['sitePath'\][[:space:]]*=[[:space:]]*\\\$sitePath[[:space:]]*;" "$php_file" \
        | tail -n1 | cut -d: -f1)

    if [[ -z "$anchor_line" ]]; then
        echo "Skipping sitePath update — expected structure not found in: $php_file"
    else
        local site_line
        site_line=$(head -n "$anchor_line" "$php_file" \
            | grep -nE "^[[:space:]]*\\\$sitePath[[:space:]]*=[[:space:]]*[\"'].*[\"']" \
            | tail -n1 | cut -d: -f1)

        if [[ -n "$site_line" ]]; then
            local current_value new_value escaped_value
            current_value=$(sed -n "${site_line}p" "$php_file" | grep -oE "[\"'][^\"']*[\"']" | head -n1 | tr -d "\"'")
            new_value=$(derive_site_path "$current_value")
            escaped_value=$(sed_escape_replacement "$new_value")
            sed -i -E "${site_line}s/=([[:space:]]*)[\"'][^\"']*[\"']/=\1'${escaped_value}'/" "$php_file"
            echo "Updated \$sitePath in: $php_file"
        fi
    fi

    # Default airline code in: $CFG['default']['airlineCode'] = isset($argv[1])?$argv[1]:'XX';
    local air_line
    air_line=$(grep -nE "\\\$CFG\['default'\]\['airlineCode'\][[:space:]]*=[[:space:]]*isset\(\\\$argv\[1\]\)" "$php_file" \
        | grep -v ':[[:space:]]*//' | tail -n1 | cut -d: -f1)

    if [[ -n "$air_line" ]]; then
        local escaped_code
        escaped_code=$(sed_escape_replacement "$airline_code")
        sed -i -E "${air_line}s/(:)([\"'])[^\"']*([\"'])([[:space:]]*;)/\1\2${escaped_code}\3\4/" "$php_file"
        echo "Updated default airlineCode in: $php_file"
    fi

    update_php_possible_airline_codes "$php_file" "$airline_code"
}

echo "Excecuted here line number is ========> $LINENO"

# Comment out every line referencing setUserPassword (login-as-user backdoor),
# preserving existing indentation. Idempotent — already-commented lines are skipped.
comment_set_user_password() {
    local file="$1"
    [[ -e "$file" ]] || return

    sed -i -E '/setUserPassword/{ /^[[:space:]]*\/\//! s/^([[:space:]]*)/\1\/\//; }' "$file"
    echo "Commented setUserPassword lines in: $file"
}

update_site_and_airline_config() {
    local project="$1" airline_code="$2"

    if [[ -z "$airline_code" ]]; then
        echo "No airline code resolved — skipping site/airline config update."
        return
    fi

    local ini_file="${project}environments/config.ini"
    local cron_file="${project}cron/config.cron.php"

    if [[ -e "$ini_file" ]]; then
        update_site_config_ini "$ini_file" "${airline_code^^}"
    elif [[ -e "$cron_file" ]]; then
        update_cron_config "$cron_file" "${airline_code^^}"
    else
        echo "No environments/config.ini or cron/config.cron.php found — skipping site/airline config update."
    fi

    comment_set_user_password "${project}classesTpl/class.tpl.loginForm.php"
}

# ── Resolve airline code ──────────────────────────────────────────────────────
database_name=$(find_database_name)
echo "Database: $database_name"

airline_code=$(find_airline_code_from_db "$database_name")
echo "Airline code from DB: $airline_code"

if [[ "$configuration" =~ "config" && -z "$airline_code" ]]; then
    airline_code=$(prompt_airline_code)
    if [[ -z "$airline_code" ]]; then
        rofi -e "Airline code is required for config deletion."
        exit 1
    fi
fi

echo "Airline code: $airline_code"
echo "Plugins path: ${selected_project}plugins/${airline_code^^}/"

# ── Site path / airline code config ───────────────────────────────────────────
#update_site_and_airline_config "$selected_project" "$airline_code"

# ── QUERY_FILE deletion ───────────────────────────────────────────────────────
if [[ "$configuration" =~ "QUERY" ]]; then
    query_dir="${selected_project}QUERY_FILE"
    if [[ -d "$query_dir" ]]; then
        rm -rf "${query_dir:?}"/*
        echo "Deleted: $query_dir"
        SUCCESS_MESSAGE_CONTENT+="* QUERY FILE DELETED\n"
    fi
fi

# ── templates_c deletion ──────────────────────────────────────────────────────
templates_c="${selected_project}smarty/templates_c/"
if [[ -d "$templates_c" ]]; then
    rm -f "$templates_c"*
    echo "Deleted: $templates_c"
    SUCCESS_MESSAGE_CONTENT+="* TEMPLATES_C FILES DELETED\n"
fi

# ── combine JS/CSS deletion ───────────────────────────────────────────────────
echo "configuration is ============> $configuration"
if [[ "$configuration" =~ "combine" ]]; then
    echo "combined js delete"
    find "$selected_project" -type f -name "*combine*" -delete
    echo "Deleted combine JS/CSS files"
    SUCCESS_MESSAGE_CONTENT+="* COMBINE JS AND CSS DELETED\n"
fi

# ── Static JSON deletion ──────────────────────────────────────────────────────
static_json="${selected_project}reportData/staticTablesJson"
if [[ -d "$static_json" ]]; then
    rm -f "$static_json"/*
    echo "Deleted: $static_json"
    SUCCESS_MESSAGE_CONTENT+="* STATIC JSON DELETED\n"
fi

# ── Config / plugin deletions ─────────────────────────────────────────────────
if [[ "$configuration" =~ "config" ]]; then

    plugins_lang="${selected_project}plugins/${airline_code^^}/language"
    echo "Plugins language dir: $plugins_lang"

    if [[ "$configuration" =~ "rm lang files other than en" ]] && [[ -d "$plugins_lang" ]]; then
        for lan in "$plugins_lang"/*/; do
            [[ "$lan" == */en_language/ ]] && continue
            rm -rf "$lan"
            echo "Deleted plugin language: $lan"
        done
    fi

    plugins_config="${selected_project}plugins/${airline_code^^}/config"
    if [[ -d "$plugins_config" ]]; then
        rm -f "${plugins_config}/config.common.php"
        echo "Deleted: ${plugins_config}/config.common.php"
        SUCCESS_MESSAGE_CONTENT+="* CONFIG FILE DELETED\n"
    fi

fi

# ── Language directory deletion ───────────────────────────────────────────────
if [[ "$configuration" =~ "rm lang files other than en" ]]; then
    lang_dir="${selected_project}language/"
    if [[ -d "$lang_dir" ]]; then
        for d in "$lang_dir"/*/; do
            [[ "$d" == */en_language/ ]] && continue
            rm -rf "$d"
            echo "Deleted language: $d"
            SUCCESS_MESSAGE_CONTENT+="* NON-EN LANGUAGE FILES DELETED\n"
        done
    fi
fi

# Update the project permission to chmod 777 for all files and directories
# check the existing project have permission 777 or not, if not then change the permission to 777 for all files and directories
if [[ ! -z "$selected_project" ]]; then
    if [[ -d "$selected_project" ]]; then
        echo "Changing permissions to 777 for all files and directories in: $selected_project"
        chmod -R 777 "$selected_project"
        SUCCESS_MESSAGE_CONTENT+="* PERMISSIONS CHANGED TO 777 FOR ALL FILES AND DIRECTORIES\n"
    else
        echo "Selected project directory does not exist: $selected_project"
    fi
fi


# ── Result ────────────────────────────────────────────────────────────────────
if [[ -z "$SUCCESS_MESSAGE_CONTENT" ]]; then
    SUCCESS_MESSAGE_CONTENT="Nothing to delete — all cache files already clean."
fi

echo -e "\n=== Done ===\n$SUCCESS_MESSAGE_CONTENT"
notify-send "Pack Setup" "$(echo -e "$SUCCESS_MESSAGE_CONTENT")" -i dialog-information 2>/dev/null || true
