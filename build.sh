#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")"

case "${1:-}" in
    "")
        zsh scripts/package-dmg.sh --preview
        version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' dist/Sela.app/Contents/Info.plist)"
        cp "dist/Sela-$version-universal-preview.dmg" dist/Sela.dmg
        (
            cd dist
            shasum -a 256 Sela.dmg > Sela.dmg.sha256
        )
        print "Paket untuk dibagikan: $PWD/dist/Sela.dmg"
        ;;
    --no-dmg) zsh scripts/build.sh ;;
    --help|-h)
        print "./build.sh           Build Sela.app dan Sela.dmg universal (ad hoc)."
        print "./build.sh --no-dmg  Build Sela.app untuk Mac lokal tanpa DMG."
        ;;
    *) print -u2 "Penggunaan: ./build.sh [--no-dmg|--help]"; exit 1 ;;
esac
