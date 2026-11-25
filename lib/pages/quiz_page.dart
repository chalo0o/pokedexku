import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/evolution_api_service.dart';
import '../services/game_storage.dart';
import '../services/notification_service.dart';
import '../services/pokemon_api_service.dart';
import '../services/quiz_engine.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/app_header.dart';

/// Halaman 4: Tebak evolusi berikutnya dengan skor tersimpan.
class QuizPage extends StatefulWidget {
  final GameStorage storage;
  final PokemonApiService listApi;
  final EvolutionApiService api;
  final Notifier notifier;
  final Random random;

  QuizPage({
    super.key,
    required this.storage,
    required this.listApi,
    required this.api,
    Notifier? notifier,
    Random? random,
  }) : notifier = notifier ?? NotificationService(),
       random = random ?? Random();

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  QuizQuestion? _question;
  QuizEngine? _engine;
  bool _isLoading = true;
  bool _answered = false;
  bool _lastCorrect = false;
  bool _notificationsEnabled = true;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    _notificationsEnabled = widget.storage.notificationsEnabled;
    _startSession();
  }

  /// Skor sesi direset, sedangkan skor/streak terbaik tetap tersimpan.
  Future<void> _startSession() async {
    await widget.storage.resetSession();
    if (!mounted) {
      return;
    }
    setState(() {});
    _initializeNotifications();
    _loadQuestion();
  }

  Future<void> _initializeNotifications() async {
    final allowed = await widget.notifier.initialize();
    if (!mounted) {
      return;
    }
    if (!allowed && _notificationsEnabled) {
      await widget.storage.setNotificationsEnabled(false);
      setState(() => _notificationsEnabled = false);
      await widget.notifier.scheduleDailyReminder(enabled: false);
      return;
    }
    await widget.notifier.scheduleDailyReminder(enabled: _notificationsEnabled);
  }

  Future<void> _loadQuestion() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _question = null;
        _answered = false;
        _loadError = null;
      });
    }

    QuizQuestion? question;
    QuizEngine? engine;
    Object? error;
    try {
      final page = await widget.listApi.fetchPage(limit: 100);
      final names = page.results.map((pokemon) => pokemon.name).toList();
      final shuffled = List<String>.of(names)..shuffle(widget.random);
      for (final name in shuffled.take(5)) {
        final species = await widget.api.fetchSpecies(name);
        // Kuis hanya butuh nama, jadi lewati fetch sprite/tipe per tahap.
        final chain = await widget.api.fetchChain(
          species.chainId,
          enrich: false,
        );
        final candidate = QuizEngine(
          chain: chain,
          randomNames: names,
          random: widget.random,
        );
        final built = candidate.buildQuestion();
        if (built != null) {
          question = built;
          engine = candidate;
          break;
        }
      }
    } catch (caught) {
      error = caught;
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _question = question;
      _engine = engine;
      _loadError = error;
      _isLoading = false;
    });
  }

  Future<void> _answer(String option) async {
    final question = _question;
    final engine = _engine;
    if (question == null || engine == null || _answered) {
      return;
    }
    final correct = engine.isCorrect(option, question);
    await widget.storage.recordAnswer(correct: correct);
    await widget.notifier.showQuizResult(correct: correct);
    if (!mounted) {
      return;
    }
    setState(() {
      _answered = true;
      _lastCorrect = correct;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          correct
              ? 'Benar! Jawabannya ${titleCase(question.correctAnswer)}.'
              : 'Belum tepat. Jawabannya ${titleCase(question.correctAnswer)}.',
        ),
      ),
    );
  }

  Future<void> _toggleNotifications(bool value) async {
    if (value) {
      final allowed = await widget.notifier.initialize();
      if (!allowed) {
        await widget.storage.setNotificationsEnabled(false);
        await widget.notifier.scheduleDailyReminder(enabled: false);
        if (mounted) {
          setState(() => _notificationsEnabled = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Izin notifikasi ditolak. Aktifkan di pengaturan sistem.',
              ),
            ),
          );
        }
        return;
      }
    }
    await widget.storage.setNotificationsEnabled(value);
    await widget.notifier.scheduleDailyReminder(enabled: value);
    if (mounted) {
      setState(() => _notificationsEnabled = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final storage = widget.storage;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppHeader(
                title: 'Tantangan',
                subtitle: 'Tebak evolusi berikutnya dari Pokémon.',
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        _stat('Skor: ${storage.score}'),
                        _stat('Streak: ${storage.streak}'),
                        _stat('Terbaik: ${storage.bestScore}'),
                        _stat('Streak terbaik: ${storage.bestStreak}'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildQuestion(),
                    const SizedBox(height: 24),
                    Card(
                      color: AppColors.card,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.card),
                      ),
                      child: SwitchListTile(
                        title: Text(
                          'Notifikasi harian',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: AppColors.text,
                          ),
                        ),
                        subtitle: Text(
                          'Pengingat buat lanjut main jam 19.00.',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppColors.muted,
                          ),
                        ),
                        value: _notificationsEnabled,
                        onChanged: _toggleNotifications,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(String label) {
    return Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.text,
      ),
    );
  }

  Widget _buildQuestion() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    final error = _loadError;
    if (error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gagal memuat soal: $error',
            style: GoogleFonts.poppins(fontSize: 13, color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _loadQuestion,
            child: const Text('Coba lagi'),
          ),
        ],
      );
    }
    final question = _question;
    if (question == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Belum ada soal yang bisa dibuat.',
            style: GoogleFonts.poppins(color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _loadQuestion,
            child: const Text('Coba lagi'),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          question.prompt,
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 16),
        for (final option in question.options) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _answered ? null : () => _answer(option),
              child: Text(
                titleCase(option),
                style: GoogleFonts.poppins(color: AppColors.text),
              ),
            ),
          ),
        ],
        if (_answered) ...[
          const SizedBox(height: 8),
          Text(
            _lastCorrect ? 'Kamu benar! 🎉' : 'Belum tepat, coba lagi ya.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: _lastCorrect ? AppColors.primaryDark : AppColors.muted,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: _loadQuestion,
            icon: const Icon(Icons.refresh),
            label: const Text('Soal berikutnya'),
          ),
        ],
      ],
    );
  }
}
