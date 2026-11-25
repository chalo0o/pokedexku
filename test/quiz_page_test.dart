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
  @override
  Future<SpeciesInfo> fetchSpecies(String nameOrId) async {
    return SpeciesInfo(name: nameOrId, id: 4, chainId: 1);
  }

  @override
  Future<EvolutionChainInfo> fetchChain(
    int chainId, {
    bool enrich = true,
  }) async {
    return EvolutionChainInfo(
      root: EvolutionNode(
        name: 'charmander',
        id: 4,
        evolvesTo: [EvolutionNode(name: 'charmeleon', id: 5)],
      ),
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
  }) async {
    final usedStorage = storage ?? GameStorage();
    await usedStorage.init();
    return QuizPage(
      storage: usedStorage,
      listApi: listApi ?? FakePokemonApiService(),
      api: FakeEvolutionApiService(),
      notifier: notifier ?? FakeNotifier(),
      random: Random(1),
    );
  }

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
