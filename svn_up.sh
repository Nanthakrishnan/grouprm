#!/bin/bash

source "$HOME/bashscripts/common.sh"
source $HOME/.svn_mysql_config

if [ -n "$selected_project" ]; then
	svn up "$selected_project"
fi