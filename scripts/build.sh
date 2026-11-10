#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")/.."
build_arguments=()
case "${1:-}" in
    "") ;;
    --universal)
        build_arguments=(--arch arm64 --arch x86_64 --scratch-path "$PWD/.build/universal")
        ;;
    *) print -u2 "Penggunaan: zsh scripts/build.sh [--universal]"; exit 1 ;;
esac
export CLANG_MODULE_CACHE_PATH="$PWD/.build/clang-module-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$PWD/.build/swift-module-cache"
signing_identity="${SELA_SIGNING_IDENTITY:-${TEGAK_SIGNING_IDENTITY:--}}"
release_version="${SELA_VERSION:-${TEGAK_VERSION:-}}"
bundle_identifier="${SELA_BUNDLE_ID:-${TEGAK_BUNDLE_ID:-}}"
if [[ "$signing_identity" != "-" && "$signing_identity" != "Developer ID Application: "* ]]; then
    print -u2 "Gunakan sertifikat Developer ID Application untuk distribusi di luar App Store."
    exit 1
fi
swift build -c release -debug-info-format none --disable-sandbox --cache-path "$PWD/.build/cache" "${build_arguments[@]}"
binary_path="$(swift build -c release --disable-sandbox --cache-path "$PWD/.build/cache" "${build_arguments[@]}" --show-bin-path)"
staging_path="$(mktemp -d "$PWD/.build/app.XXXXXX")"
trap 'rm -rf "$staging_path"' EXIT
staged_app="$staging_path/Sela.app"
app_path="$PWD/dist/Sela.app"
mkdir -p "$staged_app/Contents/MacOS" "$staged_app/Contents/Resources" "$PWD/dist"
cp "$binary_path/Sela" "$staged_app/Contents/MacOS/Sela"
cp scripts/Info.plist "$staged_app/Contents/Info.plist"
if [[ -n "$release_version" ]]; then
    if [[ ! "$release_version" =~ '^[0-9]+\.[0-9]+\.[0-9]+$' ]]; then
        print -u2 "SELA_VERSION harus berupa tiga angka, misalnya 0.1.0."
        exit 1
    fi
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $release_version" "$staged_app/Contents/Info.plist"
fi
if [[ -n "$bundle_identifier" ]]; then
    if [[ ! "$bundle_identifier" =~ '^[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+$' ]]; then
        print -u2 "SELA_BUNDLE_ID harus berupa identifier bertitik, misalnya io.github.syahraazly.sela."
        exit 1
    fi
    /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $bundle_identifier" "$staged_app/Contents/Info.plist"
fi
if [[ "$signing_identity" == "-" ]]; then
    codesign --force --sign - --timestamp=none "$staged_app"
else
    codesign --force --sign "$signing_identity" --options runtime --timestamp "$staged_app"
fi
codesign --verify --deep --strict "$staged_app"
plutil -lint "$staged_app/Contents/Info.plist"
if [[ -e "$app_path" ]]; then rm -rf "$app_path"; fi
mv "$staged_app" "$app_path"
print "Aplikasi siap: $app_path"
