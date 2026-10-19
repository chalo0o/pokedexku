import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';

/// Header merah bersudut bawah bulat (dipakai Beranda dan Daftar).
class AppHeader extends StatelessWidget {
  final String title, subtitle;
  final Widget? bottom;
  final bool showBack;

  const AppHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.bottom,
    this.showBack = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(AppRadius.sheet)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 16),
            Row(
              children: [
                if (showBack) ...[
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: GoogleFonts.poppins(
                              fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text(subtitle,
                          style: GoogleFonts.poppins(fontSize: 11, color: Colors.white70)),
                    ],
                  ),
                ),
                const CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.accent,
                  child: Icon(Icons.catching_pokemon, color: AppColors.text),
                ),
              ],
            ),
            if (bottom != null) ...[const SizedBox(height: 16), bottom!],
          ],
        ),
      ),
    );
  }
}
