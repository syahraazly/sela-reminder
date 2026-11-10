#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")/.."
export CLANG_MODULE_CACHE_PATH="$PWD/.build/clang-module-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$PWD/.build/swift-module-cache"
swift test --disable-sandbox --cache-path "$PWD/.build/cache"
if [[ "${1:-}" != "--ui" ]]; then
    exit 0
fi
swift build --disable-sandbox --cache-path "$PWD/.build/cache"
binary_path="$(swift build --disable-sandbox --cache-path "$PWD/.build/cache" --show-bin-path)"
python3 - "$binary_path/Sela" <<'PY'
from pathlib import Path
import subprocess
import sys
import time

output = Path('docs/previews').resolve()
started = time.time()
try:
    result = subprocess.run([sys.argv[1], '--smoke-test', '--smoke-output', str(output)], timeout=30)
except subprocess.TimeoutExpired:
    sys.exit('UI smoke test berhenti setelah 30 detik. Jalankan dari sesi desktop macOS yang aktif.')
if result.returncode:
    sys.exit(result.returncode)
report = output / 'smoke-test.txt'
if not report.exists() or report.stat().st_mtime < started:
    sys.exit('UI smoke test belum berjalan: akses sesi desktop tidak tersedia. Jalankan dari Terminal di macOS.')
if 'FAIL:' in report.read_text():
    sys.exit(1)
PY
