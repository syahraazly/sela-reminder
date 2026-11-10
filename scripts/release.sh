#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")/.."
export SELA_SIGNING_IDENTITY="${SELA_SIGNING_IDENTITY:-${TEGAK_SIGNING_IDENTITY:-}}"
export SELA_NOTARY_PROFILE="${SELA_NOTARY_PROFILE:-${TEGAK_NOTARY_PROFILE:-}}"

if [[ -z "$SELA_SIGNING_IDENTITY" || "$SELA_SIGNING_IDENTITY" != "Developer ID Application: "* ]]; then
    print -u2 "Rilis publik memerlukan SELA_SIGNING_IDENTITY dari sertifikat Developer ID Application di Keychain."
    exit 1
fi
if [[ -z "$SELA_NOTARY_PROFILE" ]]; then
    print -u2 "Isi SELA_NOTARY_PROFILE dengan nama profil notarytool di Keychain. Lihat docs/distribution.md."
    exit 1
fi
identities="$(security find-identity -v -p codesigning)"
if [[ "$identities" != *"\"$SELA_SIGNING_IDENTITY\""* ]]; then
    print -u2 "Sertifikat yang diminta tidak ditemukan atau belum valid. Periksa security find-identity -v -p codesigning."
    exit 1
fi

zsh scripts/build.sh --universal
staging_path="$(mktemp -d "$PWD/.build/notary.XXXXXX")"
trap 'rm -rf "$staging_path"' EXIT
app_path="$PWD/dist/Sela.app"

submit_for_notarization() {
    local artifact_path="$1"
    local report_path="$2"
    xcrun notarytool submit "$artifact_path" --keychain-profile "$SELA_NOTARY_PROFILE" \
        --wait --output-format json > "$report_path"
    python3 - "$report_path" <<'PY'
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text())
if report.get('status') != 'Accepted':
    submission_id = report.get('id', '(tidak tersedia)')
    sys.exit(f'Notarization belum diterima. Submission ID: {submission_id}. Periksa log menggunakan notarytool log.')
print(f'Notarization Accepted: {report["id"]}')
PY
}

ditto -c -k --keepParent "$app_path" "$staging_path/Sela.zip"
submit_for_notarization "$staging_path/Sela.zip" "$PWD/dist/notarization-app.json"
xcrun stapler staple "$app_path"
xcrun stapler validate "$app_path"
spctl --assess --type execute --verbose=2 "$app_path"
SELA_DMG_OUTPUT_DIR="$staging_path" zsh scripts/package-dmg.sh --release --skip-build
version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app_path/Contents/Info.plist")"
image_name="Sela-$version-universal.dmg"
image_path="$staging_path/$image_name"
submit_for_notarization "$image_path" "$PWD/dist/notarization-dmg.json"
xcrun stapler staple "$image_path"
xcrun stapler validate "$image_path"
spctl --assess --type open --context context:primary-signature --verbose=2 "$image_path"
mv -f "$image_path" "$PWD/dist/$image_name"
(
    cd dist
    shasum -a 256 "$image_name" > "$image_name.sha256"
)
print "Rilis publik siap diunggah: $PWD/dist/$image_name"
