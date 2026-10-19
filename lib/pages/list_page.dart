import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/pokemon_model.dart';
import '../services/pokemon_api_service.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/app_header.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';
import '../widgets/pokemon_card.dart';
import '../widgets/search_box.dart';

/// Halaman 2: Pokédex. Mode: semua (paginasi 20 per halaman), filter tipe, atau pencarian.
class ListPage extends StatefulWidget {
  final String? type; // nilai API, misalnya 'fire'
  final String query;
  final bool showBack;

  const ListPage({super.key, this.type, this.query = '', this.showBack = false});

  @override
  State<ListPage> createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
  static const int _pageSize = 20;

  final _api = PokemonApiService();
  final _scroll = ScrollController();
  late final TextEditingController _controller;
  late Future<void> _future;

  final List<PokemonSummary> _items = [];
  String? _type;
  String _query = '';
  bool _hasMore = false;
  bool _loadingMore = false;
  String? _moreError;
  int _token = 0; // mencegah hasil permintaan lama menimpa yang baru

  @override
  void initState() {
    super.initState();
    _type = widget.type;
    _query = widget.query;
    _controller = TextEditingController(text: widget.query);
    _scroll.addListener(_onScroll);
    _future = _loadFirst();
  }

  @override
  void dispose() {
    _scroll.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// Memuat data awal sesuai mode yang aktif.
  Future<void> _loadFirst() async {
    final token = ++_token;
    List<PokemonSummary> result;
    var more = false;

    if (_query.isNotEmpty) {
      result = await _api.searchByName(_query);
    } else if (_type != null) {
      result = await _api.fetchByType(_type!);
    } else {
      final page = await _api.fetchPage(limit: _pageSize, offset: 0);
      result = page.results;
      more = page.hasNext;
    }

    if (token != _token) return;
    _items
      ..clear()
      ..addAll(result);
    _hasMore = more;
    _moreError = null;
  }

  /// Memuat halaman berikutnya (paginasi) saat scroll mendekati dasar.
  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() {
      _loadingMore = true;
      _moreError = null;
    });
    final token = _token;
    try {
      final page = await _api.fetchPage(limit: _pageSize, offset: _items.length);
      if (!mounted || token != _token) return;
      setState(() {
        _items.addAll(page.results);
        _hasMore = page.hasNext;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingMore = false;
        _moreError = e.toString();
      });
    }
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  void _reload() => setState(() {
        _loadingMore = false;
        _future = _loadFirst();
      });

  Future<void> _refresh() async {
    _reload();
    try {
      await _future;
    } catch (_) {/* error ditampilkan oleh FutureBuilder */}
  }

  void _search(String q) {
    _type = null;
    _query = q.trim();
    _reload();
  }

  void _clearSearch() {
    _controller.clear();
    _query = '';
    _reload();
  }

  void _selectType(String? type) {
    _controller.clear();
    _query = '';
    _type = type;
    _reload();
  }

  String get _title {
    if (_query.isNotEmpty) return 'Hasil "$_query"';
    if (_type != null) return 'Tipe ${titleCase(_type!)}';
    return 'Semua Pokémon';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            title: 'Pokédex',
            subtitle: 'Jelajahi semua Pokémon.',
            showBack: widget.showBack,
            bottom: SearchBox(
              controller: _controller,
              onSubmitted: _search,
              onClear: _clearSearch,
            ),
          ),
          _typeChips(),
          Expanded(
            child: FutureBuilder<void>(
              future: _future,
              builder: (context, snap) {
                // 1. LOADING
                if (snap.connectionState != ConnectionState.done) {
                  return const LoadingView(message: 'Memuat daftar Pokémon...');
                }
                // 2. ERROR
                if (snap.hasError) {
                  return ErrorView(error: snap.error!, onRetry: _reload);
                }
                // 3. SUCCESS
                return _content();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _content() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(_title,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.text)),
              ),
              Text('${_items.length}${_hasMore ? '+' : ''} Pokémon',
                  style: GoogleFonts.poppins(fontSize: 11, color: AppColors.muted)),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: _items.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 80),
                      Center(
                        child: Text('Tidak ada Pokémon ditemukan.',
                            style: GoogleFonts.poppins(color: AppColors.muted)),
                      ),
                    ],
                  )
                : CustomScrollView(
                    controller: _scroll,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverGrid(
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 170,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.85,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => PokemonCard(pokemon: _items[i]),
                            childCount: _items.length,
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(child: _footer()),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _footer() {
    Widget child;
    if (_loadingMore) {
      child = const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary));
    } else if (_moreError != null) {
      child = TextButton.icon(
        onPressed: _loadMore,
        icon: const Icon(Icons.refresh, color: AppColors.primary),
        label: Text('Gagal memuat. Coba lagi',
            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.primary)),
      );
    } else if (!_hasMore) {
      child = Text('- akhir daftar -',
          style: GoogleFonts.poppins(fontSize: 11, color: AppColors.muted));
    } else {
      child = const SizedBox.shrink();
    }
    return Padding(padding: const EdgeInsets.all(20), child: Center(child: child));
  }

  Widget _typeChips() {
    final noFilter = _type == null && _query.isEmpty;
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          _chip('Semua', noFilter, AppColors.primary, () => _selectType(null)),
          for (final t in kTypes)
            _chip(titleCase(t), _type == t && _query.isEmpty, typeColor(t), () => _selectType(t)),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, Color color, VoidCallback onTap) {
    final fg = selected && color.computeLuminance() <= 0.5 ? Colors.white : AppColors.text;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: GoogleFonts.poppins(fontSize: 12, color: fg)),
        selected: selected,
        selectedColor: color,
        backgroundColor: Colors.white,
        showCheckmark: false,
        onSelected: (_) => onTap(),
      ),
    );
  }
}
