#!/usr/bin/env bash

configSrc="https://raw.githubusercontent.com/YaLTeR/niri/refs/heads/main/niri-config/src/lib.rs"
dest="./settings.nix"

file="$(mktemp)"

curl $configSrc > $file

# reasonably fast
# so no need for release target
./settings/target/debug/settings $file $dest
