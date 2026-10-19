import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Membuka tautan di browser luar.
Future<void> openUrl(BuildContext context, String url) async {
  final messenger = ScaffoldMessenger.of(context);
  final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  if (!ok) {
    messenger.showSnackBar(const SnackBar(content: Text('Tidak dapat membuka tautan.')));
  }
}
