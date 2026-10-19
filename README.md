# Pokédexku

Aplikasi Pokédex berbasis Flutter yang mengambil data dari **PokéAPI**.

## Deskripsi
Pokédexku menampilkan daftar Pokémon beserta gambar, tipe, kemampuan, ukuran, dan statistik dasar. Seluruh data diambil secara dinamis melalui permintaan HTTP ke PokéAPI.

## Fitur Utama
- Beranda: pencarian, pintasan 18 tipe Pokémon, dan "Pilihan Hari Ini" (acak)
- Daftar Pokédex dengan paginasi (20 per halaman, muat otomatis saat scroll)
- Filter berdasarkan tipe
- Pencarian berdasarkan nama atau nomor
- Detail Pokémon: deskripsi, tipe, tinggi, berat, kemampuan, bar statistik
- Penanganan loading, success, dan error (dengan tombol "Coba Lagi")
- Tarik layar ke bawah untuk memuat ulang

## Teknologi dan Package
- Flutter dan Dart
- `http`: permintaan API
- `google_fonts`: font Poppins
- `url_launcher`: membuka tautan atribusi

## Sumber Data
- API: https://pokeapi.co/api/v2/ ([PokéAPI](https://pokeapi.co))
- Gambar: repositori sprites PokéAPI di GitHub
- Pokémon dan nama karakternya adalah merek dagang Nintendo. Aplikasi ini dibuat untuk keperluan pembelajaran.

## Struktur Folder
```
lib/
├── main.dart
├── models/      # PokemonSummary, PokemonPage, PokemonDetail
├── services/    # PokemonApiService (HTTP)
├── pages/       # home, list, detail
├── widgets/     # pokemon_card, error_view, loading_view, dll.
└── utils/       # constants, formatters, launcher
```

## Cara Menjalankan
1. Pasang Flutter SDK dan jalankan `flutter doctor`.
2. Clone repositori ini.
3. Jalankan:
```
flutter pub get
flutter run
```
Gunakan emulator atau perangkat Android dengan koneksi internet (bukan Chrome/web).
