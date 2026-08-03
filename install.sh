#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${MENU_REPO_URL:-https://github.com/Nanthakrishnan/grouprm.git}"
INSTALL_DIR="${MENU_INSTALL_DIR:-$HOME/bashscripts}"
SHORTCUT_NAME="GroupRM Menu"
SHORTCUT_BINDING="${MENU_SHORTCUT:-<Super>m}"
REDMINE_SHORTCUT_NAME="Redmine Time Log"
REDMINE_SHORTCUT_BINDING="${REDMINE_SHORTCUT:-<Super>r}"
REDMINE_SCRIPT="$HOME/redmine/redmine_log.sh"
DEPS=(rofi yad xclip libnotify-bin git)

say()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31mxx\033[0m %s\n' "$*" >&2; exit 1; }

install_deps() {
    local missing=()
    for pkg in "${DEPS[@]}"; do
        dpkg -s "$pkg" >/dev/null 2>&1 || missing+=("$pkg")
    done

    if [ ${#missing[@]} -eq 0 ]; then
        say "All dependencies present."
        return
    fi

    say "Installing: ${missing[*]}"
    sudo apt-get update -qq
    sudo apt-get install -y "${missing[@]}"
}

sync_repo() {
    if [ -d "$INSTALL_DIR/.git" ]; then
        say "Updating existing install at $INSTALL_DIR"
        git -C "$INSTALL_DIR" pull --ff-only
    elif [ -e "$INSTALL_DIR" ]; then
        local backup="${INSTALL_DIR}_backup_$(date +%Y%m%d_%H%M%S)"
        warn "$INSTALL_DIR exists but is not a git clone — moving it to $backup"
        mv "$INSTALL_DIR" "$backup"
        say "Cloning into $INSTALL_DIR"
        git clone "$REPO_URL" "$INSTALL_DIR"
    else
        say "Cloning into $INSTALL_DIR"
        git clone "$REPO_URL" "$INSTALL_DIR"
    fi

    chmod +x "$INSTALL_DIR"/*.sh
}

# GNOME stores custom shortcuts as a list of dconf paths. Reuse the slot that
# already holds our shortcut so re-running never creates duplicates.
# Usage: register_shortcut <name> <binding> <command>
register_shortcut() {
    local name="$1" binding="$2" cmd="$3"
    local schema=org.gnome.settings-daemon.plugins.media-keys
    local kb_schema=$schema.custom-keybinding
    local base=/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings

    if ! command -v gsettings >/dev/null 2>&1; then
        warn "gsettings not found — bind '$cmd' to a key manually."
        return
    fi

    local existing
    existing=$(gsettings get "$schema" custom-keybindings)

    # Parse every existing binding path out of the gsettings list, in order.
    # We keep this full set so we can preserve all of them when appending.
    local paths=() p
    while IFS= read -r p; do
        [ -n "$p" ] && paths+=("$p")
    done < <(printf '%s\n' "$existing" | grep -oE "/[^']*/" || true)

    # Reuse our slot if it already exists anywhere in the list (idempotent
    # re-runs, and non-contiguous slots don't fool us into duplicating). If
    # the user has since rebound it to a different key than our default,
    # that's their choice — leave the binding alone and only refresh
    # name/command, so re-running install.sh never resets a customized key.
    local slot="" reused=0
    if [ ${#paths[@]} -gt 0 ]; then
        for p in "${paths[@]}"; do
            if [ "$(gsettings get "$kb_schema:$p" command)" = "'$cmd'" ]; then
                slot="$p"
                reused=1
                break
            fi
        done
    fi

    if [ "$reused" -eq 1 ]; then
        local current_binding current_name
        current_binding=$(gsettings get "$kb_schema:$slot" binding 2>/dev/null || echo "")
        current_name=$(gsettings get "$kb_schema:$slot" name 2>/dev/null || echo "")
        say "Already set up: ${current_binding//\'/} -> ${current_name//\'/} (left as-is)"
        return
    fi

    # If some OTHER command already owns this binding, don't silently steal
    # it — the user may have that key mapped to something unrelated on purpose.
    if [ -z "$slot" ] && [ ${#paths[@]} -gt 0 ]; then
        for p in "${paths[@]}"; do
            local existing_binding existing_cmd
            existing_binding=$(gsettings get "$kb_schema:$p" binding 2>/dev/null || echo "")
            existing_cmd=$(gsettings get "$kb_schema:$p" command 2>/dev/null || echo "")
            if [ "$existing_binding" = "'$binding'" ] && [ "$existing_cmd" != "'$cmd'" ]; then
                warn "Binding '$binding' is already used by: $existing_cmd — skipping '$name'."
                warn "Pick a different key, e.g.: REDMINE_SHORTCUT='<Super>t' bash $INSTALL_DIR/install.sh"
                return
            fi
        done
    fi

    if [ -z "$slot" ]; then
        # Find the lowest customN index not already present in the list.
        local i=0 candidate used
        while :; do
            candidate="$base/custom$i/"
            used=0
            if [ ${#paths[@]} -gt 0 ]; then
                for p in "${paths[@]}"; do
                    [ "$p" = "$candidate" ] && { used=1; break; }
                done
            fi
            [ "$used" -eq 0 ] && break
            i=$((i + 1))
        done
        slot="$candidate"

        # Rebuild the list from every existing entry + our new slot, so no
        # other application's shortcut is ever dropped or overwritten.
        local items=""
        if [ ${#paths[@]} -gt 0 ]; then
            for p in "${paths[@]}"; do
                items+="'$p', "
            done
        fi
        items+="'$slot'"
        gsettings set "$schema" custom-keybindings "[$items]"
    fi

    gsettings set "$kb_schema:$slot" name "$name"
    gsettings set "$kb_schema:$slot" command "$cmd"
    gsettings set "$kb_schema:$slot" binding "$binding"

    say "Shortcut bound: $binding -> $name"
}

install_deps
sync_repo
register_shortcut "$SHORTCUT_NAME" "$SHORTCUT_BINDING" "bash $INSTALL_DIR/menu.sh"

if [ -f "$REDMINE_SCRIPT" ]; then
    register_shortcut "$REDMINE_SHORTCUT_NAME" "$REDMINE_SHORTCUT_BINDING" "bash $REDMINE_SCRIPT"
else
    warn "$REDMINE_SCRIPT not found — skipping Redmine shortcut (still reachable from the menu)."
fi

cat <<EOF

Done. Press $SHORTCUT_BINDING to open the menu, $REDMINE_SHORTCUT_BINDING to log Redmine time.

Update later:      bash $INSTALL_DIR/install.sh
Change menu key:   MENU_SHORTCUT='<Super>g' bash $INSTALL_DIR/install.sh
Change redmine key: REDMINE_SHORTCUT='<Super>t' bash $INSTALL_DIR/install.sh
EOF
