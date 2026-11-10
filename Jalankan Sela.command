#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")"
zsh build.sh --no-dmg
open dist/Sela.app
