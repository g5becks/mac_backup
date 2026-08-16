#!/usr/bin/env bash
# setup.sh — full reproducible setup for a fresh Ubuntu VPS.
# Moshi + mise + yadm dotfiles + Claude Code, ready for mobile development.
# Safe to re-run: every step checks before acting.

set -euo pipefail

log()  { echo -e "\n==> $1"; }
warn() { echo "!!  $1" >&2; }

# ── 0. Preflight ─────────────────────────────────────────────────────────
[ "$(id -u)" -eq 0 ] || { echo "Must run as root."; exit 1; }

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

# Secrets (GITHUB_TOKEN especially) must load BEFORE `mise install` — without
# it, unauthenticated GitHub API calls hit a 60/hour rate limit and every
# `github:` backend tool fails at once.
[ -f "$HOME/.zshrc_secrets" ] && . "$HOME/.zshrc_secrets"

# ── 1. yadm ──────────────────────────────────────────────────────────────
log "yadm"
apt-get update -qq
apt-get install -y -qq yadm

# ── 2. moshi-hook ────────────────────────────────────────────────────────
log "moshi-hook"
if ! command -v moshi-hook >/dev/null 2>&1; then
    curl -fsSL https://getmoshi.app/install.sh | sh
fi
export PATH="$HOME/.local/bin:$PATH"
grep -qxF 'export PATH="$HOME/.local/bin:$PATH"' ~/.bashrc || \
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc

# ── 3. mosh ──────────────────────────────────────────────────────────────
log "mosh"
apt-get install -y -qq mosh

# ── 4. mise ──────────────────────────────────────────────────────────────
log "mise"
if ! command -v mise >/dev/null 2>&1; then
    curl https://mise.run | sh
fi
grep -qxF 'eval "$(~/.local/bin/mise activate bash)"' ~/.bashrc || \
    echo 'eval "$(~/.local/bin/mise activate bash)"' >> ~/.bashrc
# Do NOT source ~/.bashrc or eval `mise activate bash`: both reference
# interactive-only vars ($PS1, $PROMPT_COMMAND) that are unset in a script,
# which under `set -u` kills the run silently. Shims give the same PATH access.
export PATH="$HOME/.local/share/mise/shims:$PATH"

# ── 5. GitHub SSH key ────────────────────────────────────────────────────
log "GitHub SSH key"
if [ ! -f ~/.ssh/github ]; then
    ssh-keygen -t ed25519 -C 'techstar.dev@hotmail.com' -f ~/.ssh/github -N ""
fi
# `ssh -T git@github.com` exits 1 even on SUCCESS (no shell access granted),
# so capture and inspect the output rather than testing the exit status.
SSH_TEST="$(ssh -T -i ~/.ssh/github -o StrictHostKeyChecking=accept-new \
            git@github.com 2>&1 || true)"
if ! printf '%s' "$SSH_TEST" | grep -q "successfully authenticated"; then
    echo "Add this key at GitHub -> Settings -> SSH and GPG keys -> New SSH key:"
    cat ~/.ssh/github.pub
    read -r -p "Press Enter once you've added it to GitHub... " _ < /dev/tty
fi

# ── 6. Clone dotfiles ────────────────────────────────────────────────────
log "dotfiles"
if [ ! -f "$HOME/.zshrc##os.Linux" ]; then
    GIT_SSH_COMMAND="ssh -i $HOME/.ssh/github" \
        yadm clone git@github.com:g5becks/mac_backup.git
fi
cd ~
yadm alt

# Dotfiles may have brought in a secrets file that did not exist at step 0.
[ -f "$HOME/.zshrc_secrets" ] && . "$HOME/.zshrc_secrets"

# ── 7. System packages — MUST precede step 8, which uses `git clone` ─────
log "apt packages"
apt-get install -y -qq build-essential git curl wget unzip imagemagick \
    ffmpegthumbnailer libwebp-dev libxml2-dev libfreetype6-dev pkgconf \
    parallel p7zip-full git-flow zsh zsh-autosuggestions \
    libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev \
    libffi-dev liblzma-dev libncurses-dev jq poppler-utils

# ── 8. Clone project repos ───────────────────────────────────────────────
log "project repos"
mkdir -p ~/Dev
for repo in \
    g5becks/oxlint-plugins \
    g5becks/dox \
    g5becks/errorset \
    g5becks/StrataDb \
    Takin-Profit/agentx
do
    name="${repo##*/}"
    if [ ! -d ~/Dev/"$name" ]; then
        GIT_SSH_COMMAND="ssh -i $HOME/.ssh/github" \
            git clone "git@github.com:${repo}.git" ~/Dev/"$name" || \
            warn "failed to clone ${repo}"
    fi
done
cd ~

# ── 9. awscli v2 ─────────────────────────────────────────────────────────
log "awscli"
if ! command -v aws >/dev/null 2>&1; then
    ARCH="$(uname -m)"
    case "$ARCH" in
        x86_64)  AWS_URL="https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" ;;
        aarch64) AWS_URL="https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" ;;
        *)       AWS_URL=""; warn "unsupported arch for awscli: $ARCH, skipping" ;;
    esac
    if [ -n "$AWS_URL" ]; then
        curl -fsSL "$AWS_URL" -o /tmp/awscliv2.zip
        unzip -q /tmp/awscliv2.zip -d /tmp
        /tmp/aws/install
        rm -rf /tmp/awscliv2.zip /tmp/aws
    fi
fi

# ── 10. zimfw ────────────────────────────────────────────────────────────
log "zimfw"
if [ ! -d ~/.zim ]; then
    curl -fsSL https://raw.githubusercontent.com/zimfw/install/master/install.zsh | zsh
fi

# ── 11. bat-extras ───────────────────────────────────────────────────────
log "bat-extras"
if [ ! -f ~/.local/bin/batdiff ]; then
    rm -rf /tmp/bat-extras
    git clone --depth 1 https://github.com/eth-p/bat-extras.git /tmp/bat-extras
    /tmp/bat-extras/build.sh --install --prefix="$HOME/.local" --no-manuals
    rm -rf /tmp/bat-extras
fi

# ── 12. bats-core + helper libraries ─────────────────────────────────────
log "bats-core"
if ! command -v bats >/dev/null 2>&1; then
    rm -rf /tmp/bats-core
    git clone --depth 1 https://github.com/bats-core/bats-core.git /tmp/bats-core
    /tmp/bats-core/install.sh /usr/local
    rm -rf /tmp/bats-core
fi
mkdir -p ~/.local/share/bats-libs
[ -d ~/.local/share/bats-libs/bats-assert ]  || git clone --depth 1 https://github.com/bats-core/bats-assert.git  ~/.local/share/bats-libs/bats-assert
[ -d ~/.local/share/bats-libs/bats-support ] || git clone --depth 1 https://github.com/bats-core/bats-support.git ~/.local/share/bats-libs/bats-support
[ -d ~/.local/share/bats-libs/bats-file ]    || git clone --depth 1 https://github.com/bats-core/bats-file.git    ~/.local/share/bats-libs/bats-file

# ── 13. bash-preexec ─────────────────────────────────────────────────────
log "bash-preexec"
[ -f ~/.bash-preexec.sh ] || curl -fsSL -o ~/.bash-preexec.sh \
    https://raw.githubusercontent.com/rcaloras/bash-preexec/master/bash-preexec.sh
grep -qxF '[[ -f ~/.bash-preexec.sh ]] && source ~/.bash-preexec.sh' ~/.bashrc || \
    echo '[[ -f ~/.bash-preexec.sh ]] && source ~/.bash-preexec.sh' >> ~/.bashrc

# ── 14. Docker ───────────────────────────────────────────────────────────
log "docker"
# get.docker.com runs its own `set -e` and exits non-zero when it detects an
# existing install — which under our `set -e` would kill the whole script.
if ! command -v docker >/dev/null 2>&1; then
    curl -fsSL https://get.docker.com | sh || warn "docker install returned non-zero"
fi

# ── 15. Claude Code (native installer — the npm distribution is deprecated
#        by Anthropic as of v2.1.15) ──────────────────────────────────────
log "claude code"
if ! command -v claude >/dev/null 2>&1; then
    curl -fsSL https://claude.ai/install.sh | bash || warn "claude install returned non-zero"
fi

# ── 16. Default shell + login-shell EDITOR ───────────────────────────────
log "default shell"
ZSH_PATH="$(command -v zsh)"
grep -qxF "$ZSH_PATH" /etc/shells || echo "$ZSH_PATH" >> /etc/shells
# Compare against /etc/passwd — $SHELL is inherited from session start and
# goes stale immediately after chsh.
CURRENT_SHELL="$(getent passwd "$(id -un)" | cut -d: -f7)"
[ "$CURRENT_SHELL" = "$ZSH_PATH" ] || chsh -s "$ZSH_PATH"

# herdr-file-viewer's `e` key reads $EDITOR from the HERDR SERVER's
# environment, not your interactive shell. Under mosh the server never
# sources .zshrc, so `e` silently does nothing. ~/.profile is the
# login-shell path mosh actually reads.
grep -qxF 'export EDITOR=hx' ~/.profile 2>/dev/null || \
    echo 'export EDITOR=hx' >> ~/.profile

# ── 17. mise-managed tools ───────────────────────────────────────────────
log "mise install"
if [ -z "${GITHUB_TOKEN:-}" ]; then
    warn "GITHUB_TOKEN unset — github: backend tools may hit the 60/hour"
    warn "unauthenticated rate limit. Add it to ~/.zshrc_secrets and re-run."
fi
mise install

# ── 18. Yazi plugins — MUST follow `mise install`; `ya` ships with yazi ──
log "yazi plugins"
cd ~
mkdir -p ~/.config/yazi/plugins
for pkg in \
    yazi-rs/plugins:git \
    yazi-rs/plugins:vcs-files \
    yazi-rs/plugins:full-border \
    yazi-rs/plugins:toggle-pane \
    yazi-rs/plugins:smart-enter \
    yazi-rs/plugins:jump-to-char \
    yazi-rs/plugins:smart-filter \
    yazi-rs/plugins:piper \
    yazi-rs/plugins:chmod \
    yazi-rs/plugins:smart-paste \
    ciarandg/cd-git-root \
    qwjyh/relative-path \
    barbanevosa/linemode-plus
do
    # "already exists in package.toml" exits non-zero on a re-run, which
    # under `set -e` silently terminated the entire script.
    ya pkg add "$pkg" || true
done

# vscode-git-gutter / vscode-git-colors: `ya pkg add` fails on these two
# (LICENSE copy error — a layout quirk in the source repo), so they are
# cloned directly and live outside package.toml. `ya pkg upgrade` will never
# update them; re-run this block manually to refresh.
if [ ! -f ~/.config/yazi/plugins/vscode-git-gutter.yazi/main.lua ] || \
   [ ! -f ~/.config/yazi/plugins/vscode-git-colors.yazi/main.lua ]; then
    rm -rf /tmp/yazi-plugins-src
    git clone --depth 1 https://github.com/ShikherVerma/yazi-plugins.git /tmp/yazi-plugins-src
    cp -r /tmp/yazi-plugins-src/vscode-git-gutter.yazi ~/.config/yazi/plugins/
    cp -r /tmp/yazi-plugins-src/vscode-git-colors.yazi ~/.config/yazi/plugins/
    rm -rf /tmp/yazi-plugins-src
fi

# ── 19. Moshi agent hooks + persistent daemon ────────────────────────────
log "moshi-hook agent hooks + daemon"
HOOK_STATUS="$(moshi-hook status 2>/dev/null || true)"
if ! printf '%s' "$HOOK_STATUS" | grep -q "paired"; then
    echo "Open Moshi -> Settings -> Agent Hooks -> copy your pairing token."
    read -r -p "Paste token here: " MOSHI_TOKEN < /dev/tty
    moshi-hook pair --token "$MOSHI_TOKEN"
fi
# These exit non-zero when already configured — same silent-death pattern.
moshi-hook install --target claude   || true
moshi-hook install --target opencode || true

# Persistent daemon via moshi-hook's own systemd --user integration — NOT a
# hand-rolled system-scope unit, which was a real mistake worth not repeating.
moshi-hook service install || true

# The daemon starts with a minimal PATH and cannot see mise-managed tools
# (herdr specifically) without this override.
mkdir -p "$HOME/.config/systemd/user/moshi-hook.service.d"
cat > "$HOME/.config/systemd/user/moshi-hook.service.d/override.conf" <<EOF
[Service]
Environment="PATH=${HOME}/.local/share/mise/shims:${HOME}/.local/bin:/usr/local/bin:/usr/bin:/bin"
EOF

systemctl --user daemon-reload      || warn "systemctl --user unavailable; run daemon-reload manually"
systemctl --user restart moshi-hook || warn "could not restart moshi-hook; check 'systemctl --user status moshi-hook'"

# Without lingering, the --user service stops when the SSH/Mosh session that
# started it fully disconnects — which happens constantly on mobile.
loginctl enable-linger "$(id -un)" || true

# ── 20. Herdr plugins + project workspaces ───────────────────────────────
log "herdr plugins"
# --yes is required: plugin install shows an interactive trust preview by
# default, which would hang a non-interactive script indefinitely.
herdr plugin install cloudmanic/herdr-plus --yes      || true
herdr plugin install smarzban/herdr-file-viewer --yes || true
herdr plugin install persiyanov/herdr-reviewr --yes   || true

# Herdr integrations write into each agent's own config directory and fail
# when it does not exist yet — likely on a fresh box where neither agent has
# been run even once.
mkdir -p ~/.claude ~/.config/opencode
herdr integration install claude   || true
herdr integration install opencode || true

# Hardcoded rather than resolved via `herdr plugin config-dir`: that command
# falls back to a DIFFERENT path (~/.config/herdr-plus/) when no herdr server
# is running — exactly this script's state. Path confirmed identical across
# the plugin's README and its docs site.
HERDR_PLUS_DIR="$HOME/.config/herdr/plugins/config/cloudmanic.herdr-plus"
mkdir -p "$HERDR_PLUS_DIR/projects"

for name in oxlint-plugins dox errorset StrataDb agentx; do
    cat > "$HERDR_PLUS_DIR/projects/${name}.toml" <<EOF
name = "${name}"
working_dir = "~/Dev/${name}"

[[tabs]]
name = "editor"
command = "hx ."

[[tabs]]
name = "shell"

[[tabs]]
name = "claude"
command = "claude"

[[tabs]]
name = "opencode"
command = "opencode"

[[tabs]]
name = "yazi"
command = "yazi"

[[tabs]]
name = "lazygit"
command = "lazygit"
EOF
done

mkdir -p ~/.config/herdr
if [ ! -f ~/.config/herdr/config.toml ] || \
   ! grep -q "cloudmanic.herdr-plus.projects" ~/.config/herdr/config.toml; then
    cat >> ~/.config/herdr/config.toml <<'EOF'

[[keys.command]]
key = "prefix+up"
type = "plugin_action"
command = "cloudmanic.herdr-plus.projects"
description = "herdr-plus: projects"

[[keys.command]]
key = "prefix+f"
type = "shell"
command = "herdr plugin action invoke open-file-viewer --plugin herdr-file-viewer"
description = "file viewer (split)"

# NOTE: verify this action id after install with
#   herdr plugin action list --plugin persiyanov.reviewr
# The plugin's README names the action only in prose ("reviewr: toggle
# sidebar"), so this id is inferred from its documented plugin id.
[[keys.command]]
key = "prefix+r"
type = "plugin_action"
command = "persiyanov.reviewr.toggle-sidebar"
description = "reviewr: toggle sidebar"
EOF
fi

# ── 21. Secrets file ─────────────────────────────────────────────────────
log "secrets"
if [ ! -f ~/.zshrc_secrets ]; then
    touch ~/.zshrc_secrets
    echo "Created empty ~/.zshrc_secrets — add your API keys/tokens here."
    echo "GITHUB_TOKEN belongs here; mise needs it to avoid GitHub rate limits."
fi

# ── 22. Verify ───────────────────────────────────────────────────────────
log "verification"
# Ensure both install locations are visible regardless of what each
# installer did to PATH in this session.
export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"

MISSING=0
for cmd in yadm mosh mise git zsh docker claude aws bats yazi ya hx herdr gh opencode bun; do
    if command -v "$cmd" >/dev/null 2>&1; then
        printf '  ok      %s\n' "$cmd"
    else
        printf '  MISSING %s\n' "$cmd"
        MISSING=$((MISSING + 1))
    fi
done

for name in oxlint-plugins dox errorset StrataDb agentx; do
    if [ -d ~/Dev/"$name" ]; then
        printf '  ok      ~/Dev/%s\n' "$name"
    else
        printf '  MISSING ~/Dev/%s\n' "$name"
        MISSING=$((MISSING + 1))
    fi
done

if [ -f "$HERDR_PLUS_DIR/projects/oxlint-plugins.toml" ]; then
    printf '  ok      herdr-plus project templates\n'
else
    printf '  MISSING herdr-plus project templates\n'
    MISSING=$((MISSING + 1))
fi

HERDR_PLUGINS="$(herdr plugin list 2>/dev/null || true)"
for plug in herdr-plus file-viewer reviewr; do
    if printf '%s' "$HERDR_PLUGINS" | grep -q "$plug"; then
        printf '  ok      herdr plugin: %s\n' "$plug"
    else
        printf '  MISSING herdr plugin: %s\n' "$plug"
        MISSING=$((MISSING + 1))
    fi
done

echo ""
echo "=================================================================="
if [ "$MISSING" -eq 0 ]; then
    echo " Setup complete — all tools, repos, templates, and plugins present."
else
    echo " Setup finished with $MISSING missing item(s) — see list above."
fi
echo "=================================================================="
echo "Next steps (manual, on purpose):"
echo "  1. Run 'exec zsh' (or reconnect) to load the full shell environment."
echo "  2. Pair this server with Moshi on each device you want SSH access from:"
echo "       moshi-hook host setup"
echo "     Scan the printed QR code from the Moshi app. Repeat per device."
echo "  3. Verify: moshi-hook status"
echo "     Confirm status=paired, Moshi Pro attached, daemon running,"
echo "     and herdr shows a real path (not 'not found')."
echo "  4. Start a session with: herdr"
echo "  5. Keybindings inside herdr (prefix = ctrl+b):"
echo "       prefix+up  project picker (herdr-plus)"
echo "       prefix+f   file viewer split"
echo "       prefix+r   reviewr sidebar"
echo "  6. Confirm the reviewr action id — the keybinding in config.toml is"
echo "     inferred, not documented:"
echo "       herdr plugin action list --plugin persiyanov.reviewr"
echo "=================================================================="