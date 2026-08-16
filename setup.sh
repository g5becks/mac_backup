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
export PATH="$HOME/.local/share/mise/shims:$PATH"

# ── 5. GitHub SSH key ────────────────────────────────────────────────────
log "GitHub SSH key"
if [ ! -f ~/.ssh/github ]; then
    ssh-keygen -t ed25519 -C 'techstar.dev@hotmail.com' -f ~/.ssh/github -N ""
fi
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

# ── 7. System packages — MUST run before step 8, which uses `git clone` ──
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
            git clone "git@github.com:${repo}.git" ~/Dev/"$name"
    fi
done

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
    git clone --depth 1 https://github.com/eth-p/bat-extras.git /tmp/bat-extras
    /tmp/bat-extras/build.sh --install --prefix="$HOME/.local" --no-manuals
    rm -rf /tmp/bat-extras
fi

# ── 12. bats-core + helper libraries ─────────────────────────────────────
log "bats-core"
if ! command -v bats >/dev/null 2>&1; then
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
if ! command -v docker >/dev/null 2>&1; then
    curl -fsSL https://get.docker.com | sh
fi

# ── 15. Claude Code (native installer) ───────────────────────────────────
log "claude code"
if ! command -v claude >/dev/null 2>&1; then
    curl -fsSL https://claude.ai/install.sh | bash
fi

# ── 16. Default shell ────────────────────────────────────────────────────
log "default shell"
ZSH_PATH="$(command -v zsh)"
grep -qxF "$ZSH_PATH" /etc/shells || echo "$ZSH_PATH" >> /etc/shells
CURRENT_SHELL="$(getent passwd "$(id -un)" | cut -d: -f7)"
[ "$CURRENT_SHELL" = "$ZSH_PATH" ] || chsh -s "$ZSH_PATH"

# ── 17. mise-managed tools ───────────────────────────────────────────────
log "mise install"
mise install

# ── 18. Yazi plugins ──────────────────────────────────────────────────────
log "yazi plugins"
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
    ya pkg add "$pkg" || true
done

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
moshi-hook install --target claude   || true
moshi-hook install --target opencode || true
moshi-hook service install || true

mkdir -p "$HOME/.config/systemd/user/moshi-hook.service.d"
cat > "$HOME/.config/systemd/user/moshi-hook.service.d/override.conf" <<EOF
[Service]
Environment="PATH=${HOME}/.local/share/mise/shims:${HOME}/.local/bin:/usr/local/bin:/usr/bin:/bin"
EOF

systemctl --user daemon-reload      || warn "systemctl --user unavailable; run daemon-reload manually"
systemctl --user restart moshi-hook || warn "could not restart moshi-hook; check 'systemctl --user status moshi-hook'"
loginctl enable-linger "$(id -un)" || true

# ── 20. herdr-plus plugin + project workspaces ───────────────────────────
log "herdr-plus"
herdr plugin install cloudmanic/herdr-plus --yes || true
herdr integration install claude   || true
herdr integration install opencode || true

# Hardcoded, not resolved via `herdr plugin config-dir`: that command
# resolves differently depending on whether a herdr server is already
# running, and falls back to a DIFFERENT path (~/.config/herdr-plus/) when
# run standalone — exactly the state this script runs in. This exact path
# is confirmed identical across the plugin's own README and docs site.
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
EOF
fi

# ── 21. Secrets file ─────────────────────────────────────────────────────
log "secrets"
if [ ! -f ~/.zshrc_secrets ]; then
    touch ~/.zshrc_secrets
    echo "Created empty ~/.zshrc_secrets — add your API keys/tokens here."
fi

# ── 22. Verify ───────────────────────────────────────────────────────────
log "verification"
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

if [ -f "$HOME/.config/herdr/plugins/config/cloudmanic.herdr-plus/projects/oxlint-plugins.toml" ]; then
    printf '  ok      herdr-plus project templates\n'
else
    printf '  MISSING herdr-plus project templates\n'
    MISSING=$((MISSING + 1))
fi

echo ""
echo "=================================================================="
if [ "$MISSING" -eq 0 ]; then
    echo " Setup complete — all tools, repos, and templates present."
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
echo "  5. Press prefix+up in Herdr to open the project picker (herdr-plus)."
echo "=================================================================="