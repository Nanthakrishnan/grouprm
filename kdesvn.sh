#!/bin/bash


source "$HOME/bashscripts/common.sh"
source $HOME/.svn_mysql_config


# bash "/home/nanthakrishnan.j/rofi/quick_clipmenu_copy.sh"
echo -n "$SVN_PASSWORD" | xclip -selection clipboard
echo "selected project => $selected_project"

if [[ -n "$selected_project" ]]; then
  echo "MY_VAR is not empty."
    kdesvn "$selected_project"
fi
