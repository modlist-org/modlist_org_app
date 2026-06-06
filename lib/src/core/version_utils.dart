class VersionUtils {
  /// Returns [true] if the [latest] version is strictly greater/newer than [current].
  static bool isNewerVersion(String current, String latest) {
    final cleanCurrent = current.replaceAll(RegExp(r'[^\d.]'), '');
    final cleanLatest = latest.replaceAll(RegExp(r'[^\d.]'), '');

    if (cleanCurrent.isEmpty && cleanLatest.isEmpty) return false;
    if (cleanCurrent.isEmpty) return true;
    if (cleanLatest.isEmpty) return false;

    final currentParts = cleanCurrent.split('.').map(int.tryParse).toList();
    final latestParts = cleanLatest.split('.').map(int.tryParse).toList();

    final maxLength = currentParts.length > latestParts.length
        ? currentParts.length
        : latestParts.length;

    for (int i = 0; i < maxLength; i++) {
      final currentVal = i < currentParts.length ? (currentParts[i] ?? 0) : 0;
      final latestVal = i < latestParts.length ? (latestParts[i] ?? 0) : 0;
      if (latestVal > currentVal) return true;
      if (currentVal > latestVal) return false;
    }
    return false;
  }
}
