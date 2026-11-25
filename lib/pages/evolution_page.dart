import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/evolution_model.dart';
import '../services/evolution_api_service.dart';
import '../utils/constants.dart';
import '../widgets/app_header.dart';
import '../widgets/error_view.dart';
import '../widgets/evolution_node_card.dart';
import '../widgets/loading_view.dart';

/// Halaman 3: Pohon Evolusi dari PokéAPI.
class EvolutionPage extends StatefulWidget {
  final EvolutionApiService? service;

  const EvolutionPage({super.key, this.service});

  @override
  State<EvolutionPage> createState() => _EvolutionPageState();
}

class _EvolutionPageState extends State<EvolutionPage> {
  late final EvolutionApiService _api;
  final TextEditingController _controller = TextEditingController();
  Future<EvolutionChainInfo>? _future;
  SpeciesInfo? _species;
  int _activeRequest = 0;

  @override
  void initState() {
    super.initState();
    _api = widget.service ?? EvolutionApiService();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<EvolutionChainInfo> _load(String query, int requestId) async {
    final species = await _api.fetchSpecies(query);
    if (mounted && requestId == _activeRequest) {
      setState(() => _species = species);
    }
    return _api.fetchChain(species.chainId);
  }

  void _search() {
    final query = _controller.text.trim();
    if (query.isEmpty) {
      return;
    }
    final requestId = ++_activeRequest;
    setState(() {
      _species = null;
      _future = _load(query, requestId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppHeader(
                title: 'Evolusi',
                subtitle: 'Lihat rantai evolusi Pokémon dari PokéAPI.',
                bottom: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        onSubmitted: (_) => _search(),
                        decoration: InputDecoration(
                          hintText: 'Cari nama atau nomor Pokémon',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.text,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _search,
                      child: Text(
                        'Cari',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              _buildBody(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final future = _future;
    if (future == null) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            'Cari Pokémon untuk melihat pohon evolusinya.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: AppColors.muted),
          ),
        ),
      );
    }
    return FutureBuilder<EvolutionChainInfo>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(height: 320, child: LoadingView());
        }
        if (snapshot.hasError) {
          return SizedBox(
            height: 320,
            child: ErrorView(error: snapshot.error!, onRetry: _search),
          );
        }
        final chain = snapshot.data!;
        final species = _species;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (species != null) ...[
                Text(
                  species.genus ?? species.name,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                if (species.flavorText != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    species.flavorText!,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
              ],
              _buildNode(chain.root, 0),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNode(EvolutionNode node, int depth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (depth > 0)
          Padding(
            padding: EdgeInsets.only(left: depth * 16.0 + 20),
            child: const Icon(
              Icons.arrow_downward,
              size: 20,
              color: AppColors.primary,
            ),
          ),
        EvolutionNodeCard(node: node, depth: depth),
        for (final child in node.evolvesTo) _buildNode(child, depth + 1),
      ],
    );
  }
}
