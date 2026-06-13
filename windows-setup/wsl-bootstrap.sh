#!/usr/bin/env bash
# WSL bootstrap — run once on a fresh WSL install before restoring yadm backup
# Usage: bash wsl-bootstrap.sh

set -e

echo ">>> Updating apt and installing system packages..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y \
  git curl wget zsh \
  imagemagick ffmpegthumbnailer webp \
  libxml2-dev libfreetype6-dev pkgconf \
  parallel p7zip-full xclip \
  git-flow \
  zsh-autosuggestions zsh-completions \
  build-essential

echo ">>> Installing mise..."
curl https://mise.run | sh
export PATH="$HOME/.local/bin:$PATH"

echo ">>> Installing yadm..."
mkdir -p ~/.local/bin
curl -fLo ~/.local/bin/yadm \
  https://github.com/TheLocehiliosan/yadm/raw/master/yadm
chmod +x ~/.local/bin/yadm

echo ">>> Installing zimfw (zsh framework)..."
curl -fsSL https://raw.githubusercontent.com/zimfw/install/master/install.zsh | zsh

echo ">>> Setting zsh as default shell..."
chsh -s "$(which zsh)"

echo ""
echo ">>> Bootstrap complete. Next steps:"
echo ""
echo "  1. Set up SSH key for GitHub:"
echo "       ssh-keygen -t ed25519 -C 'techstar.dev@hotmail.com' -f ~/.ssh/github"
echo "       cat ~/.ssh/github.pub"
echo "       # Add that key to: github.com → Settings → SSH and GPG keys"
echo ""
echo "  2. Restore dotfiles:"
echo "       ~/.local/bin/yadm clone git@github.com:g5becks/mac_backup.git"
echo "       ~/.local/bin/yadm alt"
echo ""
echo "  3. Install all tools:"
echo "       mise install"
echo ""
echo "  4. Restart shell:"
echo "       exec zsh"
