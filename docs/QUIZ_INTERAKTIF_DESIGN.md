# Desain singkat: kuis Tantangan yang lebih interaktif

## Keputusan
Sesuai pilihan iChal: **A — Feedback hidup**. Aturan skor tidak diubah, halaman lain tidak disentuh.

## Alur layar
1. Soal tampil seperti sekarang (prompt + 4 opsi + stat header).
2. Saat opsi ditekan:
   - opsi yang dipilih langsung berubah warna (hijau jika benar, merah jika salah);
   - jika salah, opsi jawaban benar ikut disorot hijau;
   - sprite jawaban benar muncul dengan animasi fade + scale singkat;
   - meter streak (5 titik) terisi sesuai `streak` saat ini, ikut reset saat jawaban salah;
   - tombol “Soal berikutnya” tetap ada untuk lanjut lebih cepat.
3. Setelah ±2 detik, soal berikutnya dimuat otomatis. Timer dibatalkan kalau tombol ditekan atau halaman ditutup.

## Data
- `QuizQuestion` mendapat field opsional `imageUrl`.
- URL sprite diambil dari `EvolutionApiService.fetchPokemonPreview(correctAnswer)` (sudah ada cache, **1 request tambahan** untuk jawaban benar). Rantai tetap `enrich: false`.
- Gagal mengambil sprite tidak menggagalkan soal: kuis tetap jalan tanpa gambar.

## Batasan (sengaja tidak dilakukan)
- Tidak ada timer/bonus poin, tidak ada drag-and-drop, tidak ada perubahan `GameStorage`.
- Tidak mengubah notifikasi, halaman Evolusi, Pokédex, atau laporan UTS→UAS selain catatan kecil di `docs/UAS_CHANGES.md`.

## Verifikasi
- Test widget baru: warna opsi benar/salah, sprite tampil, meter streak, timer lanjut otomatis, timer dibatalkan saat tombol ditekan, gagal sprite tidak menggagalkan soal.
- Test lama tetap hijau (27 test), `dart format --set-exit-if-changed`, `flutter analyze`, `flutter test`, `flutter build apk --debug`, `flutter build web --release`.
- Karena server `http://localhost:3000` menyajikan `build/web`, build ulang lalu restart server supaya iChal bisa langsung lihat.
