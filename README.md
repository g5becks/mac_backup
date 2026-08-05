# mac_backup

Dotfiles and remote development environment for macOS and headless Linux, built around [Moshi](https://getmoshi.app) for mobile-first coding.

Managed with [yadm](https://yadm.io) (dotfiles) and [mise](https://mise.jdx.dev) (tools/runtimes).

---

## What this repo is for

This started as a Mac + Windows/WSL dotfiles backup. It's now built around a different workflow: **development happens on an always-on remote Linux server, accessed from a phone or tablet through Moshi** — not on a local laptop.

The reasoning: local hardware (touchscreens, cramped keyboards, unreliable connectivity) is a bad fit for sustained coding, but a phone is always in hand. Moshi turns a phone into a real terminal into a machine that never sleeps, never loses your session on a dropped connection, and keeps long-running agents (Claude Code, build processes, dev servers) alive independent of whether your device is even open.

Two environments are covered here:

- **A headless Ubuntu VPS** — the actual development machine. No desktop environment, no GUI apps. Everything is terminal-based: Helix for editing, tmux/Herdr for session persistence, Claude Code and friends for agent-assisted development.
- **macOS** — a secondary, optional environment for when a full keyboard, mouse, and monitor are actually available. Same Helix setup as the VPS — one editor config across both environments, nothing to duplicate or keep in sync.

Neither environment assumes the other is present. The VPS is the source of truth for active projects; macOS is a convenience layer on top of the same dotfiles.

---

## What's in this repo

| Path | Description |
|------|-------------|
| `.config/mise/config.toml` | All runtimes and CLI tools (node, bun, go, rust, python, helix, herdr, lazygit, etc.) |
| `.config/helix/` | Helix editor config and LSP setup |
| `.config/yazi/` | Yazi file manager config |
| `.config/lazygit/config.yml` | Lazygit config |
| `.config/starship.toml` | Starship prompt |
| `.config/zsh/` | Zsh config files |
| `.config/git/` | Global git ignore |
| `.config/gh/config.yml` | GitHub CLI config |
| `.config/agents/skills/` | Claude Code custom skills |
| `.config/opencode/` | OpenCode config |
| `.config/mcp-config.json` | MCP server config |
| `.claude/settings.json` | Claude Code hooks and plugins |
| `.gitconfig` | Global git config (name, email) |
| `.zshrc##os.Darwin` | macOS zsh config |
| `.zshrc##os.Linux` | Linux (VPS) zsh config |
| `.ssh/config##os.Darwin` | macOS SSH config |
| `.ssh/config##os.Linux` | Linux SSH config |
| `.zshenv` | Cargo env sourcing |
| `bootstrap.sh` | Installs everything mise can't manage directly (apt packages, awscli, yadm, zimfw, bat-extras, bats-core + libs, bash-preexec, Docker) |

**Not tracked in this repo, created manually per machine:**
- `~/.zshrc_secrets` — API keys and tokens. Sourced automatically by `.zshrc##os.Linux` if present; a warning prints on shell start if it's missing. Keep this out of git.

---

## Remote server setup (primary workflow)

This is the full path from an empty VPS to a working Moshi + Claude Code environment.

### Step 1 — Provision the server

Any Ubuntu VPS works. Current setup: Contabo Cloud VPS 6 (6 vCPU, 12GB RAM, 200GB SSD), St. Louis / US-Central region — chosen for balanced latency across the continental US and to avoid the AT&T/Verizon band-compatibility issues that ruled out cheaper always-on hotspot alternatives.

### Step 2 — First login (password auth)

Moshi's Easy Pair setup needs an existing SSH session to bootstrap from — you can't Easy Pair into a server you've never logged into. Use any SSH client that supports plain password auth for this one-time step (e.g. Termius):

- **Host:** your server's IP
- **Port:** 22
- **Username:** root
- **Password:** set during provisioning

### Step 3 — Install moshi-hook

```bash
curl -fsSL https://getmoshi.app/install.sh | sh
