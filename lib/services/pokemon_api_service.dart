import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/pokemon_detail_model.dart';
import '../models/pokemon_model.dart';

/// Kesalahan yang pesannya aman ditampilkan ke pengguna.
class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

/// Semua permintaan HTTP ke PokéAPI ada di sini.
class PokemonApiService {
  static const String _base = 'https://pokeapi.co/api/v2';
  static const Duration _timeout = Duration(seconds: 20);

  /// Cache daftar semua nama (dimuat sekali, dipakai untuk pencarian).
  static List<PokemonSummary>? _allCache;

  /// GET /pokemon?limit=&offset= (paginasi).
  Future<PokemonPage> fetchPage({int limit = 20, int offset = 0}) async {
    final data = await _get('/pokemon', {'limit': '$limit', 'offset': '$offset'});
    if (data is! Map<String, dynamic>) throw ApiException('Format data tidak sesuai.');
    return PokemonPage.fromJson(data);
  }

  /// Delapan Pokémon berurutan dari posisi acak, untuk "Pilihan Hari Ini".
  Future<List<PokemonSummary>> fetchRandomSample({int count = 8}) async {
    final offset = Random().nextInt(1000);
    final page = await fetchPage(limit: count, offset: offset);
    return page.results;
  }

  /// Pencarian nama atau nomor. PokéAPI tidak punya endpoint pencarian,
  /// jadi seluruh daftar nama dimuat sekali lalu difilter di aplikasi.
  Future<List<PokemonSummary>> searchByName(String query) async {
    final q = query.trim().toLowerCase();
    final all = await _allPokemon();
    return all.where((p) => p.name.contains(q) || p.id.toString() == q).toList();
  }

  /// GET /type/{nama}: semua Pokémon bertipe tertentu.
  Future<List<PokemonSummary>> fetchByType(String type) async {
    final data = await _get('/type/$type');
    if (data is! Map<String, dynamic>) throw ApiException('Format data tidak sesuai.');
    final list = (data['pokemon'] as List? ?? [])
        .whereType<Map>()
        .map((e) => e['pokemon'])
        .whereType<Map<String, dynamic>>()
        .map(PokemonSummary.fromJson)
        .where((p) => isMainDex(p.id))
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    return list;
  }

  /// GET /pokemon/{id} dan /pokemon-species/{id} dijalankan bersamaan.
  /// Kegagalan species tidak menggagalkan detail (deskripsi dikosongkan).
  Future<PokemonDetail> fetchDetail(int id) async {
    final detailFuture = _get('/pokemon/$id');
    final speciesFuture = _getOrNull('/pokemon-species/$id');
    final detail = await detailFuture;
    final species = await speciesFuture;
    if (detail is! Map<String, dynamic>) throw ApiException('Data Pokémon tidak ditemukan.');
    return PokemonDetail.fromJson(detail, species is Map<String, dynamic> ? species : null);
  }

  Future<List<PokemonSummary>> _allPokemon() async {
    final cached = _allCache;
    if (cached != null) return cached;
    final data = await _get('/pokemon', {'limit': '2000', 'offset': '0'});
    if (data is! Map<String, dynamic>) throw ApiException('Format data tidak sesuai.');
    final list = (data['results'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(PokemonSummary.fromJson)
        .where((p) => isMainDex(p.id))
        .toList();
    _allCache = list;
    return list;
  }

  Future<dynamic> _getOrNull(String path) async {
    try {
      return await _get(path);
    } catch (_) {
      return null;
    }
  }

  /// Mengirim GET, memeriksa status respons, lalu decode JSON.
  Future<dynamic> _get(String path, [Map<String, String>? params]) async {
    final uri = Uri.parse('$_base$path').replace(queryParameters: params);
    try {
      final response = await http.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else if (response.statusCode == 404) {
        throw ApiException('Data tidak ditemukan (404).');
      } else if (response.statusCode >= 500) {
        throw ApiException('Server sedang bermasalah (${response.statusCode}).');
      } else {
        throw ApiException('Permintaan gagal (kode ${response.statusCode}).');
      }
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
}
