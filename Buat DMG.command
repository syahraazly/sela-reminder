#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")"
zsh build.sh
open dist
