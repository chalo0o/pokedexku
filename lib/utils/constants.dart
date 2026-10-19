import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFE53935);
  static const Color primaryDark = Color(0xFFB71C1C);
  static const Color accent = Color(0xFFFFCB05);
  static const Color background = Color(0xFFF4F6F8);
  static const Color card = Colors.white;
  static const Color text = Color(0xFF263238);
  static const Color muted = Color(0xFF78909C);
  static const Color placeholder = Color(0x1A263238);
}

class AppRadius {
  static const double card = 16;
  static const double sheet = 28;
}

const String kAttributionUrl = 'https://pokeapi.co';

/// 18 tipe Pokémon (nilai ini juga dipakai sebagai parameter endpoint /type/{nama}).
const List<String> kTypes = [
  'normal', 'fire', 'water', 'electric', 'grass', 'ice',
  'fighting', 'poison', 'ground', 'flying', 'psychic', 'bug',
  'rock', 'ghost', 'dragon', 'dark', 'steel', 'fairy',
];

const Map<String, Color> kTypeColors = {
  'normal': Color(0xFFA8A77A),
  'fire': Color(0xFFEE8130),
  'water': Color(0xFF6390F0),
  'electric': Color(0xFFF7D02C),
  'grass': Color(0xFF7AC74C),
  'ice': Color(0xFF96D9D6),
  'fighting': Color(0xFFC22E28),
  'poison': Color(0xFFA33EA1),
  'ground': Color(0xFFE2BF65),
  'flying': Color(0xFFA98FF3),
  'psychic': Color(0xFFF95587),
  'bug': Color(0xFFA6B91A),
  'rock': Color(0xFFB6A136),
  'ghost': Color(0xFF735797),
  'dragon': Color(0xFF6F35FC),
  'dark': Color(0xFF705746),
  'steel': Color(0xFFB7B7CE),
  'fairy': Color(0xFFD685AD),
};

Color typeColor(String type) => kTypeColors[type] ?? AppColors.muted;
