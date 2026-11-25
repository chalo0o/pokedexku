import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Abstraksi kecil supaya halaman kuis bisa di-test tanpa plugin.
abstract class Notifier {
  Future<bool> initialize();
  Future<void> scheduleDailyReminder({required bool enabled});
  Future<void> showQuizResult({required bool correct});
}

/// Notifikasi lokal: pengingat harian jam 19.00 dan hasil kuis.
class NotificationService implements Notifier {
  static const int _dailyId = 0;
  static const int _resultId = 1;
  static bool _timezonesReady = false;

  final FlutterLocalNotificationsPlugin _plugin;
  Future<bool>? _initializeFuture;

  NotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  AndroidNotificationDetails get _details => const AndroidNotificationDetails(
    'uas_pokedexku',
    'Pengingat Pokédexku',
    channelDescription: 'Notifikasi harian dan hasil kuis Pokédexku.',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );

  @override
  Future<bool> initialize() {
    return _initializeFuture ??= _initialize();
  }

  Future<bool> _initialize() async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    final initialized = await _plugin.initialize(settings) ?? false;
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final permission = await android?.requestNotificationsPermission() ?? true;
    return initialized && permission;
  }

  @override
  Future<void> scheduleDailyReminder({required bool enabled}) async {
    if (!enabled) {
      await _plugin.cancel(_dailyId);
      return;
    }
    if (!_timezonesReady) {
      tz_data.initializeTimeZones();
      _timezonesReady = true;
    }

    // DateTime.now() memakai jam lokal perangkat; toUtc() mengubahnya menjadi
    // titik waktu absolut yang dipahami penjadwal plugin.
    final now = DateTime.now();
    var target = DateTime(now.year, now.month, now.day, 19);
    if (!target.isAfter(now)) {
      target = target.add(const Duration(days: 1));
    }
    final scheduled = tz.TZDateTime.from(target.toUtc(), tz.UTC);

    try {
      await _plugin.zonedSchedule(
        _dailyId,
        'Pokédexku',
        'Yuk lanjut jelajah Pokédexku hari ini!',
        scheduled,
        NotificationDetails(android: _details),
        androidScheduleMode: AndroidScheduleMode.inexact,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'daily_reminder',
      );
    } on UnsupportedError {
      // Desktop/Web tidak mendukung alarm; kuis tetap bisa dipakai.
    }
  }

  @override
  Future<void> showQuizResult({required bool correct}) async {
    try {
      await _plugin.show(
        _resultId,
        'Hasil Tantangan',
        correct
            ? 'Benar! Streak kamu bertambah.'
            : 'Belum tepat. Coba lagi soal berikutnya!',
        NotificationDetails(android: _details),
        payload: 'quiz_result',
      );
    } on UnsupportedError {
      // Platform tanpa notifikasi lokal memakai SnackBar dari halaman kuis.
    }
  }
}
