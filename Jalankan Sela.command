#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")"
zsh scripts/build.sh
open dist/Sela.app
