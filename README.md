# grouprm

A rofi menu for the GroupRM project's daily PHP/SVN/MySQL grind — fuzzy-pick
a task by name instead of remembering which terminal command or config file
does it.

```
$ bash menu.sh
> Select an option:
  GroupRM project Pack_setup
  Launch GroupRM project
  Code GroupRM project
  SVN Checkout
  Svn GroupRM project
  QUERY_FILE_DIRECTORY_OPEN
  GroupRM project Update SVN
  Set PHP version to 7.3
  Set PHP version to 8.3
  Set PHP version to 5.6
  Svn and mysql configuration
  Group Rm project directory configuration
  Database switch
  Redmine Time Log
  Update Scripts
```

## What's here

Only what `menu.sh` actually launches, plus their shared dependencies —
nothing else from the wider scratch directory this was developed in.

| Menu entry | Script | Does |
|---|---|---|
| GroupRM project Pack_setup | `pack_setup.sh` | Cache cleanup + rewrites airline code / site path in the project's config |
| Launch GroupRM project | `launch_grouprm_project.sh` | Opens a picked project in the browser |
| Code GroupRM project | `code_grouprm_project.sh` | Opens a picked project in your editor |
| SVN Checkout | `svn_checkout.sh` | Checks out a project, then rewrites its DB config to match |
| Svn GroupRM project | `kdesvn.sh` | Opens a picked project in kdesvn |
| QUERY_FILE_DIRECTORY_OPEN | `query_file_dir_open.sh` | Jumps to a project's QUERY_FILE directory |
| GroupRM project Update SVN | `svn_up.sh` | `svn up` on a picked project |
| Set PHP version to 7.3 / 8.3 / 5.6 | *(inline in menu.sh)* | Switches the active php-fpm version and restarts nginx |
| Svn and mysql configuration | `config_manager.sh` | Prompts for SVN/MySQL credentials once, saves to `~/.svn_mysql_config` |
| Group Rm project directory configuration | `grouprm_project_dir_configuration.sh` | Sets the base directory every other script searches under |
| Database switch | `database_switch.sh` | Fuzzy-pick and switch the active project database |
| Redmine Time Log | *(external)* | Launches `~/redmine/redmine_log.sh` if that's set up ([separate repo](https://github.com/Nanthakrishnan/redmine)) |
| Update Scripts | `install.sh` | Re-clones/pulls this repo and re-registers the keybinding — self-update, no manual steps |

`common.sh` and `grouprm_project_finder.sh` are shared plumbing (project
discovery under a configured base directory) that most of the above source;
they're not menu entries themselves.

## Setup

```bash
curl -fsSL https://raw.githubusercontent.com/Nanthakrishnan/grouprm/main/install.sh | bash
```

or, if you'd rather see the script first:

```bash
git clone https://github.com/Nanthakrishnan/grouprm.git ~/bashscripts
bash ~/bashscripts/install.sh
```

`install.sh` installs missing dependencies (`rofi`, `yad`, `xclip`,
`libnotify-bin`, `git`) via apt, clones/pulls the repo, and registers a
GNOME keybinding (default `<Super>m`) for `menu.sh`. Re-running it later —
including via the "Update Scripts" menu entry — just pulls the latest
scripts; it never resets a shortcut you've since rebound to a different key.

Before first use, run **Svn and mysql configuration** and **Group Rm project
directory configuration** from the menu once, so `~/.svn_mysql_config` and
the project base directory are set.

## Config files

- `~/.svn_mysql_config` — SVN/MySQL credentials, written by `config_manager.sh`, `chmod 600`. Never committed.
- `~/.base_dir.conf` — the base directory `grouprm_project_finder.sh` searches under for project folders.

Change the keybinding key: `MENU_SHORTCUT='<Super>g' bash install.sh`
