#!/usr/bin/env bash
# setup.sh — full reproducible setup for a fresh Ubuntu VPS.
# Moshi + mise + yadm dotfiles + Claude Code, ready for mobile development.
# Safe to re-run: every step checks before acting.

set -euo pipefail

log()  { echo -e "\n==> $1"; }
warn() { echo "!!  $1" >&2; }

# Case-insensitive lookup of a project folder under ~/Dev.
# Prints the real path, or nothing if there is no match.
find_project_dir() {
    find "$HOME/Dev" -maxdepth 1 -mindepth 1 -type d -iname "$1" -print -quit 2>/dev/null
}

# ── 0. Preflight ─────────────────────────────────────────────────────────
[ "$(id -u)" -eq 0 ] || { echo "Must run as root."; exit 1; }

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

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
[ -f "$HOME/.zshrc_secrets" ] && . "$HOME/.zshrc_secrets"

# ── 7. System packages — MUST precede step 8, which uses `git clone` ─────
log "apt packages"
apt-get install -y -qq build-essential git curl wget unzip imagemagick \
    ffmpegthumbnailer libwebp-dev libxml2-dev libfreetype6-dev pkgconf \
    parallel p7zip-full git-flow zsh zsh-autosuggestions \
    libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev \
    libffi-dev liblzma-dev libncurses-dev jq poppler-utils

# ── 8. Clone project repos ───────────────────────────────────────────────
# Skips any repo whose folder already exists, matched case-insensitively,
# so a hand-created ~/Dev/loadveto is never cloned over a second time.
log "project repos"
mkdir -p ~/Dev
for repo in \
    g5becks/oxlint-plugins \
    g5becks/dox \
    g5becks/errorset \
    g5becks/StrataDb \
    Takin-Profit/agentx \
    Takin-Profit/LoadVeto
do
    name="${repo##*/}"
    if [ -z "$(find_project_dir "$name")" ]; then
        GIT_SSH_COMMAND="ssh -i $HOME/.ssh/github" \
            git clone "git@github.com:${repo}.git" ~/Dev/"$name" || \
            warn "failed to clone ${repo}"
    fi
done
cd ~

# ── 8b. Fix deprecated mise config keys — MUST precede trust in step 8c ──
log "fix deprecated mise config keys"
shopt -s nullglob
for f in ~/Dev/*/mise.toml ~/Dev/*/.mise.toml; do
    if grep -q 'experimental_monorepo_root' "$f"; then
        sed -i 's/experimental_monorepo_root/monorepo_root/' "$f"
    fi
done
shopt -u nullglob

# ── 8c. Trust project mise configs — MUST follow step 8b ─────────────────
log "trust project mise configs"
shopt -s nullglob
for f in ~/Dev/*/mise.toml ~/Dev/*/.mise.toml; do
    mise trust "$f" || warn "could not trust $f"
done
shopt -u nullglob

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
if ! command -v docker >/dev/null 2>&1; then
    curl -fsSL https://get.docker.com | sh || warn "docker install returned non-zero"
fi

# ── 15. Claude Code (native installer) ────────────────────────────────────
log "claude code"
if ! command -v claude >/dev/null 2>&1; then
    curl -fsSL https://claude.ai/install.sh | bash || warn "claude install returned non-zero"
fi

# ── 16. Default shell + login-shell EDITOR ───────────────────────────────
log "default shell"
ZSH_PATH="$(command -v zsh)"
grep -qxF "$ZSH_PATH" /etc/shells || echo "$ZSH_PATH" >> /etc/shells
CURRENT_SHELL="$(getent passwd "$(id -un)" | cut -d: -f7)"
[ "$CURRENT_SHELL" = "$ZSH_PATH" ] || chsh -s "$ZSH_PATH"
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

# ── 20. Herdr plugins + project workspaces ───────────────────────────────
log "herdr plugins"
herdr plugin install cloudmanic/herdr-plus --yes      </dev/null || true
herdr plugin install smarzban/herdr-file-viewer --yes </dev/null || true
herdr plugin install persiyanov/herdr-reviewr --yes   </dev/null || true

mkdir -p ~/.claude ~/.config/opencode
herdr integration install claude   </dev/null || true
herdr integration install opencode </dev/null || true

HERDR_PLUS_DIR="$HOME/.config/herdr/plugins/config/cloudmanic.herdr-plus"
mkdir -p "$HERDR_PLUS_DIR/projects"

for name in oxlint-plugins dox errorset StrataDb agentx LoadVeto; do
    # working_dir uses the folder's real on-disk name, so a lowercase
    # hand-made ~/Dev/loadveto and a cloned ~/Dev/LoadVeto both work.
    dir="$(find_project_dir "$name" || true)"
    dirname="$(basename "${dir:-$HOME/Dev/$name}")"
    cat > "$HERDR_PLUS_DIR/projects/${name}.toml" <<EOF
name = "${name}"
working_dir = "~/Dev/${dirname}"

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

# An earlier hand-made lowercase template would show up as a second,
# duplicate "loadveto" entry in the picker. Remove it once the real one exists.
if [ -f "$HERDR_PLUS_DIR/projects/LoadVeto.toml" ] && \
   [ -f "$HERDR_PLUS_DIR/projects/loadveto.toml" ]; then
    rm -f "$HERDR_PLUS_DIR/projects/loadveto.toml"
fi

# ── 21. Secrets file ─────────────────────────────────────────────────────
log "secrets"
if [ ! -f ~/.zshrc_secrets ]; then
    touch ~/.zshrc_secrets
    echo "Created empty ~/.zshrc_secrets — add your API keys/tokens here."
    echo "GITHUB_TOKEN belongs here; mise needs it to avoid GitHub rate limits."
fi

# ── 22. cloudflared ───────────────────────────────────────────────────────
log "cloudflared"
if ! command -v cloudflared >/dev/null 2>&1; then
    mkdir -p --mode=0755 /usr/share/keyrings
    curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg \
        -o /usr/share/keyrings/cloudflare-main.gpg
    echo 'deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared any main' \
        > /etc/apt/sources.list.d/cloudflared.list
    apt-get update -qq
    apt-get install -y -qq cloudflared
fi

# ── 23. Cloudflare Tunnel — persistent dev-preview hostname ──────────────
# Domain confirmed on Cloudflare's nameservers (070717.uk, DNS Setup: Full).
# The existing root A/AAAA/MX/TXT records are untouched — this only adds a
# new CNAME for the subdomain below via `tunnel route dns`.
TUNNEL_NAME="agentx-dev"
TUNNEL_DOMAIN="agentx.070717.uk"
TUNNEL_PORT="5173"     # Vite client dev server

log "cloudflared login"
if [ ! -f ~/.cloudflared/cert.pem ]; then
    cloudflared tunnel login
    echo "If a URL didn't open automatically above, copy it and open it"
    echo "in any browser (your phone is fine), then authorize 070717.uk."
    read -r -p "Press Enter once authorized... " _ < /dev/tty
fi

log "cloudflared tunnel create"
if ! cloudflared tunnel list -o json 2>/dev/null | jq -e --arg n "$TUNNEL_NAME" \
    'any(.[]; .name == $n)' >/dev/null; then
    cloudflared tunnel create "$TUNNEL_NAME"
fi
TUNNEL_UUID="$(cloudflared tunnel list -o json | jq -r --arg n "$TUNNEL_NAME" \
    '.[] | select(.name == $n) | .id')"

# Created once, never overwritten — same principle as herdr's config.toml.
mkdir -p /etc/cloudflared
if [ ! -f /etc/cloudflared/config.yml ]; then
    cat > /etc/cloudflared/config.yml <<EOF
tunnel: ${TUNNEL_UUID}
credentials-file: /root/.cloudflared/${TUNNEL_UUID}.json

ingress:
  - hostname: ${TUNNEL_DOMAIN}
    service: http://localhost:${TUNNEL_PORT}
  - service: http_status:404
EOF
fi

log "cloudflared route dns"
cloudflared tunnel route dns "$TUNNEL_NAME" "$TUNNEL_DOMAIN" || \
    warn "route dns failed or already exists — check manually if the hostname doesn't resolve"

log "cloudflared service install"
if ! systemctl is-enabled cloudflared >/dev/null 2>&1; then
    cloudflared service install
fi
systemctl restart cloudflared || warn "could not restart cloudflared; check systemctl status cloudflared"

# ── 24. Verify ───────────────────────────────────────────────────────────
log "verification"
export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"

MISSING=0
for cmd in yadm mosh mise git zsh docker claude aws bats yazi ya hx herdr gh opencode bun cloudflared; do
    if command -v "$cmd" >/dev/null 2>&1; then
        printf '  ok      %s\n' "$cmd"
    else
        printf '  MISSING %s\n' "$cmd"
        MISSING=$((MISSING + 1))
    fi
done

for name in oxlint-plugins dox errorset StrataDb agentx LoadVeto; do
    found="$(find_project_dir "$name" || true)"
    if [ -n "$found" ]; then
        printf '  ok      %s\n' "$found"
    else
        printf '  MISSING ~/Dev/%s\n' "$name"
        MISSING=$((MISSING + 1))
    fi
done

UNTRUSTED=0
shopt -s nullglob
for f in ~/Dev/*/mise.toml ~/Dev/*/.mise.toml; do
    if mise trust --show "$f" >/dev/null 2>&1; then
        printf '  ok      trusted %s\n' "$f"
    else
        printf '  UNTRUSTED %s — run: mise trust %s\n' "$f" "$f"
        UNTRUSTED=$((UNTRUSTED + 1))
    fi
done
shopt -u nullglob
MISSING=$((MISSING + UNTRUSTED))

if [ -f "$HERDR_PLUS_DIR/projects/oxlint-plugins.toml" ]; then
    printf '  ok      herdr-plus project templates\n'
else
    printf '  MISSING herdr-plus project templates\n'
    MISSING=$((MISSING + 1))
fi

if [ -f "$HERDR_PLUS_DIR/projects/LoadVeto.toml" ]; then
    printf '  ok      herdr-plus LoadVeto template\n'
else
    printf '  MISSING herdr-plus LoadVeto template\n'
    MISSING=$((MISSING + 1))
fi

for plug in cloudmanic.herdr-plus herdr-file-viewer persiyanov.reviewr; do
    if [ -d "$HOME/.config/herdr/plugins/config/$plug" ]; then
        printf '  ok      herdr plugin: %s\n' "$plug"
    else
        printf '  MISSING herdr plugin: %s\n' "$plug"
        MISSING=$((MISSING + 1))
    fi
done

if grep -q "cloudmanic.herdr-plus.projects" ~/.config/herdr/config.toml 2>/dev/null; then
    printf '  ok      herdr keybindings (from dotfiles)\n'
else
    printf '  MISSING herdr keybindings — check config.toml in the dotfiles repo\n'
    MISSING=$((MISSING + 1))
fi

if [ -f /etc/cloudflared/config.yml ]; then
    printf '  ok      cloudflared tunnel config\n'
else
    printf '  MISSING cloudflared tunnel config\n'
    MISSING=$((MISSING + 1))
fi

if systemctl is-active cloudflared >/dev/null 2>&1; then
    printf '  ok      cloudflared service active\n'
else
    printf '  MISSING cloudflared service not active — check systemctl status cloudflared\n'
    MISSING=$((MISSING + 1))
fi

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
echo "  4. Start a session with: herdr"
echo "  5. Keybindings inside herdr:"
echo "       prefix+up  project picker (herdr-plus)"
echo "       prefix+f   file viewer"
echo "       prefix+r   reviewr sidebar"
echo "  6. Once the Vite dev server is running, https://agentx.070717.uk"
echo "     previews it permanently — same URL every time, survives reboots."
echo "=================================================================="
