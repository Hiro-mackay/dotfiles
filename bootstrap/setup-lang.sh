#!/usr/bin/env zsh


# All runtimes, tools and services necessary for development will be managed using RTX (https://github.com/jdx/rtx).
# RTX reads ${XDG_CONFIG_HOME}/rtx/config.toml and configures the runtime environment.
# Rust is an exception because the community has a mature package manager called Cargo, which does not use rtx and installs directly


echo "Start language install..."

# ----------------------
# Cargo
# ----------------------
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh


# ----------------------
# RTX
# ----------------------
if [ -x "$(command -v rtx)" ]; then
    # RTX install by ${XDG_CONFIG_HOME}/rtx/config.toml
    rtx install
fi