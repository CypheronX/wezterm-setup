# wezterm-setup

WezTerm on Windows, set up like a Linux terminal: **Git Bash** as the shell, a zsh-style experience (Starship prompt, fzf, zoxide, oh-my-zsh git aliases), Catppuccin Mocha looks, plus **GitHub CLI** and **Claude Code**.

## Install

```powershell
git clone https://github.com/CypheronX/wezterm-setup.git $HOME\wezterm-setup
powershell -ExecutionPolicy Bypass -File $HOME\wezterm-setup\install.ps1
```

No git yet? If the repo is public:

```powershell
irm https://raw.githubusercontent.com/CypheronX/wezterm-setup/main/install.ps1 | iex
```

The script:

1. Installs with winget (skipping anything already present): WezTerm, Git for Windows, Starship, fzf, zoxide, JetBrainsMono Nerd Font, GitHub CLI, Claude Code
2. Copies the configs from `config/` into your home folder (existing files are backed up as `*.bak-<timestamp>`)
3. Sets sensible global git defaults and asks for `user.name` / `user.email` if missing

Flags: `-SkipApps` (configs only), `-NoBackup`.

To update a machine later: `git pull` then re-run with `-SkipApps`.

| File | Goes to |
|---|---|
| `config/.wezterm.lua` | `~/.wezterm.lua` |
| `config/.bashrc`, `.bash_profile`, `.inputrc` | `~/` |
| `config/starship.toml` | `~/.config/starship.toml` |

## Cheatsheet

### WezTerm

| Keys | Action |
|---|---|
| `Ctrl+C` / `Ctrl+V` | copy (if selection, else interrupt) / paste; right-click pastes |
| `Ctrl+T`, `Ctrl+Tab` | new tab, next tab |
| `Ctrl+Shift+R` | rename tab |
| `Ctrl+Shift+D` / `E` | split right / down |
| `Alt+Arrows` / `Alt+Shift+Arrows` | move between / resize splits |
| `Ctrl+Shift+Z` | zoom split |
| `Ctrl+Shift+W` | close split |
| `Ctrl+Shift+A` | Claude Code in a split |
| `Ctrl+Shift+L` | launcher (PowerShell, CMD, ...) |
| `Ctrl+Shift+P` | command palette |
| `Ctrl+Shift+F` | search scrollback |

### Shell

| Keys / command | Action |
|---|---|
| `Tab` / `Shift+Tab` | cycle completions (case-insensitive) |
| `Up` / `Down` | history search by typed prefix |
| `Ctrl+R` / `Ctrl+T` / `Alt+C` | fzf history / file / cd |
| `z <part>` / `zi` | jump to a visited folder |
| `cc` / `ccc` | `claude` / `claude --continue` |

### Git

| Alias | Command |
|---|---|
| `gst` | status -sb |
| `ga`, `gaa`, `gap` | add, add --all, add -p |
| `gcm "msg"`, `gca`, `gcan` | commit -m, amend, amend --no-edit |
| `gsw`, `gswc`, `gco` | switch, switch -c, checkout |
| `gd`, `gds` | diff, diff --staged |
| `gl`, `gp`, `gpf`, `gpsup` | pull, push, push --force-with-lease, push upstream |
| `grb`, `grbi`, `grbc`, `grba` | rebase (interactive/continue/abort) |
| `gsta`, `gstp`, `gstl` | stash push / pop / list |
| `glog`, `gloga` | pretty graph log |
| `gundo` | undo last commit, keep changes |
| `gcb` | fuzzy branch switch (with preview) |
| `gadd` | fuzzy pick files to stage |
| `gshow` | fuzzy browse commits |
