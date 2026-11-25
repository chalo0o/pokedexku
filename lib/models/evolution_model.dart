/// Satu simpul dalam rantai evolusi Pokémon.
class EvolutionNode {
  final String name;
  final int id;
  final String? imageUrl;
  final List<String> types;
  final List<EvolutionNode> evolvesTo;

  const EvolutionNode({
    required this.name,
    required this.id,
    this.imageUrl,
    this.types = const [],
    this.evolvesTo = const [],
  });

  /// Rantai lurus mengikuti anak pertama — dipakai untuk membuat soal kuis.
  List<EvolutionNode> get linearStages {
    final stages = <EvolutionNode>[this];
    var current = this;
    while (current.evolvesTo.isNotEmpty) {
      current = current.evolvesTo.first;
      stages.add(current);
    }
    return stages;
  }
}

/// Hasil rantai evolusi lengkap dari PokéAPI.
class EvolutionChainInfo {
  final EvolutionNode root;
  final String? flavorText;

  const EvolutionChainInfo({required this.root, this.flavorText});
}

/// Informasi species Pokémon yang dipakai untuk membuka rantai evolusi.
class SpeciesInfo {
  final String name;
  final int id;
  final int chainId;
  final String? flavorText;
  final String? genus;

  const SpeciesInfo({
    required this.name,
    required this.id,
    required this.chainId,
    this.flavorText,
    this.genus,
  });
}
