import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ma_game/models/evolution_model.dart';
import 'package:ma_game/models/pokemon_model.dart';
import 'package:ma_game/pages/quiz_page.dart';
import 'package:ma_game/services/evolution_api_service.dart';
import 'package:ma_game/services/game_storage.dart';
import 'package:ma_game/services/notification_service.dart';
import 'package:ma_game/services/pokemon_api_service.dart';
import 'package:ma_game/utils/constants.dart';

class FakeNotifier implements Notifier {
  final bool initializeResult;
  final List<bool> results = [];
  final List<bool> schedules = [];

  FakeNotifier({this.initializeResult = true});

  @override
  Future<bool> initialize() async => initializeResult;

  @override
  Future<void> scheduleDailyReminder({required bool enabled}) async {
    schedules.add(enabled);
  }

  @override
  Future<void> showQuizResult({required bool correct}) async {
    results.add(correct);
  }
}

class SlowNotifier extends FakeNotifier {
  final Completer<void> gate = Completer<void>();

  @override
  Future<void> showQuizResult({required bool correct}) async {
    results.add(correct);
    await gate.future;
  }
}

class FakePokemonApiService extends PokemonApiService {
  final Object? error;

  FakePokemonApiService({this.error});

  @override
  Future<PokemonPage> fetchPage({int limit = 20, int offset = 0}) async {
    if (error != null) {
      throw error!;
    }
    return PokemonPage(
      count: 5,
      hasNext: false,
      results: [
        const PokemonSummary(id: 4, name: 'charmander'),
        const PokemonSummary(id: 25, name: 'pikachu'),
        const PokemonSummary(id: 1, name: 'bulbasaur'),
        const PokemonSummary(id: 7, name: 'squirtle'),
        const PokemonSummary(id: 133, name: 'eevee'),
      ],
    );
  }
}

class FakeEvolutionApiService extends EvolutionApiService {
  final Object? previewError;
  int fetchChainCalls = 0;

  FakeEvolutionApiService({this.previewError});

  @override
  Future<SpeciesInfo> fetchSpecies(String nameOrId) async {
    return SpeciesInfo(name: nameOrId, id: 4, chainId: 1);
  }

  @override
  Future<EvolutionChainInfo> fetchChain(
    int chainId, {
    bool enrich = true,
  }) async {
    fetchChainCalls++;
    return EvolutionChainInfo(
      root: EvolutionNode(
        name: 'charmander',
        id: 4,
        evolvesTo: [EvolutionNode(name: 'charmeleon', id: 5)],
      ),
    );
  }

  @override
  Future<({String? imageUrl, List<String> types})> fetchPokemonPreview(
    String name,
  ) async {
    if (previewError != null) {
      throw previewError!;
    }
    return (
      imageUrl: 'https://example.com/charmeleon.png',
      types: const ['fire'],
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<QuizPage> buildPage({
    FakeNotifier? notifier,
    GameStorage? storage,
    PokemonApiService? listApi,
    EvolutionApiService? api,
  }) async {
    final usedStorage = storage ?? GameStorage();
    await usedStorage.init();
    return QuizPage(
      storage: usedStorage,
      listApi: listApi ?? FakePokemonApiService(),
      api: api ?? FakeEvolutionApiService(),
      notifier: notifier ?? FakeNotifier(),
      random: Random(1),
    );
  }

  Finder option(String name) => find.byKey(Key('quiz-option-$name'));

  Finder findWrongOption() => find.byWidgetPredicate((widget) {
    final key = widget.key;
    return key is ValueKey<String> &&
        key.value.startsWith('quiz-option-') &&
        key.value != 'quiz-option-charmeleon';
  });

  testWidgets('jawaban benar menaikkan skor dan memanggil notifier', (
    tester,
  ) async {
    final notifier = FakeNotifier();
    await tester.pumpWidget(
      MaterialApp(home: await buildPage(notifier: notifier)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Charmeleon'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Skor: 1'), findsOneWidget);
    expect(notifier.results.last, true);
  });

  testWidgets('sprite jawaban benar tersedia di question', (tester) async {
    await tester.pumpWidget(MaterialApp(home: await buildPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Charmeleon'));
    await tester.pump();

    final image = tester.widget<Image>(
      find.byKey(const Key('quiz-feedback-image')),
    );
    // cacheWidth membungkus provider dengan ResizeImage.
    final provider = image.image is ResizeImage
        ? (image.image as ResizeImage).imageProvider
        : image.image;
    expect(provider, isA<NetworkImage>());
    expect(
      (provider as NetworkImage).url,
      'https://example.com/charmeleon.png',
    );
  });

  testWidgets('opsi salah berubah merah dan opsi benar hijau', (tester) async {
    await tester.pumpWidget(MaterialApp(home: await buildPage()));
    await tester.pumpAndSettle();

    await tester.tap(findWrongOption().first);
    await tester.pump();

    final correct = tester.widget<AnimatedContainer>(option('charmeleon'));
    final wrong = tester.widget<AnimatedContainer>(findWrongOption().first);
    expect((correct.decoration as BoxDecoration).color, Colors.green.shade700);
    expect((wrong.decoration as BoxDecoration).color, Colors.red.shade700);
  });

  testWidgets('opsi netral tetap terbaca setelah menjawab', (tester) async {
    await tester.pumpWidget(MaterialApp(home: await buildPage()));
    await tester.pumpAndSettle();

    await tester.tap(option('charmeleon'));
    await tester.pump();

    final neutralText = tester.widget<Text>(
      find.descendant(of: findWrongOption().first, matching: find.byType(Text)),
    );
    expect(neutralText.style?.color, AppColors.text);
  });

  testWidgets('sprite reveal benar-benar beranimasi', (tester) async {
    await tester.pumpWidget(MaterialApp(home: await buildPage()));
    await tester.pumpAndSettle();

    await tester.tap(option('charmeleon'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    // AnimatedSwitcher punya entry lama dan baru saat transisi berjalan.
    final fades = tester.widgetList<FadeTransition>(
      find.descendant(
        of: find.byKey(const Key('quiz-sprite-switcher')),
        matching: find.byType(FadeTransition),
      ),
    );
    expect(
      fades.any((fade) => fade.opacity.value > 0 && fade.opacity.value < 1),
      isTrue,
    );
  });

  testWidgets('dobel tap tidak menyisakan timer bocor', (tester) async {
    final notifier = SlowNotifier();
    final api = FakeEvolutionApiService();
    await tester.pumpWidget(
      MaterialApp(
        home: await buildPage(api: api, notifier: notifier),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(option('charmeleon'));
    await tester.tap(option('charmeleon'));
    notifier.gate.complete();
    await tester.pumpAndSettle();
    expect(notifier.results, [true]);

    await tester.ensureVisible(find.text('Soal berikutnya'));
    await tester.pump();
    await tester.tap(find.text('Soal berikutnya'));
    await tester.pumpAndSettle();
    final afterManual = api.fetchChainCalls;

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(api.fetchChainCalls, afterManual);
  });

  testWidgets('timer dibatalkan saat halaman ditutup', (tester) async {
    final api = FakeEvolutionApiService();
    await tester.pumpWidget(MaterialApp(home: await buildPage(api: api)));
    await tester.pumpAndSettle();
    final before = api.fetchChainCalls;

    await tester.tap(option('charmeleon'));
    await tester.pump();
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(api.fetchChainCalls, before);
  });

  testWidgets('meter streak mengikuti jawaban', (tester) async {
    await tester.pumpWidget(MaterialApp(home: await buildPage()));
    await tester.pumpAndSettle();

    await tester.tap(option('charmeleon'));
    await tester.pump();
    expect(find.text('Streak 1/5'), findsOneWidget);

    await tester.ensureVisible(find.text('Soal berikutnya'));
    await tester.pump();
    await tester.tap(find.text('Soal berikutnya'));
    await tester.pumpAndSettle();
    await tester.tap(findWrongOption().first);
    await tester.pump();
    expect(find.text('Streak 0/5'), findsOneWidget);
  });

  testWidgets('soal lanjut otomatis setelah dua detik', (tester) async {
    final api = FakeEvolutionApiService();
    await tester.pumpWidget(MaterialApp(home: await buildPage(api: api)));
    await tester.pumpAndSettle();
    final before = api.fetchChainCalls;

    await tester.tap(option('charmeleon'));
    await tester.pump();
    expect(find.textContaining('Kamu benar!'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(api.fetchChainCalls, greaterThan(before));
    expect(find.textContaining('Kamu benar!'), findsNothing);
  });

  testWidgets('tombol soal berikutnya membatalkan timer', (tester) async {
    final api = FakeEvolutionApiService();
    await tester.pumpWidget(MaterialApp(home: await buildPage(api: api)));
    await tester.pumpAndSettle();

    await tester.tap(option('charmeleon'));
    await tester.pump();
    await tester.ensureVisible(find.text('Soal berikutnya'));
    await tester.pump();
    await tester.tap(find.text('Soal berikutnya'));
    await tester.pumpAndSettle();
    final afterManual = api.fetchChainCalls;

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(api.fetchChainCalls, afterManual);
  });

  testWidgets('sprite gagal tidak menggagalkan soal', (tester) async {
    final api = FakeEvolutionApiService(
      previewError: ApiException('Gagal mengambil sprite.'),
    );
    await tester.pumpWidget(MaterialApp(home: await buildPage(api: api)));
    await tester.pumpAndSettle();

    expect(find.textContaining('Siapa evolusi berikutnya'), findsOneWidget);
    await tester.tap(option('charmeleon'));
    await tester.pump();
    expect(find.textContaining('Kamu benar!'), findsOneWidget);
  });

  testWidgets('toggle notifikasi menyimpan preferensi dan jadwal', (
    tester,
  ) async {
    final notifier = FakeNotifier();
    await tester.pumpWidget(
      MaterialApp(home: await buildPage(notifier: notifier)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(notifier.schedules.last, false);
    final switchWidget = tester.widget<Switch>(find.byType(Switch));
    expect(switchWidget.value, false);
  });

  testWidgets('izin notifikasi ditolak membuat toggle mati', (tester) async {
    final storage = GameStorage();
    final notifier = FakeNotifier(initializeResult: false);
    await tester.pumpWidget(
      MaterialApp(
        home: await buildPage(notifier: notifier, storage: storage),
      ),
    );
    await tester.pumpAndSettle();

    final switchWidget = tester.widget<Switch>(find.byType(Switch));
    expect(switchWidget.value, false);
    expect(storage.notificationsEnabled, false);
    expect(notifier.schedules, contains(false));
  });

  testWidgets('toggle dinyalakan ulang saat izin ditolak tetap mati', (
    tester,
  ) async {
    final storage = GameStorage();
    final notifier = FakeNotifier(initializeResult: false);
    await tester.pumpWidget(
      MaterialApp(
        home: await buildPage(notifier: notifier, storage: storage),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(tester.widget<Switch>(find.byType(Switch)).value, false);
    expect(storage.notificationsEnabled, false);
    expect(notifier.schedules.last, false);
    expect(find.textContaining('Izin notifikasi ditolak'), findsOneWidget);
  });

  testWidgets('skor sesi direset saat halaman dibuka, best score tetap', (
    tester,
  ) async {
    final storage = GameStorage();
    await tester.pumpWidget(
      MaterialApp(home: await buildPage(storage: storage)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Charmeleon'));
    await tester.pumpAndSettle();

    expect(storage.score, 1);
    expect(storage.bestScore, 1);

    // Keluar dulu dari halaman supaya State lama dibuang dan initState jalan lagi.
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      MaterialApp(home: await buildPage(storage: storage)),
    );
    await tester.pumpAndSettle();

    expect(storage.score, 0);
    expect(storage.bestScore, 1);
    expect(find.textContaining('Terbaik: 1'), findsOneWidget);
    expect(find.textContaining('Streak terbaik: 1'), findsOneWidget);
  });

  testWidgets('gagal memuat soal menampilkan pesan koneksi', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: await buildPage(
          listApi: FakePokemonApiService(
            error: ApiException('Tidak ada koneksi internet.'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Tidak ada koneksi internet'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);
  });
}
