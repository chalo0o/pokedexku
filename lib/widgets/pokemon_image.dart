import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Gambar dari URL dengan indikator memuat dan placeholder bila gagal.
class PokemonImage extends StatelessWidget {
  final String url;
  final double? width, height;
  final BoxFit fit;
  final int cacheWidth;

  const PokemonImage(this.url,
      {super.key, this.width, this.height, this.fit = BoxFit.contain, this.cacheWidth = 300});

  Widget _placeholder({Widget? child}) => Container(
        width: width,
        height: height,
        alignment: Alignment.center,
        child: child ?? const Icon(Icons.catching_pokemon, color: AppColors.placeholder, size: 48),
      );

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return _placeholder();
    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: cacheWidth,
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : _placeholder(
              child: const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))),
      errorBuilder: (_, __, ___) => _placeholder(),
    );
  }
}
