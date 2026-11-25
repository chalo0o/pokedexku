import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/evolution_model.dart';
import 'pokemon_api_service.dart';

/// Service untuk species & evolution chain PokéAPI (endpoint tambahan UAS).
class EvolutionApiService {
  static const String _baseUrl = 'https://pokeapi.co/api/v2';
  static const Duration _timeout = Duration(seconds: 20);

  final http.Client _client;
  final Map<String, ({String? imageUrl, List<String> types})> _previewCache =
      {};

  EvolutionApiService({http.Client? client})
    : _client = client ?? http.Client();

  static int _lastIdFromUrl(String url) {
    final segments = Uri.parse(url).pathSegments.where((s) => s.isNotEmpty);
    for (final segment in segments.toList().reversed) {
      final id = int.tryParse(segment);
      if (id != null) {
        return id;
      }
    }
    return 0;
  }

  static int idFromUrl(String url) {
    final segments = Uri.parse(url).pathSegments;
    final chainIndex = segments.indexOf('evolution-chain');
    if (chainIndex != -1 && segments.length > chainIndex + 1) {
      return int.tryParse(segments[chainIndex + 1]) ?? 0;
    }
    return _lastIdFromUrl(url);
  }

  static String? _cleanText(String? value) {
    if (value == null) {
      return null;
    }
    final cleaned = value.replaceAll(RegExp(r'[\r\n\f]'), ' ');
    return cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static SpeciesInfo parseSpecies(Map<String, dynamic> json) {
    final chainUrl = json['evolution_chain']?['url'] as String? ?? '';
    String? flavorText;
    final entries = json['flavor_text_entries'] as List<dynamic>? ?? [];
    for (final entry in entries) {
      if (entry is Map<String, dynamic> && entry['language']?['name'] == 'en') {
        flavorText = _cleanText(entry['flavor_text'] as String?);
        break;
      }
    }
    String? genus;
    final genera = json['genera'] as List<dynamic>? ?? [];
    for (final item in genera) {
      if (item is Map<String, dynamic> && item['language']?['name'] == 'en') {
        genus = _cleanText(item['genus'] as String?);
        break;
      }
    }
    return SpeciesInfo(
      name: json['name'] as String? ?? '',
      id: json['id'] as int? ?? 0,
      chainId: idFromUrl(chainUrl),
      flavorText: flavorText,
      genus: genus,
    );
  }

  static EvolutionNode _parseNode(Map<String, dynamic> json) {
    final species = json['species'] as Map<String, dynamic>? ?? {};
    final evolvesTo = json['evolves_to'] as List<dynamic>? ?? [];
    return EvolutionNode(
      name: species['name'] as String? ?? '',
      id: _lastIdFromUrl(species['url'] as String? ?? ''),
      evolvesTo: evolvesTo
          .whereType<Map<String, dynamic>>()
          .map(_parseNode)
          .toList(),
    );
  }

  static EvolutionChainInfo parseChain(Map<String, dynamic> json) {
    final chain = json['chain'] as Map<String, dynamic>? ?? {};
    return EvolutionChainInfo(root: _parseNode(chain));
  }

  static List<String> parseTypes(Map<String, dynamic> json) {
    final types = json['types'] as List<dynamic>? ?? [];
    return types
        .whereType<Map<String, dynamic>>()
        .map((item) => item['type']?['name'] as String? ?? '')
        .where((name) => name.isNotEmpty)
        .toList();
  }

  /// GET dengan batas waktu dan pesan error yang aman ditampilkan.
  Future<dynamic> _get(String path) async {
    try {
      final response = await _client
          .get(Uri.parse('$_baseUrl$path'))
          .timeout(_timeout);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      if (response.statusCode == 404) {
        throw ApiException('Data tidak ditemukan (404).');
      }
      if (response.statusCode >= 500) {
        throw ApiException(
          'Server sedang bermasalah (${response.statusCode}).',
        );
      }
      throw ApiException('Permintaan gagal (kode ${response.statusCode}).');
    } on SocketException {
      throw ApiException('Tidak ada koneksi internet.');
    } on TimeoutException {
      throw ApiException('Koneksi terlalu lama. Coba lagi.');
    } on http.ClientException {
      throw ApiException('Gagal terhubung ke server.');
    } on FormatException {
      throw ApiException('Format data dari server tidak valid.');
    }
  }

  Future<SpeciesInfo> fetchSpecies(String nameOrId) async {
    final data = await _get('/pokemon-species/${nameOrId.trim()}');
    if (data is! Map<String, dynamic>) {
      throw ApiException('Format data species tidak sesuai.');
    }
    return parseSpecies(data);
  }

  Future<({String? imageUrl, List<String> types})> fetchPokemonPreview(
    String name,
  ) async {
    final key = name.toLowerCase();
    final cached = _previewCache[key];
    if (cached != null) {
      return cached;
    }
    final data = await _get('/pokemon/$key');
    if (data is! Map<String, dynamic>) {
      throw ApiException('Format data Pokémon tidak sesuai.');
    }
    final sprites = data['sprites'] as Map<String, dynamic>? ?? {};
    final other = sprites['other'] as Map<String, dynamic>? ?? {};
    final artwork = other['official-artwork'] as Map<String, dynamic>? ?? {};
    final imageUrl =
        artwork['front_default'] as String? ??
        sprites['front_default'] as String?;
    final preview = (imageUrl: imageUrl, types: parseTypes(data));
    _previewCache[key] = preview;
    return preview;
  }

  Future<EvolutionNode> _enrich(EvolutionNode node) async {
    final preview = await fetchPokemonPreview(node.name);
    final children = <EvolutionNode>[];
    for (final child in node.evolvesTo) {
      children.add(await _enrich(child));
    }
    return EvolutionNode(
      name: node.name,
      id: node.id,
      imageUrl: preview.imageUrl,
      types: preview.types,
      evolvesTo: children,
    );
  }

  /// [enrich]=false dipakai kuis karena hanya butuh nama tiap tahap.
  Future<EvolutionChainInfo> fetchChain(
    int chainId, {
    bool enrich = true,
  }) async {
    final data = await _get('/evolution-chain/$chainId');
    if (data is! Map<String, dynamic>) {
      throw ApiException('Format data evolution chain tidak sesuai.');
    }
    final parsed = parseChain(data);
    if (!enrich) {
      return parsed;
    }
    return EvolutionChainInfo(
      root: await _enrich(parsed.root),
      flavorText: parsed.flavorText,
    );
  }
}
