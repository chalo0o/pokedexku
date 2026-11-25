# Perubahan UTS → UAS — Pokédexku

## Ringkasan
Project UAS dilanjutkan dari project UTS **Pokédexku** (Flutter, data dinamis dari PokéAPI). Arah aplikasi tidak diubah: tetap ensiklopedia Pokémon. Yang ditambahkan adalah **Pohon Evolusi**, **Tantangan Tebak Evolusi**, penyimpanan skor lokal, dan notifikasi.

## Tabel perubahan

| Aspek | UTS | UAS |
|---|---|---|
| Jumlah halaman | 2: Beranda, Pokédex | 4: Beranda, Pokédex, Evolusi, Tantangan |
| Sumber data | PokéAPI (`/pokemon`, `/pokemon/{id}`, `/type/{nama}`) | Tetap PokéAPI + `/pokemon-species/{id}` dan `/evolution-chain/{id}` |
| Interaksi utama | Cari & lihat Pokémon | + lihat rantai evolusi, + kuis tebak evolusi, + skor/streak |
| Penyimpanan | Tidak ada | `shared_preferences`: skor sesi, best score, streak, best streak, preferensi notifikasi |
| Notifikasi | Tidak ada | Pengingat harian jam 19.00 + notifikasi hasil kuis (SnackBar sebagai fallback) |
| Teks UI | Indonesia | Indonesia |

## Fitur baru

### 1. Halaman Evolusi
- Input nama/nomor Pokémon, lalu aplikasi mengambil species & evolution chain dari PokéAPI.
- Menampilkan tiap tahap evolusi dalam kartu: gambar official artwork, nomor, nama, dan tipe.
- Mendukung Pokémon tanpa evolusi (1 kartu) maupun cabang evolusi (mis. Eevee → Vaporeon/Jolteon/Flareon).
- Menampilkan genus dan flavor text bahasa Inggris dari PokéAPI.

### 2. Halaman Tantangan
- Mengambil daftar Pokémon acak dari PokéAPI, lalu memilih satu rantai evolusi yang bisa dibuat soal.
- Soal: "Siapa evolusi berikutnya dari ...?" dengan 4 pilihan unik.
- Jawaban benar menaikkan skor & streak; jawaban salah mereset streak.
- Skor sesi direset saat halaman Tantangan dibuka; skor terbaik dan streak terbaik tetap tersimpan di perangkat setelah aplikasi ditutup.
- Pengganggu soal diambil secara acak; cabang evolusi yang ambigu (mis. Eevee) tidak dipakai sebagai soal.
- Gagal memuat data menampilkan pesan kesalahan yang ramah dan tombol "Coba lagi".
- Interaktif: opsi berubah warna (hijau untuk jawaban benar, merah untuk opsi salah yang dipilih), sprite jawaban muncul dengan animasi fade + scale, dan meter streak 5 titik mengikuti jawaban.
- Setelah menjawab, soal berikutnya dimuat otomatis dalam 2 detik; tombol "Soal berikutnya" tetap bisa dipakai untuk lanjut lebih cepat dan membatalkan timer.

### 3. Notifikasi
- Izin notifikasi diminta sekali saat aplikasi dibuka.
- Pengingat harian dijadwalkan tepat jam 19.00 waktu perangkat (`zonedSchedule` + `matchDateTimeComponents.time`), bukan sekadar 24 jam setelah aplikasi dibuka.
- Receivers penjadwal dan izin `RECEIVE_BOOT_COMPLETED` dideklarasikan di `AndroidManifest.xml` agar alarm tetap hidup setelah reboot.
- Hasil kuis memunculkan notifikasi lokal; bila izin ditolak, toggle tetap mati dan aplikasi menampilkan `SnackBar`.

## File baru
- `lib/models/evolution_model.dart`
- `lib/services/evolution_api_service.dart`
- `lib/services/quiz_engine.dart`
- `lib/services/game_storage.dart`
- `lib/services/notification_service.dart`
- `lib/pages/evolution_page.dart`
- `lib/pages/quiz_page.dart`
- `lib/widgets/evolution_node_card.dart`
- `docs/UAS_DESIGN.md`
- `docs/superpowers/plans/2026-11-25-uas-evolusi-kuis.md`
- Test: `test/game_storage_test.dart`, `test/evolution_api_service_test.dart`, `test/quiz_engine_test.dart`, `test/evolution_page_test.dart`, `test/quiz_page_test.dart`

## File yang diubah
- `pubspec.yaml` / `pubspec.lock` — tambah `shared_preferences`, `flutter_local_notifications`, dan `timezone` (diperlukan penjadwalan jam 19.00).
- `lib/main.dart` — 4 tab, inisialisasi storage & notifikasi, wiring halaman Tantangan, client API dibuat sekali.
- `android/app/build.gradle.kts` — aktifkan core library desugaring & `desugar_jdk_libs:2.1.4` (wajib untuk `flutter_local_notifications`).
- `android/app/src/main/AndroidManifest.xml` — izin `RECEIVE_BOOT_COMPLETED` + `ScheduledNotificationReceiver` & `ScheduledNotificationBootReceiver` (wajib agar alarm terjadwal benar-benar berjalan).
- `macos/Flutter/GeneratedPluginRegistrant.swift`, `windows/flutter/generated_plugins.cmake` — regenerate otomatis oleh Flutter saat `pub get`/build.
- `test/widget_test.dart` — disesuaikan dengan konstruktor `PokedexApp` yang sekarang butuh storage & notifier.
- 17 file Dart lain — format ulang dengan Dart 3.13.2 (tanpa perubahan logika), plus kurung kurawal pada 4 `if` di `pokemon_api_service.dart` agar lint bersih.

## Catatan untuk laporan dosen
- Sesuai ketentuan UAS: dilanjutkan dari UTS, data tetap dinamis, minimal ada 2 halaman (sekarang 4), ditambah informasi/fitur/notifikasi.
- Perubahan difokuskan pada Pokédex, tidak melenceng ke contoh jadwal sholat/cuaca yang disebut dosen.

## Bukti verifikasi
- `dart format --output=none --set-exit-if-changed lib test` → exit 0, 0 file berubah.
- `flutter analyze` → **No issues found!** (exit 0).
- `flutter test` → **All tests passed** (37 test, exit 0).
- `flutter build apk --debug` → `build/app/outputs/flutter-apk/app-debug.apk` (exit 0).
- `flutter build web --release` → `build/web` (exit 0).
- Manifest hasil build (`build/app/intermediates/merged_manifests/debug/processDebugManifest/AndroidManifest.xml`) memuat `RECEIVE_BOOT_COMPLETED`, `ScheduledNotificationReceiver`, dan `ScheduledNotificationBootReceiver`.
- Cek data langsung ke PokéAPI: `/evolution-chain/2` → `charmander → charmeleon → charizard`; `/evolution-chain/77` → `mewtwo` (1 node, tanpa evolusi).

Catatan: build APK awalnya gagal karena AAR `flutter_local_notifications` meminta core library desugaring; setelah konfigurasi Gradle ditambahkan, build sukses. Review pasca-implementasi juga menemukan bahwa `periodicallyShow` tidak benar-benar berjalan tanpa receivers dan tidak menjamin jam 19.00; keduanya sudah diperbaiki dengan `zonedSchedule` + deklarasi manifest.
