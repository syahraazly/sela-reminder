# Tegak

Dummy project aplikasi macOS untuk pengingat duduk tegak berbasis waktu. Island kecil berada di tengah atas layar, menyatu dengan area notch jika tersedia. Saat timer habis, island terbuka dengan pengingat dan tombol tindakan.

## Jalankan

Buka **Jalankan Tegak.command** dengan klik dua kali. Script membangun aplikasi lalu membuka `dist/Tegak.app`. Build pertama memerlukan Xcode atau Command Line Tools dengan Swift 6. Aplikasi memerlukan macOS 14 atau lebih baru.

Bisa juga melalui Terminal di folder project:

```sh
zsh scripts/build.sh
open dist/Tegak.app
```

Setelah dibangun, buka `dist/Tegak.app` langsung untuk penggunaan berikutnya.

## Pakai

- Pilih 15, 30, 45, atau 60 menit; atau isi angka bulat 1–180 menit, lalu tekan Enter. Interval tersimpan otomatis. Mengubah interval mengulang hitungan timer.
- Klik **Mulai pengingat**. **Jeda pengingat** dan **Lanjutkan pengingat** mempertahankan sisa waktu.
- **Coba pengingat** membuka preview tanpa mengubah jadwal. Tutup dengan **Tutup preview** atau Escape.
- Saat pengingat asli muncul, **Sudah tegak** memulai interval berikutnya. **Tunda 5 menit** atau Escape menunda lima menit.
- Klik sisi kiri atau kanan island untuk membuka kontrol. Menu bar juga menyediakan **Buka island**, **Pengaturan**, dan **Keluar dari Tegak**.
- Menutup jendela pengaturan tetap membiarkan aplikasi berjalan. Keluar lewat menu bar atau Command-Q.
- Suara pengingat bersifat opsional dan awalnya mati. Interval dan pilihan suara dipertahankan saat aplikasi dibuka kembali; timer dimulai manual.

Pengaturan mengikuti tampilan terang/gelap macOS. Island selalu hitam agar menyatu dengan notch. Tanpa notch, island tetap tampil di tengah atas layar. Setelah Mac bangun dari sleep, timer aktif dimulai ulang agar waktu tidur tidak dihitung sebagai waktu duduk.

Ini aplikasi pengingat, tanpa deteksi postur atau akses kamera. Pengingat hanya bekerja saat aplikasi berjalan dan Mac terjaga. Overlay menggunakan jendela AppKit; ini bukan modifikasi notch bawaan macOS. Di atas aplikasi fullscreen atau mode tampilan tertentu, perilaku overlay dapat bergantung pada macOS.

## Pengembangan dan verifikasi

```sh
zsh scripts/test.sh
```

Tes engine memakai jam yang dikontrol untuk memeriksa deadline, jeda/lanjut, preview, tunda, dan wake. Smoke test mengaktifkan kontrol AppKit asli dengan `performClick`/target-action, memeriksa navigasi Tab dan tombol Enter, dan merender tampilan ke `docs/previews/`. Ini tidak memerlukan izin Screen Recording atau Accessibility.

Untuk menjalankan smoke test UI:

```sh
zsh scripts/test.sh --ui
```

Tanpa akses layar, smoke test menggunakan window AppKit di luar layar dengan geometri layar virtual 1512 × 982. Kontrol dan renderer tetap berasal dari kode aplikasi yang sama. Hasil serta preview tersedia di `docs/previews/`. Pembukaan aplikasi dari Finder, menu bar fisik, posisi terhadap notch, perpindahan Spaces, suara, dan fullscreen masih memerlukan pemeriksaan di sesi desktop macOS. Script melaporkan kegagalan jika AppKit keluar tanpa benar-benar menjalankan pemeriksaan.

- `Sources/TegakCore/ReminderEngine.swift`: state dan penjadwalan timer.
- `Sources/Tegak/`: window pengaturan, island, menu bar, dan integrasi macOS.
- `docs/previews/smoke-test.txt`: catatan pemeriksaan interaksi terakhir.
- `docs/contrast.txt`: perhitungan kontras warna.
- `docs/design-notes.md`: alasan keputusan desain.

Aplikasi dibangun dan ditandatangani ad hoc untuk penggunaan lokal. Belum dinotarisasi untuk distribusi publik.
