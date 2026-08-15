#!/usr/bin/env bash
# setup.sh — full reproducible setup for a fresh Ubuntu VPS.
# Moshi + mise + yadm dotfiles + Claude Code, ready for mobile development.
# Safe to re-run: every step checks before acting.

set -euo pipefail

log()  { echo -e "\n==> $1"; }
warn() { echo "!!  $1" >&2; }

# ── 0. Preflight ─────────────────────────────────────────────────────────
[ "$(id -u)" -eq 0 ] || { echo "Must run as root."; exit 1; }

# apt-get is the stable scripting interface; these vars stop needrestart
# and debconf from blocking on interactive prompts mid-run.
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

# ── 1. yadm — via apt, must come before anything needing the repo ─────────
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

# ── 3. mosh (required by moshi-hook) ─────────────────────────────────────
log "mosh"
apt-get install -y -qq mosh

# ── 4. mise ──────────────────────────────────────────────────────────────
log "mise"
if ! command -v mise >/dev/null 2>&1; then
    curl https://mise.run | sh
fi
grep -qxF 'eval "$(~/.local/bin/mise activate bash)"' ~/.bashrc || \
    echo 'eval "$(~/.local/bin/mise activate bash)"' >> ~/.bashrc
# Do NOT source ~/.bashrc or eval `mise activate bash` here: both reference
# interactive-only vars ($PS1, $PROMPT_COMMAND) that are unset in a script,
# which under `set -u` kills the run silently. Shims give us the same PATH
# access with no shell hooks.
export PATH="$HOME/.local/share/mise/shims:$PATH"

# ── 5. GitHub SSH key ────────────────────────────────────────────────────
log "GitHub SSH key"
if [ ! -f ~/.ssh/github ]; then
    ssh-keygen -t ed25519 -C 'techstar.dev@hotmail.com' -f ~/.ssh/github -N ""
fi
# `ssh -T git@github.com` exits 1 even on SUCCESS (no shell access granted),
# so the result must be captured and inspected, not used as a pipeline status.
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

# ── 7. System packages ───────────────────────────────────────────────────
log "apt packages"
apt-get install -y -qq build-essential git curl wget unzip imagemagick \
    ffmpegthumbnailer libwebp-dev libxml2-dev libfreetype6-dev pkgconf \
    parallel p7zip-full git-flow zsh zsh-autosuggestions \
    libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev \
    libffi-dev liblzma-dev libncurses-dev jq poppler-utils

# ── 8. awscli v2 ─────────────────────────────────────────────────────────
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

# ── 9. zimfw (needs zsh, installed above) ────────────────────────────────
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

# ── 11. bats-core + helper libraries ─────────────────────────────────────
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

# ── 13. Docker ───────────────────────────────────────────────────────────
log "docker"
if ! command -v docker >/dev/null 2>&1; then
    curl -fsSL https://get.docker.com | sh
fi

# ── 14. Claude Code (native installer, not mise-managed — the npm
#        distribution is deprecated by Anthropic as of v2.1.15) ───────────
log "claude code"
if ! command -v claude >/dev/null 2>&1; then
    curl -fsSL https://claude.ai/install.sh | bash
fi

# ── 15. Default shell ────────────────────────────────────────────────────
log "default shell"
ZSH_PATH="$(command -v zsh)"
grep -qxF "$ZSH_PATH" /etc/shells || echo "$ZSH_PATH" >> /etc/shells
# Compare against the shell actually registered in /etc/passwd — $SHELL is
# inherited from session start and goes stale immediately after chsh.
CURRENT_SHELL="$(getent passwd "$(id -un)" | cut -d: -f7)"
[ "$CURRENT_SHELL" = "$ZSH_PATH" ] || chsh -s "$ZSH_PATH"

# ── 16. mise-managed tools (yazi, helix, herdr, gh, opencode, bun, …) ────
log "mise install"
mise install

# ── 17. Yazi plugins — MUST run after `mise install`, since `ya` ships
#        with yazi and does not exist before that step ────────────────────
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
    # "already exists in package.toml" exits non-zero on a re-run, which
    # under `set -e` silently terminated the entire script.
    ya pkg add "$pkg" || true
done

# vscode-git-gutter / vscode-git-colors: `ya pkg add` fails on these two
# specifically (LICENSE copy error — a layout quirk in the source repo),
# so they are cloned directly and live outside package.toml. This means
# `ya pkg upgrade` will never update them; re-run this block manually.
if [ ! -f ~/.config/yazi/plugins/vscode-git-gutter.yazi/main.lua ] || \
   [ ! -f ~/.config/yazi/plugins/vscode-git-colors.yazi/main.lua ]; then
    rm -rf /tmp/yazi-plugins-src
    git clone --depth 1 https://github.com/ShikherVerma/yazi-plugins.git /tmp/yazi-plugins-src
    cp -r /tmp/yazi-plugins-src/vscode-git-gutter.yazi ~/.config/yazi/plugins/
    cp -r /tmp/yazi-plugins-src/vscode-git-colors.yazi ~/.config/yazi/plugins/
    rm -rf /tmp/yazi-plugins-src
fi

# ── 18. Moshi agent hooks + persistent daemon ────────────────────────────
log "moshi-hook agent hooks + daemon"
if ! moshi-hook status 2>/dev/null | grep -q "status:.*paired"; then
    echo "Open Moshi -> Settings -> Agent Hooks -> copy your pairing token."
    read -r -p "Paste token here: " MOSHI_TOKEN < /dev/tty
    moshi-hook pair --token "$MOSHI_TOKEN"
fi
# These exit non-zero when already configured — same silent-death pattern.
moshi-hook install --target claude   || true
moshi-hook install --target opencode || true

# Persistent daemon via moshi-hook's own systemd --user integration —
# NOT a hand-rolled system-scope unit, which was a real mistake to repeat.
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

# ── 19. Secrets file ─────────────────────────────────────────────────────
log "secrets"
if [ ! -f ~/.zshrc_secrets ]; then
    touch ~/.zshrc_secrets
    echo "Created empty ~/.zshrc_secrets — add your API keys/tokens here."
fi

# ── 20. Verify ───────────────────────────────────────────────────────────
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

echo ""
echo "=================================================================="
if [ "$MISSING" -eq 0 ]; then
    echo " Setup complete — all tools present."
else
    echo " Setup finished with $MISSING missing tool(s) — see list above."
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
echo "=================================================================="