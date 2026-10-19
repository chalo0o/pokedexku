/// Mengubah nilai dynamic dari JSON menjadi String aman (null -> '').
String asText(dynamic v) => v?.toString() ?? '';

/// Id 1..9999 = Pokémon utama. Id >= 10000 adalah bentuk khusus (tanpa gambar standar).
bool isMainDex(int id) => id > 0 && id < 10000;

/// Model ringkas untuk daftar. Respons /pokemon hanya berisi name dan url,
/// jadi id diambil dari url dan gambar dibentuk dari id.
class PokemonSummary {
  final int id;
  final String name;

  const PokemonSummary({required this.id, required this.name});

  factory PokemonSummary.fromJson(Map<String, dynamic> json) {
    final url = asText(json['url']);
    return PokemonSummary(id: idFromUrl(url), name: asText(json['name']));
  }

  /// "https://pokeapi.co/api/v2/pokemon/25/" -> 25
  static int idFromUrl(String url) {
    final parts = url.split('/').where((p) => p.isNotEmpty).toList();
    return parts.isEmpty ? 0 : int.tryParse(parts.last) ?? 0;
  }

  static String artworkUrl(int id) =>
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png';

  String get imageUrl => artworkUrl(id);
}

/// Satu halaman hasil /pokemon?limit=&offset=
class PokemonPage {
  final int count;
  final bool hasNext;
  final List<PokemonSummary> results;

  const PokemonPage({required this.count, required this.hasNext, required this.results});

  factory PokemonPage.fromJson(Map<String, dynamic> json) {
    final all = (json['results'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(PokemonSummary.fromJson)
        .toList();
    final valid = all.where((p) => isMainDex(p.id)).toList();
    return PokemonPage(
      count: (json['count'] as num?)?.toInt() ?? 0,
      // Bila ada bentuk khusus yang tersaring, berarti daftar utama sudah habis.
      hasNext: json['next'] != null && valid.length == all.length,
      results: valid,
    );
  }
}
