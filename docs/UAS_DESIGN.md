# Design Doc — Lanjutan UAS Pokédexku

## Tujuan
Melanjutkan project UTS (Pokédexku) tanpa mengubah arah aplikasi. Data tetap **dinamis dari PokéAPI**. UAS menambahkan:

1. Halaman **Evolusi** — pohon evolusi Pokémon dari data PokéAPI.
2. Halaman **Tantangan** — kuis tebak evolusi berikutnya dengan skor yang tersimpan.
3. **Notifikasi** harian + notifikasi hasil kuis di dalam aplikasi.
4. Bagian laporan **perubahan UTS → UAS**.

## Perubahan dari UTS
| Aspek | UTS | UAS |
|---|---|---|
| Halaman | 2 (Beranda, Pokédex) | 4 (Beranda, Pokédex, Evolusi, Tantangan) |
| Data | PokéAPI: list, pencarian, detail | Tetap PokéAPI + endpoint `pokemon-species` & `evolution-chain` |
| Interaksi | Lihat & cari Pokémon | + lihat rantai evolusi, + kuis, + skor tersimpan |
| Notifikasi | Tidak ada | Pengingat harian + hasil kuis |
| Penyimpanan | Tidak ada | `shared_preferences` untuk skor/streak & pengaturan notifikasi |

## Arsitektur (file baru)
- `lib/models/evolution_model.dart` — `EvolutionNode`, `EvolutionChainInfo`, `SpeciesInfo`.
- `lib/services/evolution_api_service.dart` — fetch species + evolution chain + sprite tiap tahap.
- `lib/pages/evolution_page.dart` — tab Evolusi: input nama/nomor, tampilkan pohon vertikal, detail species.
- `lib/pages/quiz_page.dart` — tab Tantangan: 1 soal acak per sesi, 4 pilihan, skor, streak, umpan balik.
- `lib/services/game_storage.dart` — simpan skor, streak, dan preferensi notifikasi (`shared_preferences`).
- `lib/services/notification_service.dart` — inisialisasi + jadwalkan pengingat harian (`flutter_local_notifications`).
- `lib/widgets/evolution_node_card.dart` — kartu tahap evolusi (gambar, nama, nomor, tipe, panah).
- Ubah `lib/main.dart` — `BottomNavigationBar` jadi 4 tab + inisialisasi notifikasi.
- Ubah `pubspec.yaml` — tambah `shared_preferences`, `flutter_local_notifications`.

## Sumber data (PokéAPI, tanpa API key)
- `GET /pokemon-species/{nameOrId}` → `evolution_chain.url`, `flavor_text_entries`, `genera`, `is_legendary`.
- `GET /evolution-chain/{id}` → rantai `chain` bersarang (`evolves_to`).
- `GET /pokemon/{name}` → sprite & tipe untuk tiap tahap (di-cache di memori).
- Kuis memakai `PokemonApiService.fetchPage()` untuk daftar nama acak, lalu ambil rantai evolusi untuk membuat pertanyaan "Siapa evolusi berikutnya dari X?" dengan 4 opsi.

## Perilaku kuis
- 1 soal per sesi, tombol "Soal berikutnya" mengambil data baru.
- Jawaban benar → +1 skor, +1 streak; salah → streak reset, tetap tampilkan jawaban benar.
- Skor & streak tertinggi disimpan lokal dan ditampilkan di header halaman Tantangan.
- Notifikasi lokal muncul saat kuis selesai/salah (−) dan saat pengingat harian.

## Notifikasi
- Izin notifikasi diminta sekali saat app pertama dibuka (Android 13+).
- Pengingat harian dijam 19.00: "Yuk lanjut jelajah Pokédexku hari ini!"
- Pengaturan on/off ada di halaman Tantangan.
- Fallback: `SnackBar` tetap dipakai kalau izin notifikasi ditolak.

## Non-goal
- Tidak menambah lokasi/cuaca (itu cuma contoh dosen).
- Tidak mengganti tema/warna UTS.
- Tidak mengubah logika halaman Beranda & Pokédex kecuali necessary wiring tab.

## Validasi
- `dart format --output=none --set-exit-if-changed lib test`
- `flutter analyze`
- `flutter test`
- `flutter build apk --debug`
- `flutter build web --release`
- Cek manual: cari "charmander" → pohon Charmander → Charmeleon → Charizard; kuis jawab benar/salah; skor tetap setelah restart.
- Tulis ringkasan perubahan UTS → UAS ke `docs/UAS_CHANGES.md` untuk laporan.
