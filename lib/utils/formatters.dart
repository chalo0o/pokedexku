/// "mr-mime" -> "Mr Mime"
String titleCase(String s) => s
    .split(RegExp(r'[-\s]'))
    .where((w) => w.isNotEmpty)
    .map((w) => w[0].toUpperCase() + w.substring(1))
    .join(' ');

/// 25 -> "#025"
String dexNumber(int id) => '#${id.toString().padLeft(3, '0')}';
