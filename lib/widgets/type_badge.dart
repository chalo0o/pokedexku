import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';

/// Label tipe Pokémon berwarna.
class TypeBadge extends StatelessWidget {
  final String type;
  final VoidCallback? onTap;
  const TypeBadge(this.type, {super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = typeColor(type);
    final fg = color.computeLuminance() > 0.5 ? AppColors.text : Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
        child: Text(titleCase(type),
            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
      ),
    );
  }
}
