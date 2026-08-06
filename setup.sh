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
    libffi-dev liblzma-dev libncurses-dev

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

# ── 14. Default shell ────────────────────────────────────────────────────
log "default shell"
grep -qxF "$(which zsh)" /etc/shells || echo "$(which zsh)" >> /etc/shells
[ "$SHELL" = "$(which zsh)" ] || chsh -s "$(which zsh)"

# ── 15. mise-managed tools (neovim, herdr, gh, bun, everything in config.toml) ─
log "mise install"
mise install

# ── 16. Secrets file ─────────────────────────────────────────────────────
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
echo "  2. Pair this server with Moshi on each device you want to use:"
echo "       moshi-hook host setup"
echo "     Scan the printed QR code from the Moshi app. Repeat per device."
echo "  3. Start a session with: herdr   (or: tmux)"
echo "=================================================================="
SETUPEOF
chmod +x ~/setup.sh
