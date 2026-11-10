# Distribusi Sela lewat DMG

Pengguna akhir: download DMG, buka, drag Sela.app ke Applications, lalu buka Sela dari Applications. Aplikasi tidak memerlukan Swift, Xcode, atau Terminal di Mac pengguna. Minimum macOS 14. Build universal berisi arm64 untuk Apple Silicon dan x86_64 untuk Intel; pengujian runtime saat ini dilakukan pada host Apple Silicon, belum pada hardware Intel.

## Status saat ini

- `dist/Sela-0.1.0-universal-preview.dmg` adalah paket preview lokal.
- Paket berisi aplikasi, symlink Applications, dan Baca dulu.txt.
- Aplikasi ditandatangani ad hoc. Belum memakai sertifikat Developer ID dan belum dinotarisasi.
- Pemeriksaan Keychain pada sesi ini menemukan nol signing identity yang valid.
- Belum ada DMG yang diunggah sebagai unduhan publik. File lokal dan alamat download publik adalah dua langkah berbeda.

DMG saja tidak menggantikan signing dan notarization. Untuk distribusi langsung di luar App Store, Apple menyediakan alur Developer ID dan notarization agar Gatekeeper dapat memverifikasi aplikasi. Sumber: [Notarizing macOS software before distribution](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution).

## Buat preview lokal

Klik **Buat DMG.command** atau jalankan:

```sh
zsh scripts/package-dmg.sh --preview
```

Script memakai `hdiutil makehybrid` untuk menyusun filesystem HFS+ dari folder, lalu `hdiutil convert` untuk menghasilkan image UDIF terkompresi. Cara ini tidak perlu me-mount volume saat pembuatan. Checksum image diperiksa oleh `hdiutil verify`; checksum SHA-256 juga disimpan di samping DMG. File preview memakai akhiran `-preview` dan petunjuk di dalamnya menjelaskan status notarization.

Untuk menjalankan aplikasi yang sudah dibangun tanpa DMG, buka `dist/Sela.app` lewat Finder. Tutup versi lama bernama Tegak terlebih dahulu. Bundle identifier bawaan tetap `local.dummy.tegak` agar preferensi instalasi lama tetap terbaca; nama tampilan dan executable sudah Sela.

## Persiapan rilis publik

Bagian berikut dijalankan oleh pengembang di Mac dengan akses Apple Developer, bukan oleh pengguna akhir.

1. Siapkan keanggotaan Apple Developer Program serta sertifikat **Developer ID Application** dengan private key di Keychain Mac pengembang. Akun saja belum cukup jika sertifikat dan private key belum tersedia.
2. Periksa nama sertifikat dengan `security find-identity -v -p codesigning`.
3. Simpan profil notarization secara interaktif di Keychain:

   ```sh
   xcrun notarytool store-credentials sela-notary
   ```

   Tool akan meminta data autentikasi. Jangan menaruh password, file sertifikat, atau private key di repository atau chat.

4. Tentukan versi dan bundle identifier yang akan dipakai untuk rilis publik, lalu jalankan dari folder project:

   ```sh
   export SELA_SIGNING_IDENTITY='Developer ID Application: NAMA DI SERTIFIKAT (TEAM_ID)'
   export SELA_NOTARY_PROFILE='sela-notary'
   export SELA_VERSION='0.1.0'
   export SELA_BUNDLE_ID='io.github.syahraazly.sela'
   zsh scripts/release.sh
   ```

   Ganti nilai identitas signing dengan hasil Keychain milikmu. Gunakan bundle identifier yang ingin dipertahankan untuk rilis berikutnya. Jika meneruskan instalasi yang sudah ada, pertahankan identifier rilis tersebut agar domain preferensinya sama.

Script juga menerima variabel lama berawalan `TEGAK_` sebagai fallback. Jika kedua versi diisi, nilai `SELA_` dipakai.

Alur `release.sh`: validasi sertifikat, build universal, signing dengan Hardened Runtime dan secure timestamp, notarization aplikasi dalam ZIP, stapling aplikasi, pembuatan dan signing DMG, notarization/stapling DMG, lalu pemeriksaan Gatekeeper. DMG final dipindahkan ke `dist/` setelah langkah tersebut berhasil. Laporan notarization aplikasi dan DMG disimpan di `dist/notarization-app.json` dan `dist/notarization-dmg.json`.

Kredensial diambil dari profil Keychain. Script memeriksa status `Accepted`; penolakan tidak dianggap sebagai rilis berhasil. Penyimpanan kredensial, format pengiriman ZIP/DMG, `notarytool`, dan `stapler` mengikuti [Customizing the notarization workflow](https://developer.apple.com/documentation/security/customizing-the-notarization-workflow).

## Sediakan unduhan publik

Setelah `release.sh` berhasil, unggah dua file berikut sebagai asset release di repository `syahraazly/posture-reminder`, atau ke hosting download yang kamu pilih:

- `dist/Sela-0.1.0-universal.dmg`
- `dist/Sela-0.1.0-universal.dmg.sha256`

Jangan mengganti nama file preview agar tampak seperti hasil rilis yang sudah dinotarisasi. Upload file final yang dihasilkan oleh alur release yang berhasil. Setelah release dipublikasikan, bagikan link asset `.dmg` kepada pengguna.

Sebelum publikasi, coba install dari hasil download di desktop Mac: salin ke Applications, buka app, mulai timer, coba pengingat, cek posisi notch/menu bar, tutup pengaturan, serta keluar dari menu bar. Cek di hardware Intel jika dukungan Intel hendak diumumkan. Verifikasi juga fullscreen/Spaces karena lingkungan otomatis di sesi ini tidak memiliki layar fisik.

## Jika notarization ditolak

Lihat submission ID pada laporan JSON, lalu unduh log dengan profil yang sama:

```sh
xcrun notarytool log SUBMISSION_ID --keychain-profile sela-notary dist/notarization-log.json
```

Perbaiki penyebabnya dan jalankan ulang proses release. Script tidak mengunggah paket ke hosting dan tidak mempublikasikan release secara otomatis.
