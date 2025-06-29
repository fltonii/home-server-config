#!/bin/sh

set -e

# Detect distro
if [ -f /etc/os-release ]; then
  . /etc/os-release
  DISTRO=$ID
else
  echo "Cannot detect OS. Exiting."
  exit 1
fi

# Install GitHub CLI
install_gh_cli() {
  echo "Installing GitHub CLI..."

  if [ "$DISTRO" = "debian" ] || [ "$DISTRO" = "ubuntu" ]; then
    sudo apt update
    sudo apt install -y curl git openssh-client

    type -p gh >/dev/null || (
      curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg |
        sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg &&
        sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg &&
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" |
        sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null &&
        sudo apt update &&
        sudo apt install -y gh
    )

  elif [ "$DISTRO" = "alpine" ]; then
    echo "Installing GitHub CLI for Alpine..."

    sudo apk add --no-cache curl git openssh-client

    if ! command -v gh >/dev/null; then
      TMPDIR=$(mktemp -d)
      ARCH=$(uname -m)
      case "$ARCH" in
      x86_64) GH_ARCH=amd64 ;;
      aarch64) GH_ARCH=arm64 ;;
      *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
      esac

      GH_VERSION=$(curl -s https://api.github.com/repos/cli/cli/releases/latest | grep '"tag_name":' | cut -d '"' -f4) GH_URL="https://github.com/cli/cli/releases/download/${GH_VERSION}/gh_${GH_VERSION#v}_linux_${GH_ARCH}.tar.gz"

      echo "Downloading $GH_URL"
      curl -L "$GH_URL" -o "$TMPDIR/gh.tar.gz"
      tar -xzf "$TMPDIR/gh.tar.gz" -C "$TMPDIR"
      install "$TMPDIR"/gh_*/bin/gh /usr/local/bin/gh
      rm -rf "$TMPDIR"
    fi

  else
    echo "Unsupported distro: $DISTRO"
    exit 1
  fi
}

# Authenticate with GitHub
github_login() {
  echo "Logging into GitHub..."
  gh auth login
}

# Generate SSH key
setup_ssh_key() {
  SSH_KEY="$HOME/.ssh/github_ed25519"
  if [ -f "$SSH_KEY" ]; then
    echo "SSH key already exists at $SSH_KEY"
  else
    echo "Generating new SSH key..."
    mkdir -p ~/.ssh
    ssh-keygen -t ed25519 -C "$(gh api user --jq .login)" -f "$SSH_KEY" -N ""
    eval "$(ssh-agent -s)"
    ssh-add "$SSH_KEY"
  fi
}

# Upload key to GitHub
upload_ssh_key() {
  echo "Uploading SSH public key to GitHub..."
  TITLE="$(hostname)-$(date +%Y%m%d)"
  gh ssh-key add "$SSH_KEY.pub" --title "$TITLE"
}

# Run steps
install_gh_cli
github_login
setup_ssh_key
upload_ssh_key

echo "✅ SSH key successfully added to GitHub."
