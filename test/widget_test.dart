import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ma_game/main.dart';
import 'package:ma_game/services/game_storage.dart';
import 'package:ma_game/services/notification_service.dart';

class FakeNotifier implements Notifier {
  @override
  Future<bool> initialize() async => false;

  @override
  Future<void> scheduleDailyReminder({required bool enabled}) async {}

  @override
  Future<void> showQuizResult({required bool correct}) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Pokedex app builds', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = GameStorage();
    await storage.init();

    await tester.pumpWidget(
      PokedexApp(storage: storage, notifier: FakeNotifier()),
    );

    expect(find.byType(PokedexApp), findsOneWidget);
  });
}
