# Pemeriksaan paket distribusi

Paket untuk dibagikan: `dist/Sela.dmg` dan file `.sha256` di sampingnya. Salinan berversi tetap tersedia. Statusnya preview dengan tanda tangan ad hoc; belum memakai Developer ID atau notarization, dan belum diunggah sebagai unduhan publik.

- PASS: `scripts/build.sh --universal` membangun arsitektur arm64 dan x86_64; diverifikasi dengan `lipo -archs`.
- PASS: `vtool -show-build` menyatakan minimum macOS 14.0 pada kedua arsitektur.
- PASS: bundle aplikasi lolos `codesign --verify --deep --strict`; tanda tangan saat ini ad hoc.
- PASS: Info.plist lolos `plutil -lint`.
- PASS: DMG dihasilkan sebagai UDIF terkompresi dari filesystem HFS+ tanpa perlu mount saat pembuatan.
- PASS: `hdiutil verify` memverifikasi checksum internal DMG.
- PASS: `shasum -a 256 -c Sela-0.1.0-universal-preview.dmg.sha256` dari folder `dist/` memverifikasi checksum SHA-256.
- PASS: DMG dikonversi kembali ke image mentah untuk pemeriksaan baca ulang; executable dan Info.plist ditemukan dengan byte identik terhadap bundle hasil build.
- PASS: katalog HFS memuat nama Sela.app dan Applications; target `/Applications`, petunjuk instalasi, dan teks VERSI PREVIEW ditemukan dalam image baca ulang.
- PASS: salinan byte executable distribusi terbaru yang dijalankan di luar bundle lulus 77 pemeriksaan kontrol AppKit di luar layar pada host arm64, termasuk pilihan duduk/minum dan nama Sela. Lokasi di luar bundle digunakan karena peluncuran bundle melalui layanan desktop tidak tersedia di lingkungan ini.
- PASS: semua script shell lolos `zsh -n`.
- PASS: `release.sh` menolak identitas signing yang belum diisi sebelum build atau upload notarization; `package-dmg.sh --release` juga menolak identitas yang belum diisi.
- PASS: alur release menyimpan DMG yang menunggu notarization di folder staging. File final berlabel publik baru dipindahkan ke `dist/` setelah notarization, stapling, dan pemeriksaan Gatekeeper berhasil.
- PASS: petunjuk instalasi memakai langkah konkret; paket preview diberi label yang jelas. Tidak ada klaim notarization, publikasi, atau dukungan hardware yang sudah diuji jika belum dilakukan.

Belum diverifikasi: signing Developer ID, upload dan persetujuan layanan notarization Apple, tiket stapled, pemeriksaan Gatekeeper untuk hasil download, mounting/instalasi DMG di Finder, hardware Intel, notch fisik, menu bar, serta fullscreen/Spaces. Keychain yang dapat diakses pada sesi ini tidak memiliki signing identity valid, dan lingkungan tidak memiliki layar fisik. Alur yang belum dapat dijalankan ini tidak dinyatakan lulus.

Aturan desain antislop selama pembuatan tetap mengikuti [pemeriksaan UI](delivery-check.md). Perubahan packaging tidak mengubah layout atau perilaku pengingat. Untuk meneruskan rilis publik, ikuti [distribution.md](distribution.md).
