#!/usr/bin/env bash
set -e

echo "==> apt packages"
apt update
apt install -y git curl wget imagemagick ffmpegthumbnailer libwebp-dev \
    libxml2-dev libfreetype6-dev pkgconf parallel p7zip-full \
    git-flow zsh zsh-autosuggestions zsh-completions

echo "==> awscli v2"
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

echo "==> yadm"
mkdir -p ~/.local/bin
curl -fLo ~/.local/bin/yadm https://github.com/TheLocehiliosan/yadm/raw/master/yadm
chmod +x ~/.local/bin/yadm

echo "==> zimfw (requires zsh, installed above)"
curl -fsSL https://raw.githubusercontent.com/zimfw/install/master/install.zsh | zsh

echo "==> bat-extras"
git clone --depth 1 https://github.com/eth-p/bat-extras.git /tmp/bat-extras
/tmp/bat-extras/build.sh --install --prefix="$HOME/.local" --no-manuals
rm -rf /tmp/bat-extras

echo "==> bats-core + helper libraries"
git clone --depth 1 https://github.com/bats-core/bats-core.git /tmp/bats-core
/tmp/bats-core/install.sh /usr/local
rm -rf /tmp/bats-core

mkdir -p ~/.local/share/bats-libs
git clone --depth 1 https://github.com/bats-core/bats-assert.git ~/.local/share/bats-libs/bats-assert
git clone --depth 1 https://github.com/bats-core/bats-support.git ~/.local/share/bats-libs/bats-support  # bats-assert depends on this
git clone --depth 1 https://github.com/bats-core/bats-file.git ~/.local/share/bats-libs/bats-file
# source these from a project's test_helper.bash, e.g.:
#   load "$HOME/.local/share/bats-libs/bats-support/load"
#   load "$HOME/.local/share/bats-libs/bats-assert/load"
#   load "$HOME/.local/share/bats-libs/bats-file/load"

echo "==> bash-preexec"
curl -fsSL -o ~/.bash-preexec.sh \
    https://raw.githubusercontent.com/rcaloras/bash-preexec/master/bash-preexec.sh
grep -qxF '[[ -f ~/.bash-preexec.sh ]] && source ~/.bash-preexec.sh' ~/.bashrc || \
    echo '[[ -f ~/.bash-preexec.sh ]] && source ~/.bash-preexec.sh' >> ~/.bashrc

echo "==> docker"
apt install -y ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
tee /etc/apt/sources.list.d/docker.sources > /dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF
apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "==> done"
