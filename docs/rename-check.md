# Pemeriksaan nama Sela dan contoh pengingat

- PASS: nama Sela dipakai oleh window, island, tooltip, label aksesibilitas, menu keluar, executable, Info.plist, launcher, README, dan nama DMG.
- PASS: target dan folder source menjadi `Sela` / `SelaCore` / `SelaCoreTests`; Model dan ViewModel tetap tidak mengimpor AppKit. Nama pada UI bersumber dari `AppIdentity.name`.
- PASS: contoh pengingat menampilkan pesan aslinya serta tombol Tutup contoh. Kalimat lama tentang jadwal dihapus, termasuk pada saat timer belum dimulai atau dijeda.
- PASS: 25 tes unit lulus, termasuk verifikasi contoh kedua jenis pada state idle dan paused; contoh tidak memulai timer atau mengubah sisa waktunya.
- PASS: 77 pemeriksaan kontrol AppKit lulus, termasuk judul window, label island, menu Keluar dari Sela, dan teks contoh duduk/minum.
- PASS: render pengaturan kedua tema, contoh duduk, serta contoh minum diperiksa. Warna, ukuran window, navigasi keyboard, dan posisi terhadap area kamera tetap menggunakan pola yang sudah diverifikasi.
- PASS: bundle identifier bawaan masih `local.dummy.tegak`, sama dengan versi sebelumnya, sehingga domain UserDefaults serta key jenis/interval/suara tetap sama. Identitas teknis lama ini tidak ditampilkan di UI.
- PASS: script menerima variabel `SELA_` dan fallback `TEGAK_`; preflight rilis publik tetap menolak sertifikat yang belum diisi sebelum upload notarization.
- PASS: build universal Sela.app dan Sela-0.1.0-universal-preview.dmg selesai; signature ad hoc, checksum internal image, dan SHA-256 valid.
- PASS: executable release universal lulus 77 pemeriksaan AppKit di luar bundle pada host arm64. Pembacaan ulang image memverifikasi executable serta Info.plist identik, katalog berisi Sela.app, dan petunjuk instalasi memakai nama baru.

Bukti: [contoh duduk](previews/island-preview.png), [contoh minum](previews/island-water-preview.png), [pengaturan](previews/settings-water-light.png), dan [rekaman interaksi](previews/smoke-test.txt). Gate antislop lengkap tetap tercatat di [delivery-check.md](delivery-check.md).

Batas: tidak ada layar fisik atau sertifikat Developer ID di lingkungan ini. Instalasi dari Finder, suara aktual, hardware Intel, notch/fullscreen/Spaces, serta notarization publik tetap belum diverifikasi secara langsung. Pengguna perlu keluar dari versi Tegak yang masih berjalan sebelum membuka Sela.
