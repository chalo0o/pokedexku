import 'package:shared_preferences/shared_preferences.dart';

/// Penyimpanan lokal untuk skor kuis dan preferensi notifikasi UAS.
class GameStorage {
  static const String _scoreKey = 'uas_score';
  static const String _bestScoreKey = 'uas_best_score';
  static const String _streakKey = 'uas_streak';
  static const String _bestStreakKey = 'uas_best_streak';
  static const String _notificationsKey = 'uas_notifications';

  SharedPreferences? _prefs;

  int _score = 0;
  int _bestScore = 0;
  int _streak = 0;
  int _bestStreak = 0;
  bool _notificationsEnabled = true;

  int get score => _score;
  int get bestScore => _bestScore;
  int get streak => _streak;
  int get bestStreak => _bestStreak;
  bool get notificationsEnabled => _notificationsEnabled;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    _score = _prefs!.getInt(_scoreKey) ?? 0;
    _bestScore = _prefs!.getInt(_bestScoreKey) ?? 0;
    _streak = _prefs!.getInt(_streakKey) ?? 0;
    _bestStreak = _prefs!.getInt(_bestStreakKey) ?? 0;
    _notificationsEnabled = _prefs!.getBool(_notificationsKey) ?? true;
  }

  Future<void> recordAnswer({required bool correct}) async {
    if (correct) {
      _score += 1;
      _streak += 1;
      if (_score > _bestScore) {
        _bestScore = _score;
      }
      if (_streak > _bestStreak) {
        _bestStreak = _streak;
      }
    } else {
      _streak = 0;
    }
    await _save();
  }

  Future<void> resetSession() async {
    _score = 0;
    _streak = 0;
    await _save();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    await _save();
  }

  Future<void> _save() async {
    final prefs = _prefs;
    if (prefs == null) {
      return;
    }
    await prefs.setInt(_scoreKey, _score);
    await prefs.setInt(_bestScoreKey, _bestScore);
    await prefs.setInt(_streakKey, _streak);
    await prefs.setInt(_bestStreakKey, _bestStreak);
    await prefs.setBool(_notificationsKey, _notificationsEnabled);
  }
}
