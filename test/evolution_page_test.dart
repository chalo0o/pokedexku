import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ma_game/models/evolution_model.dart';
import 'package:ma_game/pages/evolution_page.dart';
import 'package:ma_game/services/evolution_api_service.dart';

EvolutionNode _node(
  String name,
  int id, [
  List<EvolutionNode> children = const [],
]) {
  return EvolutionNode(name: name, id: id, evolvesTo: children);
}

class FakeEvolutionApiService extends EvolutionApiService {
  @override
  Future<SpeciesInfo> fetchSpecies(String nameOrId) async {
    return SpeciesInfo(
      name: nameOrId,
      id: nameOrId == 'eevee'
          ? 133
          : nameOrId == 'mewtwo'
          ? 150
          : 4,
      chainId: nameOrId == 'eevee'
          ? 2
          : nameOrId == 'mewtwo'
          ? 77
          : 1,
      genus: 'Fake',
      flavorText: 'Data uji.',
    );
  }

  @override
  Future<EvolutionChainInfo> fetchChain(
    int chainId, {
    bool enrich = true,
  }) async {
    if (chainId == 77) {
      return EvolutionChainInfo(root: _node('mewtwo', 150));
    }
    if (chainId == 2) {
      return EvolutionChainInfo(
        root: _node('eevee', 133, [
          _node('vaporeon', 134),
          _node('jolteon', 135),
          _node('flareon', 136),
        ]),
      );
    }
    return EvolutionChainInfo(
      root: _node('charmander', 4, [
        _node('charmeleon', 5, [_node('charizard', 6)]),
      ]),
    );
  }
}

void main() {
  testWidgets('menampilkan rantai evolusi charmander', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: EvolutionPage(service: FakeEvolutionApiService())),
    );

    await tester.enterText(find.byType(TextField), 'charmander');
    await tester.tap(find.text('Cari'));
    await tester.pumpAndSettle();

    expect(find.text('Charmeleon'), findsOneWidget);
    expect(find.text('Charizard'), findsOneWidget);
  });

  testWidgets('menampilkan semua cabang evolusi eevee', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: EvolutionPage(service: FakeEvolutionApiService())),
    );

    await tester.enterText(find.byType(TextField), 'eevee');
    await tester.tap(find.text('Cari'));
    await tester.pumpAndSettle();

    expect(find.text('Vaporeon'), findsOneWidget);
    expect(find.text('Jolteon'), findsOneWidget);
    expect(find.text('Flareon'), findsOneWidget);
  });

  testWidgets('Pokémon tanpa evolusi tetap menampilkan satu node', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: EvolutionPage(service: FakeEvolutionApiService())),
    );

    await tester.enterText(find.byType(TextField), 'mewtwo');
    await tester.tap(find.text('Cari'));
    await tester.pumpAndSettle();

    // Kolom cari memakai teks asli, kartu evolusi memakai title case.
    expect(find.text('mewtwo'), findsOneWidget);
    expect(find.text('Mewtwo'), findsOneWidget);
    expect(find.text('Charmeleon'), findsNothing);
  });
}
