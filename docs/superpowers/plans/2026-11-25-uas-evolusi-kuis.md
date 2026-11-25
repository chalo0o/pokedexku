# Evolusi & Tebak Evolusi Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Melanjutkan UTS Pokédexku dengan 2 halaman baru — pohon evolusi dinamis dari PokéAPI dan kuis tebak evolusi dengan skor tersimpan — plus notifikasi dan catatan perubahan UTS → UAS.

**Architecture:** Data tetap diambil dari PokéAPI lewat service baru `EvolutionApiService`; model `EvolutionNode` dipakai bareng halaman Evolusi dan mesin kuis. `GameStorage` (`shared_preferences`) menyimpan skor/streak/preferensi notifikasi, dan `NotificationService` membungkus `flutter_local_notifications` di balik abstraksi `Notifier` supaya bisa di-test.

**Tech Stack:** Flutter 3.47.2 / Dart 3.13.2, `http`, `google_fonts`, `shared_preferences`, `flutter_local_notifications`.

**Spec:** `docs/UAS_DESIGN.md`

## Global Constraints

- SDK wajib: `D:\flutter-sdk\bin\flutter.bat` (Flutter 3.47.2 / Dart 3.13.2). Jangan pakai `D:\flutter` (Dart 3.9.2, tidak cocok).
- Sumber data hanya PokéAPI, tanpa API key.
- Dilarang menambah fitur lokasi/cuaca — itu cuma contoh dosen.
- Tema/warna UTS tetap memakai `AppColors` & `AppRadius` di `lib/utils/constants.dart`.
- Semua teks UI berbahasa Indonesia.
- `dart format --output=none --set-exit-if-changed lib test` harus exit 0; `flutter analyze` harus "No issues found!".
- Commit ditunda sampai iChal menyetujui; jangan `git commit` otomatis.
- Perubahan format Dart 3.13 yang sudah ada di working tree tidak boleh di-revert.

## Review Focus

- **Pokémon tanpa evolusi** (mis. Mewtwo) → halaman Evolusi tetap menampilkan 1 node dan kuis tidak crash. Di-test di Task 2 (`parseChain single-node`) dan Task 3 (`buildQuestion returns null`).
- **Pohon bercabang** (mis. Eevee) → `evolvesTo` harus list, bukan node tunggal, dan UI merender semua cabang. Di-test di Task 2 (`parseChain branching`) dan Task 4 (widget test cabang).
- **Jawaban kuis duplikat/kurang dari 4 opsi unik** → opsi harus unik, memuat jawaban benar, dan kuis return `null` kalau tidak cukup. Di-test di Task 3.
- **Skor/streak hilang setelah restart** → harus persist lewat `shared_preferences`. Di-test di Task 1 (`reload instance`).
- **Izin notifikasi ditolak** → aplikasi tetap jalan, pakai `SnackBar` fallback, dan toggle mati. Di-test di Task 5 (fake `Notifier` mencatat `initialize()` false → toggle mati).

---

### Task 1: Dependency & GameStorage

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/services/game_storage.dart`
- Test: `test/game_storage_test.dart`

**Interfaces:**
- Consumes: `shared_preferences` package.
- Produces: `class GameStorage` dengan `Future<void> init()`, `int get score`, `int get bestScore`, `int get streak`, `int get bestStreak`, `bool get notificationsEnabled`, `Future<void> recordAnswer({required bool correct})`, `Future<void> resetSession()`, `Future<void> setNotificationsEnabled(bool value)`.

- [ ] **Step 1: Tambah dependency**

Di `pubspec.yaml` bagian `dependencies`, tambahkan `shared_preferences: ^2.5.3` dan `flutter_local_notifications: ^19.0.0` (versi disesuaikan dengan yang tersedia saat `flutter pub get`, tapi jangan mengubah constraintexisting). Jalankan `flutter pub get`.

- [ ] **Step 2: Tulis test gagal**

```dart
test('skor dan streak tersimpan setelah instance baru', () async {
  SharedPreferences.setMockInitialValues({});
  final storage = GameStorage();
  await storage.init();
  await storage.recordAnswer(correct: true);
  await storage.recordAnswer(correct: true);
  await storage.recordAnswer(correct: false);

  expect(storage.score, 2);
  expect(storage.bestScore, 2);
  expect(storage.streak, 0);
  expect(storage.bestStreak, 2);

  final reloaded = GameStorage();
  await reloaded.init();
  expect(reloaded.bestScore, 2);
  expect(reloaded.bestStreak, 2);
});
```

Tambah test `toggle notifikasi tersimpan` yang memanggil `setNotificationsEnabled(false)` lalu cek instance baru bernilai false.

- [ ] **Step 3: Jalankan test, pastikan gagal**

Run: `flutter test test/game_storage_test.dart` — expected FAIL (class belum ada).

- [ ] **Step 4: Implementasi `GameStorage`**

Pakai key: `uas_score`, `uas_best_score`, `uas_streak`, `uas_best_streak`, `uas_notifications`. `recordAnswer` menaikkan `score` & `streak` jika benar, reset `streak` jika salah, dan selalu update `bestScore`/`bestStreak`. `resetSession` hanya mengembalikan `score` & `streak` ke 0.

- [ ] **Step 5: Jalankan test, pastikan lolos**

Run: `flutter test test/game_storage_test.dart` — expected PASS.

---

### Task 2: Model & EvolutionApiService

**Files:**
- Create: `lib/models/evolution_model.dart`
- Create: `lib/services/evolution_api_service.dart`
- Test: `test/evolution_api_service_test.dart`

**Interfaces:**
- Consumes: `http`, `lib/models/evolution_model.dart`.
- Produces:
  - `EvolutionNode({required String name, required int id, String? imageUrl, List<String> types = const [], List<EvolutionNode> evolvesTo = const []})` dengan getter `List<EvolutionNode> get linearStages`.
  - `EvolutionChainInfo({required EvolutionNode root, String? flavorText})`.
  - `SpeciesInfo({required String name, required int id, required int chainId, String? flavorText, String? genus})`.
  - `EvolutionApiService({http.Client? client})` dengan `Future<SpeciesInfo> fetchSpecies(String nameOrId)`, `Future<EvolutionChainInfo> fetchChain(int chainId)`, `Future<({String? imageUrl, List<String> types})> fetchPokemonPreview(String name)`.
  - Static parser: `EvolutionApiService.parseSpecies(Map<String, dynamic>)`, `EvolutionApiService.parseChain(Map<String, dynamic>)`, `EvolutionApiService.idFromUrl(String)`, `EvolutionApiService.parseTypes(Map<String, dynamic>)`.

- [ ] **Step 1: Tulis test gagal untuk parser**

```dart
test('parseChain mengikuti rantai charmander', () {
  final chain = EvolutionApiService.parseChain(_chainJson);
  expect(chain.root.name, 'charmander');
  expect(chain.root.evolvesTo.single.name, 'charmeleon');
  expect(chain.root.evolvesTo.single.evolvesTo.single.name, 'charizard');
  expect(chain.root.linearStages.map((e) => e.name).toList(),
      ['charmander', 'charmeleon', 'charizard']);
});
```

Tambah: `parseChain single-node` (`evolvesTo.isEmpty`, `linearStages.length == 1`), `parseChain branching` (root Eevee punya 3+ `evolvesTo`), `idFromUrl` mengembalikan `1`, `parseSpecies` mengambil `chainId`, `flavorText` bahasa Inggris, dan `genus`.

- [ ] **Step 2: Jalankan test, pastikan gagal**

Run: `flutter test test/evolution_api_service_test.dart` — expected FAIL.

- [ ] **Step 3: Implementasi model & parser**

`linearStages` = depth-first mengikuti `evolvesTo.first` saja (untuk keperluan kuis). `parseSpecies` mengambil `evolution_chain.url`, `flavor_text_entries` dengan `language.name == 'en'` (bersihkan `\n`/`\f`), dan `genera` dengan `language.name == 'en'`. `parseChain` rekursif dari `chain`. `parseTypes` mengambil `types[].type.name`.

- [ ] **Step 4: Implementasi fetch network**

Gunakan base URL `https://pokeapi.co/api/v2`. `fetchChain` memanggil `parseChain`, lalu untuk tiap node memanggil `fetchPokemonPreview` dan mengisi `imageUrl` + `types` secara rekursif. Cache preview per nama di `_previewCache` agar tidak request berulang. Lempar `ApiException` untuk status code bukan 200 (ikuti pola `PokemonApiService`).

- [ ] **Step 5: Jalankan test, pastikan lolos**

Run: `flutter test test/evolution_api_service_test.dart` — expected PASS.

---

### Task 3: QuizEngine

**Files:**
- Create: `lib/services/quiz_engine.dart`
- Test: `test/quiz_engine_test.dart`

**Interfaces:**
- Consumes: `EvolutionChainInfo` dari Task 2.
- Produces:
  - `QuizQuestion({required String prompt, required String correctAnswer, required List<String> options})`.
  - `QuizEngine({required EvolutionChainInfo chain, required List<String> randomNames, Random? random})` dengan `QuizQuestion? buildQuestion()` dan `bool isCorrect(String answer, QuizQuestion question)`.

- [ ] **Step 1: Tulis test gagal**

```dart
test('buildQuestion menyusun 4 opsi unik berisi jawaban benar', () {
  final engine = QuizEngine(
    chain: _chain('charmander', 'charmeleon'),
    randomNames: ['pikachu', 'bulbasaur', 'squirtle', 'eevee', 'charizard'],
  );
  final q = engine.buildQuestion()!;
  expect(q.prompt, contains('charmander'));
  expect(q.correctAnswer, 'charmeleon');
  expect(q.options, contains('charmeleon'));
  expect(q.options.length, 4);
  expect(q.options.toSet().length, 4);
  expect(engine.isCorrect('charmeleon', q), true);
  expect(engine.isCorrect('pikachu', q), false);
});
```

Tambah test `single-node chain -> null`, dan `randomNames` dengan duplikat tetap menghasilkan 4 opsi unik bila cukup nama.

- [ ] **Step 2: Jalankan test, pastikan gagal**

Run: `flutter test test/quiz_engine_test.dart` — expected FAIL.

- [ ] **Step 3: Implementasi `QuizEngine`**

Kumpulkan semua node yang punya `evolvesTo.isNotEmpty`, pilih satu secara acak. Jawaban benar = `node.evolvesTo.first.name`. Opsi = jawaban benar + 3 nama unik dari `randomNames` (buang duplikat & jawaban benar), lalu shuffle.Kalau kurang dari 4 opsi unik, return `null`. `isCorrect` membandingkan huruf kecil.

- [ ] **Step 4: Jalankan test, pastikan lolos**

Run: `flutter test test/quiz_engine_test.dart` — expected PASS.

---

### Task 4: Halaman Evolusi & wiring tab

**Files:**
- Create: `lib/widgets/evolution_node_card.dart`
- Create: `lib/pages/evolution_page.dart`
- Modify: `lib/main.dart`
- Test: `test/evolution_page_test.dart`

**Interfaces:**
- Consumes: `EvolutionApiService`, `EvolutionNode`, `LoadingView`, `ErrorView`, `AppHeader`, `GoogleFonts`.
- Produces:
  - `EvolutionNodeCard({required EvolutionNode node, int depth = 0})` — kartu stateless dengan gambar, `#id`, nama, badge tipe, dan indentasi `depth * 16`.
  - `EvolutionPage({EvolutionApiService? service})` — stateful; field search, tombol "Cari", `FutureBuilder<EvolutionChainInfo>`, render tiap node rekursif.

- [ ] **Step 1: Tulis widget test gagal**

```dart
testWidgets('menampilkan rantai evolusi charmander', (tester) async {
  final page = EvolutionPage(service: FakeEvolutionApiService());
  await tester.pumpWidget(MaterialApp(home: page));
  await tester.enterText(find.byType(TextField), 'charmander');
  await tester.tap(find.text('Cari'));
  await tester.pumpAndSettle();
  expect(find.text('charmeleon'), findsOneWidget);
  expect(find.text('charizard'), findsOneWidget);
});
```

`FakeEvolutionApiService` extends `EvolutionApiService` dan override `fetchSpecies` / `fetchChain` dengan fixture Task 2. Tambah test cabang Eevee memunculkan lebih dari satu anak.

- [ ] **Step 2: Jalankan test, pastikan gagal**

Run: `flutter test test/evolution_page_test.dart` — expected FAIL.

- [ ] **Step 3: Implementasi `EvolutionNodeCard` & `EvolutionPage`**

`EvolutionPage` memanggil `_api.fetchSpecies(query)` lalu `_api.fetchChain(species.chainId)`. Tampilkan `CircularProgressIndicator` saat loading; `ErrorView` dengan tombol retry saat error; di header tampilkan `species.genus` & `species.flavorText` kalau ada. Render node rekursif: kartu lalu child dengan `depth + 1`.

- [ ] **Step 4: Wire 4 tab di `main.dart`**

`IndexedStack` children: `[HomePage, ListPage, EvolutionPage(), QuizPage(...)]`. `BottomNavigationBar` items: Beranda, Pokédex, Evolusi, Tantangan dengan ikon `catching_pokemon`, `account_tree`, `quiz` (sesuai available icons). `QuizPage` menyusul di Task 5 — untuk sementara pakai placeholder `SizedBox.shrink()`.

- [ ] **Step 5: Jalankan test, pastikan lolos**

Run: `flutter test test/evolution_page_test.dart` — expected PASS. Lalu `flutter analyze` — expected 0 issues.

---

### Task 5: Halaman Tantangan, notifikasi, & laporan

**Files:**
- Create: `lib/services/notification_service.dart`
- Create: `lib/pages/quiz_page.dart`
- Create: `docs/UAS_CHANGES.md`
- Modify: `lib/main.dart`
- Test: `test/quiz_page_test.dart`

**Interfaces:**
- Consumes: `GameStorage` (Task 1), `QuizEngine`/`QuizQuestion` (Task 3), `EvolutionApiService` (Task 2), `PokemonApiService` (existing).
- Produces:
  - `abstract class Notifier { Future<bool> initialize(); Future<void> scheduleDailyReminder({required bool enabled}); Future<void> showQuizResult({required bool correct}); }`
  - `class NotificationService implements Notifier` — membungkus plugin; `initialize()` minta izin dan return `false` kalau ditolak.
  - `QuizPage({required GameStorage storage, required PokemonApiService listApi, required EvolutionApiService api, Notifier? notifier, Random? random})`.

- [ ] **Step 1: Tulis widget test gagal**

```dart
testWidgets('jawaban benar menaikkan skor dan memanggil notifier', (tester) async {
  final storage = GameStorage();
  await storage.init();
  final notifier = FakeNotifier();
  await tester.pumpWidget(MaterialApp(
    home: QuizPage(
      storage: storage,
      listApi: FakePokemonApiService(),
      api: FakeEvolutionApiService(),
      notifier: notifier,
      random: Random(1),
    ),
  ));
  await tester.pumpAndSettle();
  await tester.tap(find.text('charmeleon'));
  await tester.pumpAndSettle();
  expect(find.textContaining('Skor: 1'), findsOneWidget);
  expect(notifier.results.last, true);
});
```

Tambah test toggle notifikasi memanggil `setNotificationsEnabled(false)` dan `scheduleDailyReminder(enabled: false)`, serta test `initialize()` false membuat toggle mati.

- [ ] **Step 2: Jalankan test, pastikan gagal**

Run: `flutter test test/quiz_page_test.dart` — expected FAIL.

- [ ] **Step 3: Implementasi `NotificationService`**

Init plugin, minta izin notifikasi (Android 13+), jadwalkan harian jam 19.00 via `zonedSchedule` atau `periodicallyShow` (pilih yang paling sederhana dan kompatibel). Kalau `initialize()` false, jangan jadwalkan; `QuizPage` tetap pakai `SnackBar`.

- [ ] **Step 4: Implementasi `QuizPage`**

Saat init, ambil daftar nama via `listApi.fetchPage(limit: 100)` (`PokemonApiService` yang sudah ada), pilih beberapa nama acak, untuk masing-masing panggil `api.fetchSpecies` + `api.fetchChain` sampai dapat chain dengan evolusi (maksimal 5 percobaan), lalu bangun `QuizEngine`. Tampilkan skor/streak/best, prompt, 4 tombol opsi. Setelah jawab: panggil `storage.recordAnswer`, `notifier.showQuizResult`, tampilkan `SnackBar` benar/salah + jawaban benar. Tombol "Soal berikutnya" reset & bangun soal baru. Toggle notifikasi tersimpan di `GameStorage`.

- [ ] **Step 5: Ganti placeholder di `main.dart` dengan `QuizPage` asli**

Di `main()`: `WidgetsFlutterBinding.ensureInitialized()`, `final storage = GameStorage(); await storage.init(); final notifier = NotificationService(); await notifier.initialize();` lalu teruskan ke `QuizPage`.

- [ ] **Step 6: Tulis laporan perubahan**

`docs/UAS_CHANGES.md`: tabel UTS → UAS (halaman 2→4, data PokéAPI → + species/evolution-chain, interaksi, notifikasi, penyimpanan), daftar file baru, dan catatan buat laporan dosen.

- [ ] **Step 7: Jalankan test & analyze**

Run: `flutter test test/quiz_page_test.dart` lalu `flutter analyze` — expected PASS / 0 issues.

---

### Task 6: Verifikasi penuh

**Files:** tidak ada (verifikasi saja)

- [ ] **Step 1: Format**

Run: `dart format --output=none --set-exit-if-changed lib test` — expected exit 0, 0 changed.

- [ ] **Step 2: Analyze + test**

Run: `flutter analyze && flutter test` — expected "No issues found!" dan "All tests passed!".

- [ ] **Step 3: Build**

Run: `flutter build apk --debug` dan `flutter build web --release` — expected keduanya exit 0.

- [ ] **Step 4: Cek manual (dokumentasikan di laporan)**

Cari `charmander` → Charmander → Charmeleon → Charizard; cari `mewtwo` → tetap 1 node; buka Tantangan → jawab benar & salah → skor/streak berubah → restart app → best score tetap; toggle notifikasi mati → tidak ada jadwal.

- [ ] **Step 5: Git status**

Run: `git status --short` — expected hanya file-file UAS + format yang sudah disetujui; tidak ada commit otomatis.
