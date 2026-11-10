#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")"
zsh scripts/package-dmg.sh --preview
open dist
