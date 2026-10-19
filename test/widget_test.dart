import 'package:flutter_test/flutter_test.dart';
import 'package:ma_game/main.dart';

void main() {
  testWidgets('Pokedex app builds', (WidgetTester tester) async {
    await tester.pumpWidget(const PokedexApp());

    expect(find.byType(PokedexApp), findsOneWidget);
  });
}