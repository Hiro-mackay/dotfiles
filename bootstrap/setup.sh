#!/bin/sh

set -x

script_dir="$(dirname "$(realpath "$0")")"

source $script_dir/env.sh

echo "Start Xcode install..."
xcode-select --install


$script_dir/setup-dir.sh
$script_dir/setup-link.sh
$script_dir/setup-brew.sh
$script_dir/setup-lang.sh
$script_dir/setup-macos.sh
