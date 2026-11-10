# Distribusi Sela lewat DMG

Pengguna akhir: download DMG, buka, drag Sela.app ke Applications, lalu buka Sela dari Applications. Aplikasi tidak memerlukan Swift, Xcode, atau Terminal di Mac pengguna. Minimum macOS 14. Build universal berisi arm64 untuk Apple Silicon dan x86_64 untuk Intel; pengujian runtime saat ini dilakukan pada host Apple Silicon, belum pada hardware Intel.

## Status saat ini

- `dist/Sela.dmg` adalah paket preview lokal untuk dibagikan. Salinan berversi juga tersedia di `dist/`.
- Paket berisi aplikasi, symlink Applications, dan Baca dulu.txt.
- Aplikasi ditandatangani ad hoc. Belum memakai sertifikat Developer ID dan belum dinotarisasi.
- Pemeriksaan Keychain pada sesi ini menemukan nol signing identity yang valid.
- Belum ada DMG yang diunggah sebagai unduhan publik. File lokal dan alamat download publik adalah dua langkah berbeda.

DMG yang ditandatangani ad hoc tetap dapat dibagikan publik melalui GitHub Releases tanpa akun Apple Developer. Pengguna mungkin perlu memberikan persetujuan saat pertama membuka aplikasi; petunjuknya ada di README dan [panduan Apple](https://support.apple.com/en-us/102445). Developer ID dan notarization adalah opsi agar Gatekeeper dapat memverifikasi distribusi melalui alur Apple. Sumber: [Notarizing macOS software before distribution](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution).

## Buat preview lokal

Klik **Buat DMG.command** atau jalankan:

```sh
./build.sh
```

Script memakai `hdiutil makehybrid` untuk menyusun filesystem HFS+ dari folder, lalu `hdiutil convert` untuk menghasilkan image UDIF terkompresi. Cara ini tidak perlu me-mount volume saat pembuatan. Checksum image diperiksa oleh `hdiutil verify`; SHA-256 disimpan di samping DMG. Paket berversi memakai akhiran `-preview`, sedangkan file untuk pengguna bernama `Sela.dmg`. Keduanya berisi aplikasi yang sama dan petunjuk status notarization.

Untuk menjalankan aplikasi yang sudah dibangun tanpa DMG, buka `dist/Sela.app` lewat Finder. Tutup versi lama bernama Tegak terlebih dahulu. Bundle identifier bawaan tetap `local.dummy.tegak` agar preferensi instalasi lama tetap terbaca; nama tampilan dan executable sudah Sela.

## Opsional: rilis dengan Developer ID dan notarization

Bagian berikut khusus opsi notarization dan dijalankan oleh pengembang dengan akses Apple Developer. Bagian ini tidak diperlukan untuk membagikan paket ad hoc melalui Releases.

1. Siapkan keanggotaan Apple Developer Program serta sertifikat **Developer ID Application** dengan private key di Keychain Mac pengembang. Akun saja belum cukup jika sertifikat dan private key belum tersedia.
2. Periksa nama sertifikat dengan `security find-identity -v -p codesigning`.
3. Simpan profil notarization secara interaktif di Keychain:

   ```sh
   xcrun notarytool store-credentials sela-notary
   ```

   Tool akan meminta data autentikasi. Jangan menaruh password, file sertifikat, atau private key di repository atau chat.

4. Tentukan versi dan bundle identifier yang akan dipakai untuk rilis bernotarisasi, lalu jalankan dari folder project:

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

DMG di `dist/` hanya tersedia di Mac pengembang. Folder tersebut diabaikan Git agar binary hasil build tidak bercampur dengan source. Gunakan GitHub Releases untuk menyediakan file unduhan.

### Preview melalui GitHub Actions

1. Push source beserta `.github/workflows/publish-preview.yml` ke branch default repository.
2. Pastikan repository public agar asset release dapat diakses tanpa undangan.
3. Buka **Actions → Publish DMG preview → Run workflow**.
4. Isi versi, misalnya `0.1.0`, dan jalankan. Workflow menjalankan tes, membangun DMG universal, memverifikasi SHA-256, mengunggah asset ke draft, lalu mempublikasikannya sebagai pre-release setelah upload berhasil.
5. Buka halaman release dari ringkasan workflow dan bagikan link tersebut kepada pengguna. Asset yang dipilih adalah `Sela.dmg`, bukan Source code ZIP. File `Sela.dmg.sha256` ikut dilampirkan.

Workflow memakai token repository bawaan GitHub dengan izin `contents: write`; tidak memerlukan personal access token di source. Nama tag berbentuk `v0.1.0-preview`. Jika tag release sudah dipakai, pilih versi baru. Jika upload/publikasi gagal setelah draft dibuat, periksa draft di halaman Releases sebelum mencoba lagi. Script signing/notarization tidak dijalankan dalam workflow preview ini.

Cara manual juga tersedia: buka halaman **Releases → Draft a new release**, pilih tag, lampirkan `dist/Sela.dmg` serta checksum, tandai pre-release untuk paket preview, lalu pilih **Publish release**. Tidak perlu memasukkan file DMG ke Git.

Panduan resmi: [menjalankan workflow manual](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/manually-run-a-workflow) dan [membuat GitHub Release](https://cli.github.com/manual/gh_release_create).

### Paket yang sudah dinotarisasi

Setelah `release.sh` berhasil, unggah dua file berikut sebagai asset release di repository `syahraazly/posture-reminder`, atau ke hosting download yang kamu pilih:

- `dist/Sela-0.1.0-universal.dmg`
- `dist/Sela-0.1.0-universal.dmg.sha256`

Untuk menyebut sebuah paket sudah dinotarisasi, gunakan hasil alur notarization yang berhasil dan tiketnya sudah diverifikasi. Nama file `Sela.dmg` saja tidak menyatakan status notarization. Setelah release dipublikasikan, bagikan link asset DMG kepada pengguna.

Sebelum publikasi, coba install dari hasil download di desktop Mac: salin ke Applications, buka app, mulai timer, coba pengingat, cek posisi notch/menu bar, tutup pengaturan, serta keluar dari menu bar. Cek di hardware Intel jika dukungan Intel hendak diumumkan. Verifikasi juga fullscreen/Spaces karena lingkungan otomatis di sesi ini tidak memiliki layar fisik.

## Jika notarization ditolak

Lihat submission ID pada laporan JSON, lalu unduh log dengan profil yang sama:

```sh
xcrun notarytool log SUBMISSION_ID --keychain-profile sela-notary dist/notarization-log.json
```

Perbaiki penyebabnya dan jalankan ulang proses release. Script tidak mengunggah paket ke hosting dan tidak mempublikasikan release secara otomatis.
