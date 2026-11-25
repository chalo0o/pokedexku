import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ma_game/services/game_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('skor dan streak tersimpan setelah instance baru', () async {
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

  test('toggle notifikasi tersimpan', () async {
    final storage = GameStorage();
    await storage.init();

    await storage.setNotificationsEnabled(false);

    final reloaded = GameStorage();
    await reloaded.init();
    expect(reloaded.notificationsEnabled, false);
  });
}
