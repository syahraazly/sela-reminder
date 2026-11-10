# Alur distribusi seperti referensi menu bar

Referensi pengguna: [spotify-lyrics-menubar](https://github.com/nadialvy/spotify-lyrics-menubar). README referensi memisahkan instalasi untuk pengguna dari build source untuk pengembang, membagikan DMG melalui Releases, dan memakai ad-hoc signing. Sela menerapkan alur tersebut dengan kode packaging miliknya sendiri; MVVM dan fungsi pengingat tetap sama.

- PASS: `./build.sh` berhasil membangun aplikasi universal, menandatangani ad hoc, membuat image terkompresi, memverifikasi image, dan menyiapkan `dist/Sela.dmg` serta SHA-256.
- PASS: `Sela.dmg` identik byte demi byte dengan salinan berversi; aplikasi lolos verifikasi signature ad hoc.
- PASS: root builder menyediakan `--no-dmg` untuk meneruskan build aplikasi lokal, `--help`, dan penolakan argumen yang tidak dikenal. Syntax seluruh script diperiksa dengan `zsh -n`.
- PASS: workflow GitHub dapat diparse, langkah shell lolos `bash -n`, build memakai root entry point, dan asset upload bernama `Sela.dmg` beserta checksum.
- PASS: README mendahulukan download dan instalasi, membedakan pengguna dari pengembang, serta menjelaskan persetujuan aplikasi pertama sesuai [panduan Apple](https://support.apple.com/en-us/102445).
- PASS: signing Developer ID/notarization dijelaskan sebagai opsi distribusi. Packaging ad hoc tidak dinyatakan memerlukan akun Apple Developer agar dapat dibagikan di GitHub.
- PASS: petunjuk dalam DMG serta catatan release menjelaskan status ad hoc; tidak menyalin klaim performa atau jaminan keamanan dari aplikasi referensi.

Belum diverifikasi: upload nyata ke GitHub, URL asset setelah publikasi, dan pemasangan DMG melalui desktop Mac lain. Paket belum dinotarisasi, dan pilihan Open Anyway dapat bergantung pada pesan macOS serta kebijakan administrator. Tidak ada perubahan pada View, ViewModel, Model, atau perilaku timer dalam penyesuaian alur distribusi ini.
