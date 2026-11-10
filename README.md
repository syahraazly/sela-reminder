# Sela

Sela adalah aplikasi native macOS untuk mengingatkan **duduk tegak** atau **minum air putih**. Aplikasi berjalan dari menu bar dan menampilkan pengingat di area island saat waktunya tiba. Dibuat dengan Swift dan AppKit.

## Jalankan lokal

Cara utama saat ini: clone repository, build menjadi aplikasi, lalu jalankan di Mac sendiri. Memerlukan **macOS 14 atau lebih baru**, Git, dan **Swift 6 atau lebih baru** dari Xcode atau Command Line Tools.

Jika Command Line Tools belum terpasang, jalankan perintah berikut dan selesaikan dialog instalasinya:

```sh
xcode-select --install
```

Periksa `swift --version` dan pastikan versi 6 atau lebih baru. Setelah itu:

```sh
git clone https://github.com/syahraazly/posture-reminder.git
cd posture-reminder
zsh build.sh --no-dmg
open dist/Sela.app
```

Perintah build menghasilkan `dist/Sela.app`. Setelah aplikasi terbuka, pilih **Duduk tegak** atau **Minum air putih**, atur interval, lalu klik **Mulai pengingat**. Source yang di-clone dibuild di Mac kamu menjadi aplikasi; tidak perlu membuat atau mendownload DMG untuk cara ini.

Untuk membuka lagi, cukup buka `dist/Sela.app` lewat Finder. Kamu juga dapat menyalinnya ke Applications, atau klik dua kali **Jalankan Sela.command** untuk build dan membuka aplikasi dari folder project.

Sela tetap berjalan di menu bar saat jendela pengaturan ditutup. Untuk mematikannya, klik ikon Sela di menu bar lalu pilih **Keluar dari Sela**.

## Download DMG (opsional)

DMG bisa dibuat, tetapi unduhan publik hanya tersedia setelah asset diunggah dan release dipublikasikan. Mem-push source atau workflow saja tidak menerbitkan DMG. Jika paketnya sudah tersedia, pengguna DMG tidak perlu clone repository atau memasang Xcode.

1. Buka [halaman Releases](https://github.com/syahraazly/posture-reminder/releases), lalu download **Sela.dmg** di bagian **Assets**. Jika belum ada asset DMG, paket belum dipublikasikan. File Source code ZIP bukan installer aplikasi.
2. Buka DMG, lalu drag **Sela.app** ke shortcut **Applications**.
3. Buka **Sela** dari folder Applications.
4. Pilih **Duduk tegak** atau **Minum air putih**, atur interval, lalu klik **Mulai pengingat**.

Pengaturan dan pilihan keluar tersedia lewat ikon Sela di menu bar. Menutup jendela pengaturan tetap membiarkan timer berjalan.

### Pertama kali dibuka

Paket preview ditandatangani ad hoc dan belum dinotarisasi Apple. Jika macOS menolak karena pengembang belum dapat diverifikasi dan kamu mempercayai sumber unduhannya:

1. Coba buka Sela sekali.
2. Buka **System Settings → Privacy & Security → Open Anyway** untuk Sela.
3. Konfirmasikan **Open**.

Ikuti [panduan Apple](https://support.apple.com/en-us/102445) sesuai pesan yang muncul. Paket ad hoc bisa dibagikan melalui Releases tanpa akun Apple Developer; signing Developer ID dan notarization tersedia sebagai opsi distribusi.

## Publikasikan unduhan

Cara langsung: jalankan `./build.sh`, buka [halaman membuat release](https://github.com/syahraazly/posture-reminder/releases/new), buat tag seperti `v0.1.0-preview`, lampirkan `dist/Sela.dmg` beserta `dist/Sela.dmg.sha256`, tandai sebagai pre-release, lalu klik **Publish release**. Setelah itu pengguna dapat download lewat halaman Releases. Repository harus public untuk unduhan tanpa akses khusus.

Workflow otomatis juga tersedia: push perubahan termasuk `.github/workflows/publish-preview.yml` ke branch default, lalu buka **Actions → Publish DMG preview → Run workflow**, isi versi, dan jalankan. Workflow menguji source, membuat DMG universal, serta mengunggah dan mempublikasikannya sebagai pre-release. Workflow ini belum dijalankan dari sesi lokal ini.

DMG lokal belum otomatis menjadi unduhan publik. Folder `dist/` masuk `.gitignore`; binary dibagikan sebagai asset release. Untuk opsi Developer ID dan notarization, lihat [panduan distribusi](docs/distribution.md).

## Membuat paket distribusi

Untuk membuat aplikasi sekaligus DMG universal, jalankan dari folder project:

```sh
./build.sh
```

Perintah ini membangun aplikasi universal Apple Silicon/Intel, menandatanganinya ad hoc, lalu menghasilkan:

- `dist/Sela.app`
- `dist/Sela.dmg`
- `dist/Sela.dmg.sha256`

Untuk pemakaian lokal, gunakan langkah di bagian **Jalankan lokal**. **Buat DMG.command** adalah shortcut untuk membuat paket distribusi.

Jika versi lama bernama Tegak masih berjalan, pilih **Keluar dari Tegak** terlebih dahulu. Identitas penyimpanan aplikasi dipertahankan agar pilihan jenis, interval, dan suara tetap terbaca.

### Script packaging lanjutan

Script packaging juga tersedia langsung:

```sh
zsh scripts/package-dmg.sh --preview
```

Script ini menyimpan paket berversi seperti `dist/Sela-0.1.0-universal-preview.dmg`. `./build.sh` menyiapkan salinan bernama `Sela.dmg` agar nama file unduhan tetap sederhana. DMG berisi aplikasi, shortcut Applications, dan petunjuk instalasi.

## Pakai

- Pada **Ingatkan untuk**, pilih **Duduk tegak** atau **Minum air putih**. Satu jenis aktif pada satu waktu; pilihan tersimpan otomatis. Mengganti jenis tidak mengulang sisa waktu timer.
- Pilih 15, 30, 45, atau 60 menit; atau isi angka bulat 1–180 menit, lalu tekan Enter. Interval tersimpan otomatis. Mengubah interval mengulang hitungan timer.
- Klik **Mulai pengingat**. **Jeda pengingat** dan **Lanjutkan pengingat** mempertahankan sisa waktu.
- **Coba pengingat** menampilkan contoh pesan sesuai jenis yang dipilih, tanpa mengubah timer. Tutup dengan **Tutup contoh** atau Escape.
- Saat pengingat asli muncul, **Sudah tegak** atau **Sudah minum** memulai interval berikutnya, sesuai jenis yang dipilih. **Tunda 5 menit** atau Escape menunda lima menit.
- Klik sisi kiri atau kanan island untuk membuka kontrol. Menu bar juga menyediakan **Buka island**, **Pengaturan**, dan **Keluar dari Sela**.
- Menutup jendela pengaturan tetap membiarkan aplikasi berjalan. Keluar lewat menu bar atau Command-Q.
- Suara pengingat bersifat opsional dan awalnya mati. Jenis pengingat, interval, dan pilihan suara dipertahankan saat aplikasi dibuka kembali; timer dimulai manual.

Pengaturan mengikuti tampilan terang/gelap macOS. Island selalu hitam agar menyatu dengan notch. Tanpa notch, island tetap tampil di tengah atas layar. Setelah Mac bangun dari sleep, timer aktif dimulai ulang agar waktu tidur tidak dihitung sebagai waktu duduk.

Ini aplikasi pengingat, tanpa deteksi postur atau akses kamera. Pengingat hanya bekerja saat aplikasi berjalan dan Mac terjaga. Overlay menggunakan jendela AppKit; ini bukan modifikasi notch bawaan macOS. Di atas aplikasi fullscreen atau mode tampilan tertentu, perilaku overlay dapat bergantung pada macOS.

## Pengembangan dan verifikasi

```sh
zsh scripts/test.sh
```

Tes engine memakai jam yang dikontrol untuk memeriksa deadline, jeda/lanjut, preview, tunda, dan wake. Tes ViewModel memeriksa validasi, draft input, sinkronisasi state, routing, dan permintaan suara tanpa AppKit. Smoke test mengaktifkan kontrol AppKit asli dengan `performClick`/target-action, memeriksa navigasi Tab dan tombol Enter, dan merender tampilan ke `docs/previews/`. Ini tidak memerlukan izin Screen Recording atau Accessibility.

Untuk menjalankan smoke test UI:

```sh
zsh scripts/test.sh --ui
```

Tanpa akses layar, smoke test menggunakan window AppKit di luar layar dengan geometri layar virtual 1512 × 982. Kontrol dan renderer tetap berasal dari kode aplikasi yang sama. Hasil serta preview tersedia di `docs/previews/`. Pembukaan aplikasi dari Finder, menu bar fisik, posisi terhadap notch, perpindahan Spaces, suara, dan fullscreen masih memerlukan pemeriksaan di sesi desktop macOS. Script melaporkan kegagalan jika AppKit keluar tanpa benar-benar menjalankan pemeriksaan.

- `Sources/SelaCore/Models/`: state dan aturan timer pada `ReminderEngine`, serta identitas aplikasi.
- `Sources/SelaCore/ViewModels/`: aksi pengguna, validasi input, serta state pengaturan, island, dan menu bar.
- `Sources/SelaCore/Services/`: kontrak penyimpanan preferensi dan implementasi UserDefaults.
- `Sources/Sela/Views/`: layout dan render komponen AppKit.
- `Sources/Sela/Controllers/`: penghubung event AppKit ke ViewModel dan pengelolaan window/menu.
- `Sources/Sela/Application/`: entry point, lifecycle, serta koordinasi pembaruan tampilan.
- `Sources/Sela/Services/`: timer sistem, wake, perubahan layar, dan suara.
- `Sources/Sela/Diagnostics/`: smoke test UI dengan jam yang dikontrol.
- `docs/previews/smoke-test.txt`: catatan pemeriksaan interaksi terakhir.
- `docs/contrast.txt`: perhitungan kontras warna.
- `docs/design-notes.md`: alasan keputusan desain.

Project memakai MVVM dengan `ReminderViewModel` sebagai sumber state UI bersama. `SelaCore` tidak mengimpor AppKit; Model dan ViewModel bisa diuji tanpa window. Lihat [panduan arsitektur](docs/architecture.md) untuk alur data dan lokasi perubahan fitur.

Tanpa konfigurasi signing, aplikasi ditandatangani ad hoc dan dapat dibagikan sebagai preview. Opsi `scripts/release.sh` menyiapkan Developer ID, notarization, stapling, dan pemeriksaan Gatekeeper; opsi ini memerlukan sertifikat serta kredensial Apple Developer di Keychain dan belum dijalankan di lingkungan ini.
