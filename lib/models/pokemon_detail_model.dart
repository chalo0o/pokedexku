import 'pokemon_model.dart';

class PokemonStat {
  final String name;
  final int value;
  const PokemonStat({required this.name, required this.value});

  String get label {
    switch (name) {
      case 'hp':
        return 'HP';
      case 'attack':
        return 'Attack';
      case 'defense':
        return 'Defense';
      case 'special-attack':
        return 'Sp. Atk';
      case 'special-defense':
        return 'Sp. Def';
      case 'speed':
        return 'Speed';
      default:
        return name;
    }
  }
}

class PokemonAbility {
  final String name;
  final bool isHidden;
  const PokemonAbility({required this.name, required this.isHidden});
}

/// Model lengkap dari /pokemon/{id}, ditambah deskripsi dari /pokemon-species/{id}.
class PokemonDetail {
  final int id;
  final String name;
  final double heightM;
  final double weightKg;
  final int baseExp;
  final List<String> types;
  final List<PokemonAbility> abilities;
  final List<PokemonStat> stats;
  final String imageUrl;
  final String description;
  final String genus;

  const PokemonDetail({
    required this.id,
    required this.name,
    required this.heightM,
    required this.weightKg,
    required this.baseExp,
    required this.types,
    required this.abilities,
    required this.stats,
    required this.imageUrl,
    required this.description,
    required this.genus,
  });

  factory PokemonDetail.fromJson(Map<String, dynamic> json, Map<String, dynamic>? species) {
    final id = (json['id'] as num?)?.toInt() ?? 0;

    final types = (json['types'] as List? ?? [])
        .whereType<Map>()
        .map((t) => asText((t['type'] as Map?)?['name']))
        .where((e) => e.isNotEmpty)
        .toList();

    final abilities = (json['abilities'] as List? ?? [])
        .whereType<Map>()
        .map((a) => PokemonAbility(
              name: asText((a['ability'] as Map?)?['name']),
              isHidden: a['is_hidden'] == true,
            ))
        .where((a) => a.name.isNotEmpty)
        .toList();

    final stats = (json['stats'] as List? ?? [])
        .whereType<Map>()
        .map((s) => PokemonStat(
              name: asText((s['stat'] as Map?)?['name']),
              value: (s['base_stat'] as num?)?.toInt() ?? 0,
            ))
        .toList();

    // Gambar: official artwork dari respons, cadangan dari repo sprites.
    final sprites = json['sprites'] as Map?;
    final other = sprites?['other'] as Map?;
    final artwork = other?['official-artwork'] as Map?;
    var image = asText(artwork?['front_default']);
    if (image.isEmpty) image = PokemonSummary.artworkUrl(id);

    // Deskripsi dan kategori dari species (bahasa Inggris).
    var description = '';
    var genus = '';
    if (species != null) {
      for (final e in (species['flavor_text_entries'] as List? ?? []).whereType<Map>()) {
        if (asText((e['language'] as Map?)?['name']) == 'en') {
          description = asText(e['flavor_text']);
        }
      }
      description = description.replaceAll(RegExp(r'[\n\f\r]+'), ' ').trim();
      for (final e in (species['genera'] as List? ?? []).whereType<Map>()) {
        if (asText((e['language'] as Map?)?['name']) == 'en') {
          genus = asText(e['genus']);
        }
      }
    }

    return PokemonDetail(
      id: id,
      name: asText(json['name']),
      heightM: ((json['height'] as num?) ?? 0) / 10, // desimeter -> meter
      weightKg: ((json['weight'] as num?) ?? 0) / 10, // hektogram -> kg
      baseExp: (json['base_experience'] as num?)?.toInt() ?? 0,
      types: types,
      abilities: abilities,
      stats: stats,
      imageUrl: image,
      description: description,
      genus: genus,
    );
  }
}
