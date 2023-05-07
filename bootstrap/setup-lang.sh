#!/bin/sh

echo "Start language install..."

# ----------------------
# Cargo
# ----------------------
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh


# ----------------------
# Volta
# ----------------------
curl https://get.volta.sh | bash


# ----------------------
# Pyenv
# ----------------------
curl https://pyenv.run | bash
eval "$(pyenv init -)"
eval "$(pyenv init --path)"


# ----------------------
# Pipenv
# ----------------------
PYTHON_VERSION=$(pyenv install --list | grep --extended-regexp "^\s*[0-9][0-9.]*[0-9]\s*$" | tail -1)
pyenv install $PYTHON_VERSION
pyenv global $PYTHON_VERSION
pip install pipenv


# ----------------------
# Golang
# ----------------------
curl https://golang.org/dl/$(curl https://go.dev/VERSION?m=text).darwin-amd64.tar.gz | tar xz --strip 1 -C $GOPATH


# ---------------------- 
# Deno
# ----------------------
curl -fsSL https://deno.land/x/install/install.sh | sh
