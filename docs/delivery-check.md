# Pemeriksaan Tegak

Status: PASS untuk build, Model, ViewModel, kontrol AppKit, dan render di luar layar pada 10 November 2026. Tidak menyatakan bahwa penempatan pada layar fisik sudah diuji.

Validasi setelah refactor MVVM: 8 tes engine, 10 tes ViewModel, dan 57 pemeriksaan UI lulus. Build universal menghasilkan aplikasi lokal dan DMG preview. Signature diperiksa dengan `codesign --verify --deep --strict`; Info.plist diperiksa dengan `plutil -lint`.

Bukti: [rekaman interaksi](previews/smoke-test.txt), [kontras](contrast.txt), [alasan desain](design-notes.md), [tema terang](previews/settings-light.png), [tema gelap](previews/settings-dark.png), [validasi input](previews/settings-invalid-input.png), [island kecil](previews/island-compact.png), [pengingat](previews/island-reminder.png).

## Hard Gate

| Item | Status dan bukti |
| --- | --- |
| R-02, tanda baca | PASS: pencarian source dan copy tidak menemukan em dash. |
| R-03, overflow | PASS: render window 520 × 650 dan island 336 × 38 / 480 × 178 diperiksa; teks berada dalam kontainer. Platform khusus desktop, mobile tidak berlaku. |
| R-17, statistik | PASS: satu-satunya angka produk adalah interval dan sisa waktu engine; tidak ada statistik promosi. |
| R-18, testimonial | PASS: tidak ada testimonial, avatar, atau nama pelanggan. |
| R-23, aset | PASS: tidak membuat logo, foto, atau ilustrasi; teks nama dan SF Symbol posisi duduk mendukung utilitas yang diminta. Preview merupakan render kode aplikasi sendiri. |
| R-24, navigasi | PASS: menu hanya berisi tindakan aplikasi dengan selector nyata; tidak ada tautan produk atau halaman kosong. |
| R-25, kontras teks | PASS: 13 pasangan teks custom melebihi 4,5:1 dan 3 pasangan batas kontrol custom melebihi 3:1, tercatat di contrast.txt. Kontrol native memakai rendering sistem. |
| R-26, interaksi | PASS: preset, input custom, mulai, jeda, lanjut, checkbox suara, kedua sisi island, preview, pengaturan, pengakuan pengingat, dan tunda dijalankan melalui kontrol asli. |
| R-27, state | PASS: state awal, berjalan, jeda, pengingat, preview, dan input invalid memiliki label nyata; render awal, jeda, dan invalid disimpan. Tidak ada proses pemuatan asinkron atau sumber data jaringan. |
| R-28, FAQ | PASS: tidak ada FAQ. |
| R-32, keyboard | PASS: Tab antar preset, dari editor menit ke checkbox lalu aksi utama diuji; Enter memicu aksi utama; Escape menutup preview/pengaturan dan menunda pengingat. Focus ring native dipertahankan. |
| R-33, perubahan source | PASS: implementasi ditulis di file Swift dengan patch source; tidak ada injeksi runtime atau script pengubah source. |
| R-34, tema | PASS: kedua appearance dirender dan diperiksa; tombol serta permukaan custom menggambar ulang saat appearance berubah. |
| R-35, eksekusi | PASS: build debug/release serta 57 pemeriksaan kontrol AppKit di luar layar selesai. Batas pemeriksaan desktop fisik tercatat di bawah. |
| R-36, klaim | PASS: tidak ada klaim keamanan, kepatuhan, performa, diagnosis, atau hasil kesehatan. |
| R-37, arah | PASS: brief pengguna meminta utilitas island MacBook; Design Read serta ENERGY 1 / RHYTHM 1 / MOTION 2 dinyatakan sebelum UI dibuat. |
| R-38, keaslian | PASS: timer dan state berasal dari engine; preview berlabel sebagai preview; tidak ada konten promosi atau data aktivitas buatan. |

## Purpose Gate

| Item | Status dan bukti |
| --- | --- |
| R-01, gradient | PASS: tidak memakai gradient atau glow. |
| R-04, ikon | PASS: satu SF Symbol `figure.seated.side` menandai utilitas posisi duduk; relevansi tercatat di design-notes.md. |
| R-06, tipografi | PASS: system font mengikuti utilitas native macOS; digit timer tetap lebar untuk menghindari pergeseran antar detik. |
| R-07, latar | PASS: permukaan solid tanpa grid atau pola dekoratif. |
| R-08, panah | PASS: tidak ada panah dekoratif pada tombol. |
| R-09, badge | PASS: tidak ada badge promosi. |
| R-10, glass | PASS: tidak memakai glassmorphism. |
| R-12, shadow | PASS: tidak menambahkan shadow komponen; island secara eksplisit tanpa shadow. |
| R-13, glow | PASS: tidak memakai glow atau pulse. |
| R-14, kartu | PASS: hanya panel timer untuk mengelompokkan countdown dan state; tidak ada grid kartu fitur. |
| R-19, gerakan | PASS: animasi 0,22 detik hanya untuk perubahan ukuran island; kondisi Reduce Motion menonaktifkannya. Jalur animasi fisik belum diuji di lingkungan tanpa layar. |
| R-22, ilustrasi | PASS: tidak ada ilustrasi generik. |

## Liveliness

| Item | Status dan bukti |
| --- | --- |
| Dials | PASS: ENERGY 1 / RHYTHM 1 / MOTION 2 tercatat dalam design-notes.md. |
| Konsistensi | PASS: utilitas satu kolom dengan perpindahan ukuran island; tidak ada gerakan dekoratif. |
| Fokus | PASS: countdown menjadi fokus pengaturan; kalimat pengingat menjadi fokus island terbuka. |
| Ruang | PASS: margin 32 poin dan jarak bagian memisahkan countdown, interval, dan aksi. |
| Aksen | PASS: satu keluarga oranye menandai aksi utama; bagian lain netral. |
| Motif | PASS: area tengah atas island dikosongkan untuk notch dan diapit nama/status; pola ini bertahan pada state kecil dan terbuka. |
| Design Read | PASS: dinyatakan sebelum implementasi dan disimpan di design-notes.md. |

## Craftsmanship dan Quality Locks

| Item | Status dan bukti |
| --- | --- |
| C-1, intentionality | PASS: alasan warna, bentuk, font, layout, jarak, ikon, dan motion tertulis. |
| C-2, kelengkapan | PASS: tindakan kontrol dijalankan di smoke test; tidak ada tombol placeholder. |
| C-3, komposisi | PASS: hanya countdown, interval, suara, dan aksi yang diperlukan oleh pengingat. |
| C-4, ketahanan | PASS dalam cakupan lokal: input invalid ditolak, preview tidak mengubah deadline, jeda mempertahankan waktu, dua appearance dan fokus diuji. Integrasi desktop fisik memerlukan pemeriksaan tambahan. |
| C-5, bukti | PASS: setiap state/countdown berasal dari engine dan laporan tes berasal dari eksekusi. |
| R-05, struktur | PASS: utilitas satu kolom; tidak memakai struktur landing page, sidebar, grafik, atau statistik dekoratif. |
| R-11, radius | PASS: panel timer 16 poin, tombol 8 poin, kontur bawah island sampai 24 poin sesuai fungsi. |
| R-15, CTA | PASS: label konkret seperti Mulai pengingat, Coba pengingat, dan Tunda 5 menit. |
| R-16, bahasa | PASS: copy menerangkan tindakan aktual, tanpa klaim marketing generik. |
| R-20, identitas | PASS: area kamera yang dikosongkan, countdown dua sisi, dan pesan postur membentuk utilitas khusus notch. |
| R-21, tema | PASS: pengaturan mengikuti pilihan tema macOS; island hitam punya alasan menyatu dengan notch fisik. |
| R-29, palet | PASS: netral dengan satu keluarga aksen oranye; tidak ada rangkaian warna dekoratif. |
| R-30, referensi | PASS: pola island mengikuti permintaan pengguna; tidak menyalin aplikasi pihak ketiga. |
| R-31, alasan | PASS: keputusan utama dan alasan satu baris tersedia di design-notes.md. |

## Batas pemeriksaan

Lingkungan ini melaporkan nol layar fisik. Smoke test memakai window AppKit di luar layar dan geometri virtual; menu bar sistem tidak dibuat pada mode ini. Karena itu pembukaan melalui Finder, menu bar fisik, deteksi notch pada hardware, Spaces, fullscreen, Reduce Motion aktual, dan keluaran suara belum diverifikasi langsung. Aplikasi bukan detektor postur, tidak memakai kamera, dan belum dinotarisasi untuk distribusi publik.

Build universal dan paket DMG preview kemudian ditambahkan tanpa mengubah UI. Hasil pemeriksaan packaging, termasuk batas verifikasi rilis publik, tercatat dalam [distribution-check.md](distribution-check.md).

Pemeriksaan refactor MVVM, batas dependensi, dan kesamaan render tercatat dalam [mvvm-check.md](mvvm-check.md). Semua aturan visual di atas tetap memakai desain yang sama.
