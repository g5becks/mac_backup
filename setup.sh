#!/usr/bin/env bash
# setup.sh — full reproducible setup for a fresh Ubuntu VPS.
# Moshi + mise + yadm dotfiles + Claude Code, ready for mobile development.
# Safe to re-run: every step checks before acting.

set -euo pipefail

log() { echo -e "\n==> $1"; }

# ── 1. yadm — via apt, must come before anything needing the repo ──────────
log "yadm"
apt update
apt install -y yadm

# ── 2. moshi-hook ────────────────────────────────────────────────────────
log "moshi-hook"
if ! command -v moshi-hook >/dev/null 2>&1; then
    curl -fsSL https://getmoshi.app/install.sh | sh
fi
export PATH="$HOME/.local/bin:$PATH"
grep -qxF 'export PATH="$HOME/.local/bin:$PATH"' ~/.bashrc || \
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc

# ── 3. mosh (required by moshi-hook) ────────────────────────────────────
log "mosh"
apt install -y mosh

# ── 4. mise ──────────────────────────────────────────────────────────────
log "mise"
if ! command -v mise >/dev/null 2>&1; then
    curl https://mise.run | sh
fi
grep -qxF 'eval "$(~/.local/bin/mise activate bash)"' ~/.bashrc || \
    echo 'eval "$(~/.local/bin/mise activate bash)"' >> ~/.bashrc
source ~/.bashrc

# ── Yazi plugins ──────────────────────────────────────────────────────────
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
    ya pkg add "$pkg"
done

# vscode-git-gutter and vscode-git-colors: ya pkg add fails on these two
# specifically (LICENSE copy error — a layout quirk in the source repo).
# Installed via direct clone instead, bypassing package.toml.
if [ ! -f ~/.config/yazi/plugins/vscode-git-gutter.yazi/main.lua ] || \
   [ ! -f ~/.config/yazi/plugins/vscode-git-colors.yazi/main.lua ]; then
    git clone --depth 1 https://github.com/ShikherVerma/yazi-plugins.git /tmp/yazi-plugins-src
    cp -r /tmp/yazi-plugins-src/vscode-git-gutter.yazi ~/.config/yazi/plugins/
    cp -r /tmp/yazi-plugins-src/vscode-git-colors.yazi ~/.config/yazi/plugins/
    rm -rf /tmp/yazi-plugins-src
fi

# ── 5. GitHub SSH key ────────────────────────────────────────────────────
log "GitHub SSH key"
if [ ! -f ~/.ssh/github ]; then
    ssh-keygen -t ed25519 -C 'techstar.dev@hotmail.com' -f ~/.ssh/github -N ""
fi
if ! ssh -T -i ~/.ssh/github -o StrictHostKeyChecking=accept-new git@github.com 2>&1 \
     | grep -q "successfully authenticated"; then
    echo "Add this key at GitHub -> Settings -> SSH and GPG keys -> New SSH key:"
    cat ~/.ssh/github.pub
    read -p "Press Enter once you've added it to GitHub... " _ < /dev/tty
fi

# ── 6. Clone dotfiles ────────────────────────────────────────────────────
log "dotfiles"
if [ ! -f ~/.zshrc##os.Linux ]; then
    GIT_SSH_COMMAND="ssh -i ~/.ssh/github" yadm clone git@github.com:g5becks/mac_backup.git
fi
cd ~
yadm alt

# ── 7. System packages ───────────────────────────────────────────────────
log "apt packages"
apt install -y build-essential git curl wget unzip imagemagick ffmpegthumbnailer libwebp-dev \
    libxml2-dev libfreetype6-dev pkgconf parallel p7zip-full \
    git-flow zsh zsh-autosuggestions \
    libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev \
    libffi-dev liblzma-dev libncurses-dev jq poppler-utils

# ── 8. awscli v2 ─────────────────────────────────────────────────────────
log "awscli"
if ! command -v aws >/dev/null 2>&1; then
    ARCH=$(uname -m)
    if [ "$ARCH" = "x86_64" ]; then
        AWS_URL="https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"
    elif [ "$ARCH" = "aarch64" ]; then
        AWS_URL="https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip"
    else
        echo "unsupported arch for awscli: $ARCH, skipping"
        AWS_URL=""
    fi
    if [ -n "$AWS_URL" ]; then
        curl -fsSL "$AWS_URL" -o /tmp/awscliv2.zip
        unzip -q /tmp/awscliv2.zip -d /tmp
        /tmp/aws/install
        rm -rf /tmp/awscliv2.zip /tmp/aws
    fi
fi

# ── 9. zimfw (needs zsh, installed above) ───────────────────────────────
log "zimfw"
if [ ! -d ~/.zim ]; then
    curl -fsSL https://raw.githubusercontent.com/zimfw/install/master/install.zsh | zsh
fi

# ── 10. bat-extras ───────────────────────────────────────────────────────
log "bat-extras"
if [ ! -f ~/.local/bin/batdiff ]; then
    git clone --depth 1 https://github.com/eth-p/bat-extras.git /tmp/bat-extras
    /tmp/bat-extras/build.sh --install --prefix="$HOME/.local" --no-manuals
    rm -rf /tmp/bat-extras
fi

# ── 11. bats-core + helper libraries ────────────────────────────────────
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

# ── 12. bash-preexec ─────────────────────────────────────────────────────
log "bash-preexec"
[ -f ~/.bash-preexec.sh ] || curl -fsSL -o ~/.bash-preexec.sh \
    https://raw.githubusercontent.com/rcaloras/bash-preexec/master/bash-preexec.sh
grep -qxF '[[ -f ~/.bash-preexec.sh ]] && source ~/.bash-preexec.sh' ~/.bashrc || \
    echo '[[ -f ~/.bash-preexec.sh ]] && source ~/.bash-preexec.sh' >> ~/.bashrc

# ── 13. Docker ────────────────────────────────────────────────────────────
log "docker"
if ! command -v docker >/dev/null 2>&1; then
    curl -fsSL https://get.docker.com | sh
fi

# ── 14. Claude Code (native installer, not mise-managed — npm distribution
#        is deprecated by Anthropic as of v2.1.15) ─────────────────────────
log "claude code"
if ! command -v claude >/dev/null 2>&1; then
    curl -fsSL https://claude.ai/install.sh | bash
fi

# ── 15. Default shell ────────────────────────────────────────────────────
log "default shell"
grep -qxF "$(which zsh)" /etc/shells || echo "$(which zsh)" >> /etc/shells
[ "$SHELL" = "$(which zsh)" ] || chsh -s "$(which zsh)"

# ── 16. mise-managed tools (neovim, herdr, gh, bun, everything in config.toml) ─
log "mise install"
mise install

# ── 17. Moshi agent hooks + persistent daemon ────────────────────────────
log "moshi-hook agent hooks + daemon"
if ! moshi-hook status 2>/dev/null | grep -q "status:.*paired"; then
    echo "Open Moshi -> Settings -> Agent Hooks -> copy your pairing token."
    read -p "Paste token here: " MOSHI_TOKEN < /dev/tty
    moshi-hook pair --token "$MOSHI_TOKEN"
fi
moshi-hook install --target claude
moshi-hook install --target opencode

# Persistent daemon via moshi-hook's own systemd --user integration —
# NOT a hand-rolled system-scope unit, that was a real mistake to avoid repeating.
moshi-hook service install

# The daemon's default PATH is minimal and can't see mise-managed tools
# (herdr specifically) without this override.
mkdir -p ~/.config/systemd/user/moshi-hook.service.d
cat > ~/.config/systemd/user/moshi-hook.service.d/override.conf << 'EOF'
[Service]
Environment="PATH=/root/.local/share/mise/shims:/usr/local/bin:/usr/bin:/bin"
EOF

systemctl --user daemon-reload
systemctl --user restart moshi-hook

# Without lingering, the --user service can stop when the SSH/Mosh session
# that started it fully disconnects — which happens constantly on mobile.
loginctl enable-linger root

# ── 18. Secrets file ─────────────────────────────────────────────────────
log "secrets"
if [ ! -f ~/.zshrc_secrets ]; then
    touch ~/.zshrc_secrets
    echo "Created empty ~/.zshrc_secrets — add your API keys/tokens here."
fi

echo ""
echo "=================================================================="
echo " Setup complete."
echo "=================================================================="
echo "Next steps (manual, on purpose):"
echo "  1. Run 'exec zsh' (or reconnect) to load the full shell environment."
echo "  2. Pair this server with Moshi on each device you want SSH access from:"
echo "       moshi-hook host setup"
echo "     Scan the printed QR code from the Moshi app. Repeat per device."
echo "  3. Verify everything: moshi-hook status"
echo "     Confirm: status=paired, Moshi Pro attached, daemon running,"
echo "     herdr shows a real path (not 'not found')."
echo "  4. Start a session with: herdr   (or: tmux)"
echo "=================================================================="
