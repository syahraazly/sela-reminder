# Pemeriksaan pilihan jenis pengingat

Satu jenis pengingat aktif pada satu waktu: Duduk tegak atau Minum air putih. Interval dan sisa waktu dipertahankan saat jenis diganti. Preferensi lama tanpa jenis memakai Duduk tegak.

- PASS: 24 tes unit lulus, termasuk pemulihan pilihan tersimpan, fallback nilai lama/tidak dikenal, pergantian jenis saat aktif/jeda, preview minum, konfirmasi pengingat minum, serta pencegahan suara berulang saat jenis diganti.
- PASS: 71 pemeriksaan AppKit lulus melalui kontrol asli, termasuk kedua tombol jenis, penyimpanan pilihan, deadline yang tetap, preview, konfirmasi minum, serta navigasi Tab melalui pilihan jenis ke preset interval.
- PASS: ViewModel tetap tidak mengimpor AppKit; `ReminderKind` berada di Model dan teks/simbol per jenis berada di `ReminderContent` pada lapisan ViewModel.
- PASS: render pengaturan duduk/minum pada tema terang/gelap diperiksa. Window tetap 520 × 650; tombol jenis, teks status, countdown, input, dan aksi muat di kontainernya.
- PASS: teks, konfirmasi, tooltip, dan simbol menu bar berasal dari jenis aktif. `figure.seated.side` mewakili duduk dan `drop` mewakili minum; keduanya SF Symbol yang relevan.
- PASS: pilihan aktif memiliki tanda centang dan label aksesibilitas, sehingga state tidak hanya bergantung pada warna. Focus ring native serta aksi Enter/Escape dipertahankan.
- PASS: tidak menambah warna, efek, aset gambar, statistik, atau klaim kesehatan. Pasangan warna tetap menggunakan palet yang diperiksa dalam `contrast.txt`.
- PASS: build universal arm64/x86_64 serta DMG preview terbaru selesai; tanda tangan ad hoc, checksum internal DMG, dan checksum SHA-256 valid.
- PASS: salinan executable release universal di luar bundle lulus 71 pemeriksaan AppKit. Image DMG dibaca ulang untuk memastikan executable serta Info.plist identik dengan aplikasi hasil build, dan petunjuk instalasi memuat kedua pilihan.
- PASS: README dan petunjuk dalam DMG menjelaskan pemilihan jenis; arsitektur MVVM dan laporan delivery diperbarui.

Bukti visual: [minum terang](previews/settings-water-light.png), [minum gelap](previews/settings-water-dark.png), [preview minum](previews/island-water-preview.png), dan [pengingat minum](previews/island-water-reminder.png). Bukti interaksi: [smoke-test.txt](previews/smoke-test.txt). Gate desain lengkap: [delivery-check.md](delivery-check.md).

Pengujian menggunakan window AppKit di luar layar pada host arm64. Menu bar fisik, hardware Intel, suara aktual, penempatan notch, fullscreen/Spaces, dan notarization publik tetap memerlukan pemeriksaan di lingkungan yang sesuai.
