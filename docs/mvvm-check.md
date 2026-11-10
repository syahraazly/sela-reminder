# Pemeriksaan refactor MVVM

- PASS: `AppDelegate` berkurang dari 473 menjadi 32 baris dan hanya menangani launch, reopen, serta termination.
- PASS: Model dan ViewModel berada dalam target `TegakCore` tanpa import AppKit. Deadline tetap milik `ReminderEngine`; format countdown dan teks UI pindah ke `ReminderViewModel`.
- PASS: View menerima `SettingsViewState` / `IslandViewState` dan tidak mengakses Model atau UserDefaults. Controller meneruskan event native ke ViewModel.
- PASS: preferensi diinjeksi melalui `ReminderPreferencesStore`. Implementasi produksi memakai UserDefaults, sedangkan tes ViewModel memakai penyimpanan dalam memori.
- PASS: timer sistem, wake, perubahan layar, dan suara dipisahkan ke `MacOSReminderService`; pembaruan tampilan dihubungkan oleh `AppCoordinator`.
- PASS: seluruh 8 tes engine lama tetap lulus, dan 10 tes ViewModel baru lulus menggunakan `zsh scripts/test.sh`.
- PASS: 57 pemeriksaan UI lama tetap lulus melalui controller, ViewModel, dan coordinator hasil refactor. Smoke test memakai jam yang diinjeksi tanpa mengganti Model ketika sedang berjalan.
- PASS: delapan file PNG render pengaturan/island identik byte demi byte dengan baseline sebelum refactor, mencakup kedua tema, state awal, input invalid, jeda, island kecil, preview, dan pengingat asli.
- PASS: build universal arm64/x86_64 dan pembuatan DMG preview selesai; tanda tangan ad hoc aplikasi serta checksum DMG valid.
- PASS: executable release universal yang sama dengan paket distribusi lulus 57 pemeriksaan AppKit ketika dijalankan di luar bundle pada host arm64.
- PASS: sumber, petunjuk arsitektur, dan laporan pemeriksaan diperbarui mengikuti struktur folder baru. Aturan antislop tetap merujuk [delivery-check.md](delivery-check.md); tidak ada perubahan warna, layout, copy produk, atau aset visual.

Panduan struktur dan alur data tersedia di [architecture.md](architecture.md). Pembukaan bundle lewat Finder, hardware Intel, notch fisik, suara, Spaces/fullscreen, serta notarization publik tetap berada di luar cakupan lingkungan tanpa layar dan sertifikat Developer ID ini.
