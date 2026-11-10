# Keputusan desain Tegak

Mode antislop: selama pembuatan, sesuai pilihan pengguna.

Design Read: utilitas native macOS untuk pengguna MacBook yang menginginkan pengingat duduk di area island. Bahasa visual mengikuti kebutuhan notch dan kontrol macOS. ENERGY 1 / RHYTHM 1 / MOTION 2.

- Island hitam: menyambung secara visual dengan notch fisik, dengan bagian tengah atas dikosongkan agar kamera tidak menutupi teks.
- Pengaturan netral hangat: membedakan kontrol pengaturan dari permukaan hitam island tanpa dekorasi yang mengalihkan perhatian.
- Warna mengikuti sistem: jendela pengaturan mendukung tampilan terang/gelap; island tetap hitam karena tujuannya menyatu dengan notch.
- Aksen oranye: menandai tindakan utama pengingat. Oranye gelap dipakai dengan teks putih di pengaturan; oranye terang dengan teks hitam di island untuk menjaga kontras.
- SF system font: konsisten dengan keterbacaan dan kontrol native macOS. Digit timer memakai lebar tetap agar perubahan detik tidak menggeser angka.
- Komposisi satu kolom: keputusan utama adalah kapan pengingat berbunyi, sehingga timer dan interval menjadi fokus tanpa sidebar atau statistik.
- Panel timer: satu permukaan berbeda mengelompokkan sisa waktu dengan status aktualnya. Tidak ada kartu fitur atau statistik buatan.
- Ruang 32 poin pada tepi: memisahkan pengaturan dari bingkai window; jarak antarbagian lebih besar daripada jarak label dengan kontrolnya.
- Bentuk: island berkontur bawah membulat mengikuti notch; panel timer 16 poin dan tombol 8 poin membedakan kelompok informasi dari tindakan.
- Animasi 0,22 detik: hanya saat island membuka atau menutup, untuk menjelaskan perpindahan dari countdown ke pengingat. Reduce Motion sistem menonaktifkannya.
- Ikon menu bar `figure.seated.side`: SF Symbol terkait posisi duduk, bukan logo buatan. Tidak ada foto, ilustrasi, statistik, atau testimonial.
- Tanpa ketergantungan jaringan: seluruh tampilan dan state dimuat sinkron dari memori/UserDefaults. Tidak ada loading jaringan yang perlu disimulasikan. State awal menjelaskan timer belum dimulai, dan input interval invalid memiliki pesan pemulihan.
- Batas platform: aplikasi ini khusus desktop macOS, sehingga breakpoint mobile dan keyboard layar tidak berlaku. Kontrol memakai fokus dan urutan Tab native.
- Pilihan interval: tanda centang serta label aksesibilitas menyatakan interval yang dipilih, sehingga state tidak bergantung pada warna saja.
- Render adaptif: permukaan dan tombol custom digambar ulang ketika appearance berubah. Kontrol tombol dan checkbox menerima Tab meskipun pengaturan navigasi keyboard sistem sedang mati.
