#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")/.."
export CLANG_MODULE_CACHE_PATH="$PWD/.build/clang-module-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$PWD/.build/swift-module-cache"
swift build -c release -debug-info-format none --disable-sandbox --cache-path "$PWD/.build/cache"
binary_path="$(swift build -c release --disable-sandbox --cache-path "$PWD/.build/cache" --show-bin-path)"
app_path="$PWD/dist/Tegak.app"
mkdir -p "$app_path/Contents/MacOS" "$app_path/Contents/Resources"
cp "$binary_path/Tegak" "$app_path/Contents/MacOS/Tegak"
cp scripts/Info.plist "$app_path/Contents/Info.plist"
codesign --force --sign - "$app_path"
print "Aplikasi siap: $app_path"
