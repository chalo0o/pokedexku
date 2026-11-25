import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:ma_game/services/evolution_api_service.dart';
import 'package:ma_game/services/pokemon_api_service.dart';

Map<String, dynamic> _speciesNode(String name, int id) => {
  'species': {
    'name': name,
    'url': 'https://pokeapi.co/api/v2/pokemon-species/$id/',
  },
  'evolution_details': [],
  'evolves_to': <dynamic>[],
};

Map<String, dynamic> get _charmanderChain {
  final charmander = _speciesNode('charmander', 4);
  final charmeleon = _speciesNode('charmeleon', 5);
  final charizard = _speciesNode('charizard', 6);
  charmeleon['evolves_to'] = [charizard];
  charmander['evolves_to'] = [charmeleon];
  return {'chain': charmander};
}

Map<String, dynamic> get _eeveeChain {
  final eevee = _speciesNode('eevee', 133);
  eevee['evolves_to'] = [
    _speciesNode('vaporeon', 134),
    _speciesNode('jolteon', 135),
    _speciesNode('flareon', 136),
  ];
  return {'chain': eevee};
}

Map<String, dynamic> get _speciesJson => {
  'name': 'charmander',
  'id': 4,
  'evolution_chain': {'url': 'https://pokeapi.co/api/v2/evolution-chain/1/'},
  'flavor_text_entries': [
    {
      'flavor_text': 'Blah\r\nblah\f',
      'language': {'name': 'en'},
    },
    {
      'flavor_text': 'Indonesia',
      'language': {'name': 'id'},
    },
  ],
  'genera': [
    {
      'genus': 'Lizard',
      'language': {'name': 'en'},
    },
  ],
};

void main() {
  test('parseChain mengikuti rantai charmander', () {
    final chain = EvolutionApiService.parseChain(_charmanderChain);

    expect(chain.root.name, 'charmander');
    expect(chain.root.evolvesTo.single.name, 'charmeleon');
    expect(chain.root.evolvesTo.single.evolvesTo.single.name, 'charizard');
    expect(chain.root.linearStages.map((e) => e.name).toList(), [
      'charmander',
      'charmeleon',
      'charizard',
    ]);
  });

  test('parseChain menangani Pokémon tanpa evolusi', () {
    final chain = EvolutionApiService.parseChain({
      'chain': _speciesNode('mewtwo', 150),
    });

    expect(chain.root.name, 'mewtwo');
    expect(chain.root.evolvesTo.isEmpty, true);
    expect(chain.root.linearStages.length, 1);
  });

  test('parseChain menangani cabang evolusi', () {
    final chain = EvolutionApiService.parseChain(_eeveeChain);

    expect(chain.root.name, 'eevee');
    expect(chain.root.evolvesTo.length, 3);
    expect(chain.root.evolvesTo.map((e) => e.name).toList(), [
      'vaporeon',
      'jolteon',
      'flareon',
    ]);
  });

  test('idFromUrl mengambil angka evolution-chain', () {
    expect(
      EvolutionApiService.idFromUrl(
        'https://pokeapi.co/api/v2/evolution-chain/1/',
      ),
      1,
    );
  });

  test('parseSpecies mengambil chainId, flavorText, dan genus Inggris', () {
    final species = EvolutionApiService.parseSpecies(_speciesJson);

    expect(species.name, 'charmander');
    expect(species.id, 4);
    expect(species.chainId, 1);
    expect(species.flavorText, 'Blah blah');
    expect(species.genus, 'Lizard');
  });

  test('parseTypes mengambil tipe dari Pokemon', () {
    expect(
      EvolutionApiService.parseTypes({
        'types': [
          {
            'type': {'name': 'fire'},
          },
          {
            'type': {'name': 'flying'},
          },
        ],
      }),
      ['fire', 'flying'],
    );
  });

  test('404 diterjemahkan ke ApiException yang ramah', () {
    final service = EvolutionApiService(
      client: MockClient((request) async => http.Response('{}', 404)),
    );

    expect(
      service.fetchSpecies('mewtwo'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          contains('404'),
        ),
      ),
    );
  });

  test('timeout diterjemahkan ke ApiException yang ramah', () {
    final service = EvolutionApiService(
      client: MockClient((request) async => throw TimeoutException('lama')),
    );

    expect(
      service.fetchChain(1),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          contains('Koneksi terlalu lama'),
        ),
      ),
    );
  });

  test('fetchChain tanpa enrich tidak memanggil endpoint pokemon', () async {
    final paths = <String>[];
    final service = EvolutionApiService(
      client: MockClient((request) async {
        paths.add(request.url.path);
        if (request.url.path.contains('evolution-chain')) {
          return http.Response(jsonEncode(_charmanderChain), 200);
        }
        return http.Response('{}', 500);
      }),
    );

    final chain = await service.fetchChain(1, enrich: false);

    expect(chain.root.name, 'charmander');
    expect(paths, hasLength(1));
  });
}
