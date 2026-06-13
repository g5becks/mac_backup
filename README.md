# mac_backup

Dotfiles and cross-platform setup for macOS and Windows + WSL.

Managed with [yadm](https://yadm.io) (dotfiles) and [mise](https://mise.jdx.dev) (tools/runtimes).

---

## New Machine Setup

### Step 1 — Windows apps (run in PowerShell as Administrator)

Download and run the winget install script from this repo:

```powershell
# Download
curl -o install.ps1 https://raw.githubusercontent.com/g5becks/mac_backup/main/windows-setup/install.ps1

# Run
.\install.ps1
```

This installs: PowerToys, WezTerm, Firefox Developer Edition, Bitwarden, Discord, Telegram, Canva, CapCut, ONLYOFFICE, Antigravity, and the X (Twitter) app.

> If any package fails, find the correct ID with `winget search <name>` and re-run:
> `winget install --id <PackageID> -e`

---

### Step 2 — WezTerm config

Copy the WezTerm config from this repo to your Windows user profile:

```powershell
curl -o "$env:USERPROFILE\.wezterm.lua" https://raw.githubusercontent.com/g5becks/mac_backup/main/windows-setup/wezterm.lua
```

> **Font:** The config uses Cartograph CF. If you don't have it, open `~\.wezterm.lua`
> and change the font line to `wezterm.font 'JetBrainsMono Nerd Font'`.

WezTerm connects to WSL automatically once WSL is set up (Step 3).
To verify your WSL distro name run `wsl --list` and update `wezterm.lua` if needed.

---

### Step 3 — Install WSL

In PowerShell as Administrator:

```powershell
wsl --install
```

Restart when prompted, then open WSL and set a username/password.

---

### Step 4 — WSL bootstrap

Inside WSL, download and run the bootstrap script:

```bash
curl -fLo wsl-bootstrap.sh \
  https://raw.githubusercontent.com/g5becks/mac_backup/main/windows-setup/wsl-bootstrap.sh
bash wsl-bootstrap.sh
```

This installs: apt system packages, mise, yadm, zimfw, and sets zsh as the default shell.

---

### Step 5 — SSH key for GitHub

```bash
ssh-keygen -t ed25519 -C 'techstar.dev@hotmail.com' -f ~/.ssh/github
cat ~/.ssh/github.pub
```

Add the printed public key to GitHub → **Settings → SSH and GPG keys → New SSH key**.

Test it:

```bash
ssh -T git@github.com
```

---

### Step 6 — Restore dotfiles

```bash
~/.local/bin/yadm clone git@github.com:g5becks/mac_backup.git
~/.local/bin/yadm alt
```

`yadm alt` activates OS-specific alternate files (`.zshrc`, `.ssh/config`, etc.).

---

### Step 7 — Install all tools

```bash
mise install
```

This installs all runtimes and CLI tools defined in `~/.config/mise/config.toml`.

---

### Step 8 — Finish

```bash
exec zsh
```

Your prompt, aliases, completions, and tools should all be active.

---

## What's in this repo

| Path | Description |
|------|-------------|
| `.config/mise/config.toml` | All runtimes and CLI tools (node, go, rust, python, helix, lazygit, etc.) |
| `.config/helix/` | Helix editor config and LSP setup |
| `.config/zellij/` | Zellij terminal multiplexer layouts |
| `.config/yazi/` | Yazi file manager config |
| `.config/lazygit/config.yml` | Lazygit config |
| `.config/starship.toml` | Starship prompt |
| `.config/zsh/` | Zsh config files |
| `.config/broot/` | Broot file navigator |
| `.config/git/` | Global git ignore |
| `.config/gh/config.yml` | GitHub CLI config |
| `.config/agents/skills/` | Claude Code custom skills |
| `.claude/settings.json` | Claude Code hooks and plugins |
| `.gitconfig` | Global git config (name, email) |
| `.wezterm.lua` | WezTerm config for macOS |
| `.zshrc##os.Darwin` | macOS zsh config |
| `.zshrc##os.Linux` | Linux/WSL zsh config |
| `.ssh/config##os.Darwin` | macOS SSH config (includes colima) |
| `.ssh/config##os.Linux` | Linux/WSL SSH config |
| `.zshenv` | Cargo env sourcing |
| `windows-setup/install.ps1` | Winget install script |
| `windows-setup/wezterm.lua` | WezTerm config for Windows + WSL |
| `windows-setup/wsl-bootstrap.sh` | WSL initial setup script |

---

## macOS restore

On a fresh Mac with yadm already installed:

```bash
yadm clone git@github.com:g5becks/mac_backup.git
yadm alt
mise install
exec zsh
```
