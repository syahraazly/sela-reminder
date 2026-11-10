#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")/.."
signing_identity="${SELA_SIGNING_IDENTITY:-${TEGAK_SIGNING_IDENTITY:-}}"

release_mode=false
skip_build=false
for argument in "$@"; do
    case "$argument" in
        --preview) release_mode=false ;;
        --release) release_mode=true ;;
        --skip-build) skip_build=true ;;
        *) print -u2 "Penggunaan: zsh scripts/package-dmg.sh [--preview|--release] [--skip-build]"; exit 1 ;;
    esac
done

if $release_mode; then
    if [[ -z "$signing_identity" ]]; then
        print -u2 "DMG bernotarisasi memerlukan SELA_SIGNING_IDENTITY. Gunakan scripts/release.sh untuk notarization."
        exit 1
    fi
fi
if ! $skip_build; then zsh scripts/build.sh --universal; fi

app_path="$PWD/dist/Sela.app"
codesign --verify --deep --strict "$app_path"
if $release_mode; then xcrun stapler validate "$app_path"; fi
version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app_path/Contents/Info.plist")"
architectures="$(lipo -archs "$app_path/Contents/MacOS/Sela")"
if [[ "$architectures" == *arm64* && "$architectures" == *x86_64* ]]; then
    architecture_label=universal
elif [[ "$architectures" == arm64 || "$architectures" == x86_64 ]]; then
    architecture_label="$architectures"
else
    print -u2 "Arsitektur aplikasi tidak dikenali: $architectures"
    exit 1
fi

suffix="-preview"
if $release_mode; then suffix=""; fi
image_name="Sela-$version-$architecture_label$suffix.dmg"
output_path="${SELA_DMG_OUTPUT_DIR:-${TEGAK_DMG_OUTPUT_DIR:-$PWD/dist}}"
mkdir -p "$output_path"
staging_path="$(mktemp -d "$PWD/.build/dmg.XXXXXX")"
trap 'rm -rf "$staging_path"' EXIT
payload="$staging_path/payload"
mkdir -p "$payload"
ditto "$app_path" "$payload/Sela.app"
ln -s /Applications "$payload/Applications"
cat > "$payload/Baca dulu.txt" <<'INSTALL'
SELA

1. Drag Sela.app ke folder Applications di jendela ini.
2. Buka Sela dari Applications, pilih Duduk tegak atau Minum air putih,
   lalu atur interval pengingat.
3. Klik Mulai pengingat.
4. Eject disk Sela setelah aplikasi disalin.

Pengaturan dapat dibuka kembali dari ikon Sela di menu bar.
Menutup jendela pengaturan tidak menghentikan timer.
Untuk menghentikan aplikasi, pilih Keluar dari Sela di menu bar.

Memerlukan macOS 14 atau lebih baru. Tidak perlu Xcode atau Terminal.
Pengingat berbasis waktu, tanpa akses kamera atau deteksi postur.
INSTALL
if ! $release_mode; then
    cat >> "$payload/Baca dulu.txt" <<'PREVIEW'

VERSI PREVIEW
Paket ini ditandatangani ad hoc dan belum dinotarisasi oleh Apple.
Paket boleh dibagikan sebagai preview; macOS dapat menahannya saat pertama dibuka.
Jika pengembang belum diverifikasi dan sumber dipercaya: coba buka Sela,
lalu pilih System Settings > Privacy & Security > Open Anyway.
Panduan Apple:
https://support.apple.com/en-us/102445
PREVIEW
fi

hdiutil makehybrid -hfs -hfs-volume-name Sela -o "$staging_path/Sela-hfs.dmg" "$payload"
hdiutil convert "$staging_path/Sela-hfs.dmg" -format UDZO -o "$staging_path/Sela.dmg"
hdiutil verify "$staging_path/Sela.dmg"
if $release_mode; then
    codesign --force --sign "$signing_identity" --timestamp "$staging_path/Sela.dmg"
    codesign --verify --strict "$staging_path/Sela.dmg"
fi
mv -f "$staging_path/Sela.dmg" "$output_path/$image_name"
(
    cd "$output_path"
    shasum -a 256 "$image_name" > "$image_name.sha256"
)
print "DMG siap: $output_path/$image_name"
if ! $release_mode; then print "Status: preview, belum dinotarisasi Apple."; fi
