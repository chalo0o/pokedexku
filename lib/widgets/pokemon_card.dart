import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/pokemon_model.dart';
import '../pages/detail_page.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import 'pokemon_image.dart';

/// Kartu Pokémon (gambar, nomor, nama). Dipakai di grid dan carousel.
class PokemonCard extends StatelessWidget {
  final PokemonSummary pokemon;
  const PokemonCard({super.key, required this.pokemon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => DetailPage.open(context, pokemon.id),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
        ),
        child: Column(
          children: [
            Expanded(
              child: PokemonImage(pokemon.imageUrl, width: double.infinity),
            ),
            const SizedBox(height: 6),
            Text(dexNumber(pokemon.id),
                style: GoogleFonts.poppins(fontSize: 11, color: AppColors.muted)),
            Text(titleCase(pokemon.name),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
          ],
        ),
      ),
    );
  }
}
