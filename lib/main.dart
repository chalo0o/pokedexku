import 'package:flutter/material.dart';

import 'pages/evolution_page.dart';
import 'pages/home_page.dart';
import 'pages/list_page.dart';
import 'pages/quiz_page.dart';
import 'services/evolution_api_service.dart';
import 'services/game_storage.dart';
import 'services/notification_service.dart';
import 'services/pokemon_api_service.dart';
import 'utils/constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = GameStorage();
  await storage.init();
  final notifier = NotificationService();
  try {
    await notifier.initialize();
  } catch (_) {
    // Izin/gagal inisialisasi tidak boleh menghalangi tampilan pertama.
  }
  runApp(PokedexApp(storage: storage, notifier: notifier));
}

class PokedexApp extends StatelessWidget {
  final GameStorage storage;
  final Notifier notifier;

  const PokedexApp({super.key, required this.storage, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pokédexku',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        useMaterial3: true,
      ),
      home: MainShell(storage: storage, notifier: notifier),
    );
  }
}

/// Kerangka utama dengan BottomNavigationBar (4 halaman UAS).
class MainShell extends StatefulWidget {
  final GameStorage storage;
  final Notifier notifier;

  const MainShell({super.key, required this.storage, required this.notifier});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  final PokemonApiService _listApi = PokemonApiService();
  final EvolutionApiService _evolutionApi = EvolutionApiService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomePage(onSeeAll: () => setState(() => _index = 1)),
          const ListPage(),
          const EvolutionPage(),
          QuizPage(
            storage: widget.storage,
            listApi: _listApi,
            api: _evolutionApi,
            notifier: widget.notifier,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.muted,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.catching_pokemon),
            label: 'Pokédex',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_tree_outlined),
            activeIcon: Icon(Icons.account_tree),
            label: 'Evolusi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.quiz_outlined),
            activeIcon: Icon(Icons.quiz),
            label: 'Tantangan',
          ),
        ],
      ),
    );
  }
}
