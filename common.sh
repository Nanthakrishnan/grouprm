#!/bin/bash

source $HOME/bashscripts/grouprm_project_finder.sh

# Use rofi to prompt the user to select a project
selected_project=$(printf '%s\n' "${PROJECT_ARRAY[@]}" | rofi -dmenu -i -p "Select Project")

# add the slash at the end of the project 
selected_project="$selected_project/"
