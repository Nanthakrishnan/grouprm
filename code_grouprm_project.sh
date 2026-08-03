#!/bin/bash

source "$HOME/bashscripts/common.sh"

if [ -z "$selected_project" ] || [ ! -d "$selected_project" ]; then
    echo "No valid project selected."
    exit 1
fi

# Define possible editors: "display_name:command [extra_args_if_needed]"
# Order here = order in menu (you can put your favorites first)
editors=(
    "VS Code:code"
    "Zed:zed"
    "Antigravity:antigravity"   # assuming it has a 'antigravity' CLI command
    "PyCharm:pycharm"           # or 'pycharm.sh' on some installs
    "Sublime Text:subl"
    "Vim:vim"
    "Neovim:nvim"
    "Neovide:neovide"
    "Cursor:cursor"
    "VSCodium:codium"
    # Add more if you want, e.g.
)

# Dynamically build list of installed editors
available=()
for entry in "${editors[@]}"; do
    name="${entry%%:*}"
    cmd="${entry#*:}"
    # Check if the command exists and is executable
    if command -v "${cmd%% *}" >/dev/null 2>&1; then
        available+=("$name:$cmd")
    fi
done

if [ ${#available[@]} -eq 0 ]; then
    echo "No supported code editors found in PATH."
    exit 1
fi

# If only one editor is available, open it directly (ultra fast, no prompt)
if [ ${#available[@]} -eq 1 ]; then
    cmd="${available[0]#*:}"
    echo "Opening with only available editor: ${available[0]%%:*}"
    $cmd "$selected_project" &
    exit 0
fi

# Build clean list for rofi (just the display names)
menu_items=()
for item in "${available[@]}"; do
    menu_items+=("${item%%:*}")
done

# Show ultra-fast rofi prompt (dmenu style, case insensitive, etc.)
chosen=$(printf '%s\n' "${menu_items[@]}" | rofi -dmenu -i -p "Open project in:" -theme-str 'window {width: 400px;}')

if [ -z "$chosen" ]; then
    echo "Cancelled."
    exit 0
fi

# Find the corresponding command and run it
for item in "${available[@]}"; do
    if [ "${item%%:*}" = "$chosen" ]; then
        cmd="${item#*:}"
        echo "Opening $selected_project with $chosen ($cmd)"
        # Run in background so script dadd9c80673oesn't hang
        $cmd "$selected_project" &
        break
    fi
done

if [ -n "$selected_project" ]; then
	code "$selected_project"
fi
