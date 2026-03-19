class Helpers {
  static String generateReceiptNumber() {
    final now = DateTime.now();
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final randomPart = (now.millisecondsSinceEpoch % 10000).toString().padLeft(4, '0');
    return 'INV-$dateStr-$randomPart';
  }

  static String getCurrentTimestamp() {
    return DateTime.now().toIso8601String();
  }
}
