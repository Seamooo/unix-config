# Unix Config

A set of config files for setting up a new environment.

## Contents

there exists configuration and automatic installs for the below packages

- nvm
- neovim
- vim-plug
- coc
- tmux
- vim
- sublime text
- vscode

## Setup

If setting up a new debian based environment, there's an easy
setup script available. Copy one of the below depending on
whether you're setting up a desktop or headless environment

### Desktop

```bash
sudo apt-get update && \
  sudo apt-get install -y curl && \
  curl "https://raw.githubusercontent.com/Seamooo/unix-config/master/setup.sh" \
  | sudo -E bash
```

### Headless

```bash
sudo apt-get update && \
  sudo apt-get install -y curl && \
  curl "https://raw.githubusercontent.com/Seamooo/unix-config/master/setup.sh" \
  | sudo -E bash -s - --headless
```

