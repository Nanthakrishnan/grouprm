#!/bin/bash

# Define constants (readonly vars) for option texts
readonly OPT1="GroupRM project Pack_setup"
readonly OPT2="Launch GroupRM project"
readonly OPT3="Code GroupRM project"
readonly OPT4="Svn GroupRM project"
readonly OPT5="Set PHP version to 7.3"
readonly OPT6="Set PHP version to 8.3"
readonly OPT7="Set PHP version to 5.6"
readonly OPT8="Svn and mysql configuration"
readonly OPT9="Group Rm project directory configuration"
readonly OPT10="QUERY_FILE_DIRECTORY_OPEN"
readonly OPT11="GroupRM project Update SVN"
readonly OPT12="SVN Checkout"
readonly OPT13="Database switch"
readonly OPT14="Redmine Time Log"
readonly OPT15="Update Scripts"

# Build menu options array from constants
OPTIONS=("$OPT1" "$OPT2" "$OPT3" "$OPT12" "$OPT4" "$OPT10" "$OPT11" "$OPT5" "$OPT6" "$OPT7" "$OPT8" "$OPT9" "$OPT13" "$OPT14" "$OPT15")

# Convert options array to a newline-separated string for rofi
MENU=$(printf "%s\n" "${OPTIONS[@]}")

# Display rofi menu and capture the selected option
SELECTED=$(echo -e "$MENU" | rofi -dmenu -i -p  "Select an option: ")

# Handle the selected option
case "$SELECTED" in
    "$OPT8")
        # /home/nanthakrishnan.j/bashscripts/config_manager.sh
        if [ -f "$HOME/bashscripts/config_manager.sh" ]; then
            bash "$HOME/bashscripts/config_manager.sh"
        else
            notify-send "Error" "config_manager.sh not found in $HOME"
            exit 1
        fi
        ;;
    "$OPT9")
        # /home/nanthakrishnan.j/bashscripts/config_manager.sh
        if [ -f "$HOME/bashscripts/grouprm_project_dir_configuration.sh" ]; then
            bash "$HOME/bashscripts/grouprm_project_dir_configuration.sh"
        else
            notify-send "Error" "config_setup sh not found in $HOME"
            exit 1
        fi
        ;;
    "$OPT4")
        # /home/nanthakrishnan.j/bashscripts/config_manager.sh
        if [ -f "$HOME/bashscripts/kdesvn.sh" ]; then
            bash "$HOME/bashscripts/kdesvn.sh"
        else
            notify-send "Error" "config_setup sh not found in $HOME"
            exit 1
        fi
        ;;
    "$OPT7")
        sudo service php7.3-fpm stop
        sudo service php8.3-fpm stop
        sudo service php5.6-fpm start
        sudo service nginx restart
        notify-send "PHP Version" "Switched to PHP 5.6"
        ;;
    "$OPT5")
        sudo service php5.6-fpm stop
        sudo service php8.3-fpm stop
        sudo service php7.3-fpm start
        sudo service nginx restart
        notify-send "PHP Version" "Switched to PHP 7.3"
        ;;
    "$OPT6")
        sudo service php5.6-fpm stop
        sudo service php7.3-fpm stop
        sudo service php8.3-fpm start
        sudo service nginx restart
        notify-send "PHP Version" "Switched to PHP 8.3"
        ;;
    "$OPT1")
        if [ -f "$HOME/bashscripts/pack_setup.sh" ]; then
            bash "$HOME/bashscripts/pack_setup.sh"
        else
            notify-send "Error" "pack_setup.sh not found in $HOME"
            exit 1
        fi
        ;;
    "$OPT3")
        if [ -f "$HOME/bashscripts/code_grouprm_project.sh" ]; then
            bash "$HOME/bashscripts/code_grouprm_project.sh"
        else
            notify-send "Error" "code_group_rm_project.sh not found in $HOME"
            exit 1
        fi
        ;;
    "$OPT2")
        if [ -f "$HOME/bashscripts/launch_grouprm_project.sh" ]; then
            bash "$HOME/bashscripts/launch_grouprm_project.sh"
        else
            notify-send "Error" "launch_group_rm_project.sh not found in $HOME"
            exit 1
        fi
        ;;

    "$OPT10")
        if [ -f "$HOME/bashscripts/query_file_dir_open.sh" ]; then
            bash "$HOME/bashscripts/query_file_dir_open.sh"
        else
            notify-send "Error" "query file directory script not found in $HOME"
            exit 1
        fi
        ;;
    "$OPT11")
        if [ -f "$HOME/bashscripts/svn_up.sh" ]; then
            bash "$HOME/bashscripts/svn_up.sh"
        else
            notify-send "Error" "svn update script not found in $HOME"
            exit 1
        fi
        ;;
    "$OPT12")
        if [ -f "$HOME/bashscripts/svn_checkout.sh" ]; then
            bash "$HOME/bashscripts/svn_checkout.sh"
        else
            notify-send "Error" "svn checkout script not found in $HOME"
            exit 1
        fi
        ;;
    "$OPT13")
        if [ -f "$HOME/bashscripts/database_switch.sh" ]; then
            bash "$HOME/bashscripts/database_switch.sh"
        else
            notify-send "Error" "database_switch.sh not found in $HOME"
            exit 1
        fi
        ;;
    "$OPT14")
        if [ -f "$HOME/redmine/redmine_log.sh" ]; then
            bash "$HOME/redmine/redmine_log.sh"
        else
            notify-send "Error" "redmine_log.sh not found in $HOME/redmine"
            exit 1
        fi
        ;;
    "$OPT15")
        if [ -f "$HOME/bashscripts/install.sh" ]; then
            bash "$HOME/bashscripts/install.sh"
        else
            notify-send "Error" "install.sh not found in $HOME/bashscripts"
            exit 1
        fi
        ;;
    *)
        # notify-send "Error" "No valid option selected"
        exit 1
        ;;
esac