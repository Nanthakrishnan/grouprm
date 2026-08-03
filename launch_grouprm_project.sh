#!/bin/bash

source "$HOME/bashscripts/common.sh"

selected_project=${selected_project#/home/Staging/}
selected_project=${selected_project%/}

echo "selected Project : $selected_project";

if [[ -z "$selected_project" ]]; then
	# zenity --info --text="No project selected!"
	exit 1
fi

# get the query param
# query_param=$(rofi -dmenu -p "ENTER QUERY PARAM IF PRESENT")

if [[ -z "$query_param" ]]; then
	google-chrome "http://localhost/${selected_project}/"
else
	google-chrome "http://localhost/${selected_project}/?${query_param}"
fi
