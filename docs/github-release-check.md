# Pemeriksaan alur unduhan GitHub

Status: file DMG lokal tersedia dan valid. Workflow publikasi sudah ditulis, tetapi belum dipush atau dijalankan di GitHub dan belum menghasilkan URL asset publik dari sesi ini.

- PASS: `dist/Sela.dmg` serta salinan berversi tersedia dan checksum SHA-256 cocok. Workflow membuat paket melalui `build.sh` di root dan mengunggah asset bernama Sela.dmg beserta checksum.
- PASS: YAML workflow dapat diparse; seluruh langkah shell lolos `bash -n`.
- PASS: preflight menerima versi numerik dan menghasilkan tag preview yang sesuai, diuji dengan fixture CLI GitHub lokal.
- PASS: input versi yang tidak valid ditolak sebelum publikasi.
- PASS: repository private ditolak untuk alur download publik, diuji dengan fixture CLI GitHub lokal.
- PASS: release yang sudah ada tidak ditimpa, diuji dengan fixture CLI GitHub lokal.
- PASS: alur memakai token bawaan repository dengan izin `contents: write`, mengunggah DMG/checksum ke draft, lalu mempublikasikan pre-release setelah upload berhasil.
- PASS: README membedakan file lokal, source Git, dan asset Releases; tidak menjanjikan asset yang belum dipublikasikan. Cara upload manual dan menjalankan workflow dijelaskan.

Belum diverifikasi: akses ke repository melalui akun pengguna, pengaturan visibility/Actions remote, eksekusi pada runner GitHub, upload asset, serta URL download setelah publikasi. Koneksi GitHub belum terpasang/terhubung pada sesi ini, dan CLI `gh` tidak tersedia secara lokal. Pemeriksaan dengan fixture tidak membuktikan bahwa upload ke GitHub sudah berhasil.

File utama: [workflow](../.github/workflows/publish-preview.yml), [catatan release](preview-release-notes.md), dan [panduan distribusi](distribution.md). Tidak ada perubahan pada kode atau tampilan aplikasi; paket tetap preview tanpa notarization Apple.
