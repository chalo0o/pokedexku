import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/pokemon_detail_model.dart';
import '../services/pokemon_api_service.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';
import '../widgets/pokemon_image.dart';
import '../widgets/type_badge.dart';

/// Halaman 3: Detail Pokémon (/pokemon/{id} + /pokemon-species/{id}).
class DetailPage extends StatefulWidget {
  final int pokemonId;
  const DetailPage({super.key, required this.pokemonId});

  static void open(BuildContext context, int id) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => DetailPage(pokemonId: id)));
  }

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  final _api = PokemonApiService();
  late Future<PokemonDetail> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.fetchDetail(widget.pokemonId);
  }

  void _reload() => setState(() => _future = _api.fetchDetail(widget.pokemonId));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<PokemonDetail>(
        future: _future,
        builder: (context, snap) {
          // 1. LOADING
          if (snap.connectionState != ConnectionState.done) {
            return Stack(children: [
              const LoadingView(message: 'Memuat detail Pokémon...'),
              _backButton(),
            ]);
          }
          // 2. ERROR
          if (snap.hasError) {
            return Stack(children: [
              ErrorView(error: snap.error!, onRetry: _reload),
              _backButton(),
            ]);
          }
          // 3. SUCCESS
          return _content(snap.data!);
        },
      ),
    );
  }

  Widget _backButton() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: CircleAvatar(
          radius: 24,
          backgroundColor: Colors.white,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.text),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
    );
  }

  Widget _content(PokemonDetail d) {
    final color = d.types.isNotEmpty ? typeColor(d.types.first) : AppColors.primary;
    final h = MediaQuery.of(context).size.height;
    return Stack(
      children: [
        Positioned.fill(child: ColoredBox(color: color)),
        Positioned(
          top: h * 0.07,
          left: 0,
          right: 0,
          height: h * 0.30,
          child: PokemonImage(d.imageUrl, cacheWidth: 600),
        ),
        SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: h * 0.33),
              _card(d, color),
            ],
          ),
        ),
        _backButton(),
      ],
    );
  }

  Widget _card(PokemonDetail d, Color color) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height * 0.67),
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(titleCase(d.name),
                    style: GoogleFonts.poppins(
                        fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.text)),
              ),
              Text(dexNumber(d.id),
                  style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.muted)),
            ],
          ),
          if (d.genus.isNotEmpty)
            Text(d.genus, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.muted)),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [for (final t in d.types) TypeBadge(t)]),
          if (d.description.isNotEmpty) ...[
            const SizedBox(height: 20),
            _sectionTitle('Deskripsi'),
            const SizedBox(height: 6),
            Text(d.description,
                style: GoogleFonts.poppins(fontSize: 13, height: 1.6, color: AppColors.muted)),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              _infoBox('Tinggi', '${d.heightM.toStringAsFixed(1)} m'),
              const SizedBox(width: 10),
              _infoBox('Berat', '${d.weightKg.toStringAsFixed(1)} kg'),
              const SizedBox(width: 10),
              _infoBox('Base EXP', d.baseExp > 0 ? '${d.baseExp}' : '-'),
            ],
          ),
          const SizedBox(height: 20),
          _sectionTitle('Kemampuan'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final a in d.abilities)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Text(
                    a.isHidden ? '${titleCase(a.name)} (tersembunyi)' : titleCase(a.name),
                    style: GoogleFonts.poppins(fontSize: 12, color: AppColors.text),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          _sectionTitle('Statistik Dasar'),
          const SizedBox(height: 8),
          for (final s in d.stats) _statRow(s, color),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: GoogleFonts.poppins(
          fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.text));

  Widget _infoBox(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Column(
          children: [
            Text(value,
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text)),
            Text(label, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.muted)),
          ],
        ),
      ),
    );
  }

  Widget _statRow(PokemonStat s, Color color) {
    final progress = (s.value / 255).clamp(0.0, 1.0).toDouble();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(s.label,
                style: GoogleFonts.poppins(fontSize: 12, color: AppColors.muted)),
          ),
          SizedBox(
            width: 38,
            child: Text('${s.value}',
                style: GoogleFonts.poppins(
                    fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: AppColors.placeholder,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
