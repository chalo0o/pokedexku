# Kuis Interaktif Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Beri feedback hidup pada kuis Tantangan (warna opsi, reveal sprite beranimasi, meter streak, lanjut otomatis) tanpa mengubah aturan skor.

**Architecture:** `QuizQuestion` diperluas dengan URL sprite opsional yang diambil dari cache `fetchPokemonPreview` milik `EvolutionApiService` (1 request per soal, gagal sprite tidak menggagalkan soal). `QuizPage` menyimpan state jawaban + `Timer` auto-lanjut dan merender feedback dengan widget animasi standar Flutter.

**Tech Stack:** Flutter/Dart, google_fonts, PokéAPI via `EvolutionApiService`, `flutter_test`.

**Spec:** `docs/QUIZ_INTERAKTIF_DESIGN.md`

## Global Constraints

- Tetap Pokédexku; jangan tambah fitur di luar desain (timer poin, drag-and-drop, halaman baru).
- Skor/streak/best score tidak berubah semantically; `GameStorage` tidak diubah.
- Teks UI bahasa Indonesia; nama Pokémon memakai `titleCase` dari `lib/utils/formatters.dart`.
- Jalankan Flutter dari `D:\flutter-sdk\bin\flutter.bat`; `flutter pub get` bila perlu memakai `--no-precompile`.
- Jangan commit/push otomatis untuk perubahan ini kecuali iChal meminta.
- Server demo `http://localhost:3000` menyajikan `build/web`; setelah perubahan perlu build ulang + restart server.

## Review Focus

- Jawaban salah: opsi yang dipilih merah, opsi benar tetap hijau — diuji dengan warna `AnimatedContainer` di Task 2.
- Sprite gagal diambil: soal tetap tampil tanpa gambar — diuji `sprite gagal tidak menggagalkan soal` di Task 2.
- Timer auto-lanjut dengan halaman ditutup/soal diganti manual: tidak boleh ada fetch atau `setState` setelah dispose — diuji `tombol soal berikutnya membatalkan timer` di Task 2.
- `pumpAndSettle` pada test lama ikut menjalankan timer: test lama harus tetap hijau — dijalankan ulang di Task 2.
- Streak meter setelah jawaban salah: ikut reset mengikuti `storage.streak` — diuji teks `Streak 0/5` di Task 2.

---

### Task 1: Model soal membawa sprite jawaban

**Files:**
- Modify: `lib/services/quiz_engine.dart` (class `QuizQuestion`)
- Modify: `lib/pages/quiz_page.dart` (`_loadQuestion`)
- Test: `test/quiz_page_test.dart` (`FakeEvolutionApiService`, test sprite)

**Interfaces:**
- Consumes: `EvolutionApiService.fetchPokemonPreview(String name) -> Future<({String? imageUrl, List<String> types})>` (sudah ada, cache internal).
- Produces: `QuizQuestion.imageUrl` (`String?`, default `null`) dan `QuizQuestion.copyWith({String? imageUrl})`; `_loadQuestion` mengisi `imageUrl` dari preview jawaban benar.

- [ ] **Step 1: Tulis test gagal** di `test/quiz_page_test.dart`: override `fetchPokemonPreview` di `FakeEvolutionApiService` sehingga mengembalikan `(imageUrl: 'https://example.com/charmeleon.png', types: const ['fire'])`; tambah test `sprite jawaban benar tersedia di question` yang mengecek `find.byKey(const Key('quiz-feedback-image'))` muncul setelah menjawab dan `Image.network` memuat URL tersebut.

- [ ] **Step 2: Jalankan test, pastikan gagal**

Run: `flutter test test/quiz_page_test.dart --plain-name 'sprite jawaban benar'`
Expected: FAIL karena field/kunci belum ada.

- [ ] **Step 3: Implementasi di `lib/services/quiz_engine.dart`**

Tambahkan `final String? imageUrl` ke `QuizQuestion` (default `null` di constructor) dan `QuizQuestion copyWith({String? imageUrl})` yang mempertahankan field lain.

- [ ] **Step 4: Implementasi di `lib/pages/quiz_page.dart`**

Di `_loadQuestion`, setelah `built != null`, panggil `widget.api.fetchPokemonPreview(built.correctAnswer)` di dalam `try/catch` tersendiri; jika berhasil, `built = built.copyWith(imageUrl: preview.imageUrl)`. Jangan biarkan kegagalan preview menggagalkan soal. Beri `Key('quiz-feedback-image')` pada widget gambar di feedback.

- [ ] **Step 5: Jalankan test, pastikan lulus**

Run: `flutter test test/quiz_page_test.dart`
Expected: PASS (test baru + 5 test lama).

### Task 2: Feedback interaktif dan auto-lanjut

**Files:**
- Modify: `lib/pages/quiz_page.dart` (`_answer`, `dispose`, `_buildQuestion`, header stat)
- Modify: `docs/UAS_CHANGES.md` (catatan kecil)
- Test: `test/quiz_page_test.dart` (4 test baru)

**Interfaces:**
- Consumes: `QuizQuestion.imageUrl` dari Task 1; `GameStorage.score/streak` yang sudah ada.
- Produces: `_advanceTimer` (`Timer?`) dan widget feedback berkey `quiz-option-<nama>`, `quiz-feedback-image`, `quiz-streak-meter`.

- [ ] **Step 1: Tulis test gagal** di `test/quiz_page_test.dart` (tambah counter `fetchChainCalls` pada fake): `opsi salah berubah merah dan opsi benar hijau` (tap `Bulbasaur`, cek `AnimatedContainer` berkunci `quiz-option-charmeleon` berwarna hijau dan `quiz-option-bulbasaur` merah); `meter streak mengikuti jawaban` (cek teks `Streak 1/5` setelah benar, lalu `Streak 0/5` setelah salah di soal berikutnya); `soal lanjut otomatis setelah dua detik` (tap, `pump` 2 detik, cek `fetchChainCalls` bertambah dan teks `Kamu benar!` hilang); `tombol soal berikutnya membatalkan timer` (tap opsi lalu tap tombol, `pump` 2 detik, cek `fetchChainCalls` tidak bertambah lagi); `sprite gagal tidak menggagalkan soal` (fake melempar `ApiException`, cek prompt masih tampil).

- [ ] **Step 2: Jalankan test, pastikan gagal**

Run: `flutter test test/quiz_page_test.dart`
Expected: FAIL pada assertion warna/teks/timer.

- [ ] **Step 3: Implementasi state di `lib/pages/quiz_page.dart`**

Tambah `Timer? _advanceTimer`; di `_answer` setelah `setState`, jadwalkan `Timer(const Duration(seconds: 2), _loadQuestion)`; batalkan timer di awal `_loadQuestion` dan di `dispose`. Tombol “Soal berikutnya” memanggil `_loadQuestion` langsung.

- [ ] **Step 4: Implementasi UI di `lib/pages/quiz_page.dart`**

Ganti `OutlinedButton` opsi dengan `AnimatedContainer` (key `quiz-option-<nama>`) yang warnanya: hijau untuk jawaban benar setelah dijawab, merah untuk opsi salah yang dipilih, netral sebelum dijawab. Tambah `AnimatedSwitcher` fade+scale berisi `Image.network` dari `question.imageUrl` (key `quiz-feedback-image`) atau placeholder teks bila null. Tambah `_streakMeter()` dengan 5 titik + teks `Streak ${min(streak, 5)}/5` (key `quiz-streak-meter`).

- [ ] **Step 5: Update laporan**

Tambah satu poin di `docs/UAS_CHANGES.md` bagian kuis: feedback warna, reveal sprite, meter streak, lanjut otomatis 2 detik.

- [ ] **Step 6: Verifikasi penuh**

Run: `dart format lib test`; lalu `dart format --output=none --set-exit-if-changed lib test`; `flutter analyze`; `flutter test`; `flutter build apk --debug`; `flutter build web --release`.
Expected: format exit 0, analyze No issues, semua test PASS, kedua build exit 0.

- [ ] **Step 7: Tampilkan hasil**

Restart server statik port 3000 yang menyajikan `build/web` lalu buka `http://localhost:3000` di Chrome. Expected: HTTP 200 untuk `index.html` dan `main.dart.js`.
