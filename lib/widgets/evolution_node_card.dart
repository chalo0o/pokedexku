import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/evolution_model.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import 'type_badge.dart';

/// Kartu satu tahap evolusi; [depth] dipakai untuk indentasi cabang.
class EvolutionNodeCard extends StatelessWidget {
  final EvolutionNode node;
  final int depth;

  const EvolutionNodeCard({super.key, required this.node, this.depth = 0});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: depth * 16.0),
      child: Card(
        color: AppColors.card,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: node.imageUrl != null
                    ? Image.network(
                        node.imageUrl!,
                        width: 56,
                        height: 56,
                        cacheWidth: 168,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.catching_pokemon,
                          size: 40,
                          color: AppColors.muted,
                        ),
                      )
                    : const Icon(
                        Icons.catching_pokemon,
                        size: 40,
                        color: AppColors.muted,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${node.id.toString().padLeft(3, '0')}',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: AppColors.muted,
                      ),
                    ),
                    Text(
                      titleCase(node.name),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    if (node.types.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final type in node.types) TypeBadge(type),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
