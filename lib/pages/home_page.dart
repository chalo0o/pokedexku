import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/pokemon_model.dart';
import '../services/pokemon_api_service.dart';
import '../utils/constants.dart';
import '../utils/launcher.dart';
import '../widgets/app_header.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';
import '../widgets/pokemon_card.dart';
import '../widgets/search_box.dart';
import '../widgets/type_badge.dart';
import 'list_page.dart';

/// Halaman 1: Beranda (pencarian, tipe, pilihan hari ini).
class HomePage extends StatefulWidget {
  final VoidCallback onSeeAll; // pindah ke tab Pokédex
  const HomePage({super.key, required this.onSeeAll});

  @override
  State<HomePage> createState() => _HomePageState();
}

/// Pokémon populer (statis, tidak butuh permintaan HTTP tambahan).
const List<PokemonSummary> _popular = [
  PokemonSummary(id: 25, name: 'pikachu'),
  PokemonSummary(id: 6, name: 'charizard'),
  PokemonSummary(id: 150, name: 'mewtwo'),
  PokemonSummary(id: 133, name: 'eevee'),
  PokemonSummary(id: 94, name: 'gengar'),
  PokemonSummary(id: 448, name: 'lucario'),
];

const List<String> _facts = [
  'Pikachu awalnya dirancang sebagai Pokémon evolusi dari Raichu, bukan sebaliknya.',
  'Ada 18 tipe Pokémon, dan setiap tipe punya kelebihan serta kelemahan masing-masing.',
  'Snorlax bisa tidur hampir sepanjang hari dan baru bangun saat lapar.',
  'Mew adalah Pokémon yang konon memiliki DNA dari semua Pokémon lain.',
  'Eevee punya banyak evolusi, dan bentuknya bergantung pada batu atau kondisi tertentu.',
  'Pokémon pertama di Pokédex nasional adalah Bulbasaur dengan nomor #001.',
];

class _HomePageState extends State<HomePage> {
  final String _fact = _facts[DateTime.now().millisecond % _facts.length];
  final _api = PokemonApiService();
  final _controller = TextEditingController();
  late Future<List<PokemonSummary>> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.fetchRandomSample();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _reload() => setState(() => _future = _api.fetchRandomSample());

  Future<void> _refresh() async {
    _reload();
    try {
      await _future;
    } catch (_) {/* error ditampilkan oleh FutureBuilder */}
  }

  void _openList({String? type, String query = ''}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ListPage(type: type, query: query, showBack: true)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppHeader(
                title: 'Pokédexku',
                subtitle: 'Ensiklopedia Pokémon dari PokéAPI.',
                bottom: SearchBox(
                  controller: _controller,
                  onSubmitted: (q) {
                    if (q.trim().isNotEmpty) _openList(query: q.trim());
                  },
                ),
              ),
              _sectionTitle('Jelajahi Tipe'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final t in kTypes) TypeBadge(t, onTap: () => _openList(type: t)),
                  ],
                ),
              ),
              _sectionTitle('Pilihan Hari Ini', action: 'Lihat semua'),
              FutureBuilder<List<PokemonSummary>>(
                future: _future,
                builder: (context, snap) {
                  // 1. LOADING
                  if (snap.connectionState != ConnectionState.done) {
                    return const SizedBox(height: 220, child: LoadingView());
                  }
                  // 2. ERROR
                  if (snap.hasError) {
                    return SizedBox(
                        height: 260, child: ErrorView(error: snap.error!, onRetry: _reload));
                  }
                  // 3. SUCCESS
                  final items = snap.data!;
                  return SizedBox(
                    height: 190,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, i) => SizedBox(width: 140, child: PokemonCard(pokemon: items[i])),
                    ),
                  );
                },
              ),
              _sectionTitle('Pokémon Populer', action: 'Lihat semua'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _popular.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.8,
                  ),
                  itemBuilder: (_, i) => PokemonCard(pokemon: _popular[i]),
                ),
              ),
              _sectionTitle('Tahukah Kamu?'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0x40FFCB05),
                    borderRadius: BorderRadius.circular(AppRadius.card),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb_outline, color: AppColors.primaryDark),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(_fact,
                            style: GoogleFonts.poppins(
                                fontSize: 12, height: 1.5, color: AppColors.text)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => openUrl(context, kAttributionUrl),
                  child: Text('Data dari PokéAPI (pokeapi.co)',
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.muted,
                          decoration: TextDecoration.underline)),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text('Pokémon dan nama karakternya adalah merek dagang Nintendo.',
                      style: GoogleFonts.poppins(fontSize: 9, color: AppColors.muted)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, {String? action}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.text)),
          if (action != null)
            GestureDetector(
              onTap: widget.onSeeAll,
              child: Text(action,
                  style: GoogleFonts.poppins(fontSize: 11, color: AppColors.primary)),
            ),
        ],
      ),
    );
  }
}