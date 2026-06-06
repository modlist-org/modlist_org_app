String describeAppError(Object error) {
  final raw = _stripExceptionPrefixes(error.toString()).trim();
  final lower = raw.toLowerCase();

  final host = RegExp(r"failed host lookup: '([^']+)'")
      .firstMatch(raw)
      ?.group(1);
  if (host != null && host.isNotEmpty) {
    return 'Cannot reach $host. Check your internet connection, DNS, or firewall and try again.';
  }

  if (lower.contains('socketexception') ||
      lower.contains('clientexception') ||
      lower.contains('connection refused') ||
      lower.contains('connection reset')) {
    return 'Network connection failed. Check your internet connection and try again.';
  }

  if (lower.contains('timeout') || lower.contains('timed out')) {
    return 'Network request timed out. Check your connection and try again.';
  }

  if (lower.contains('operation not permitted') ||
      lower.contains('permission denied')) {
    return 'Permission denied. Select the game folder manually or relaunch the updated app.';
  }

  if (raw.isEmpty) {
    return 'Unknown error.';
  }
  return raw;
}

String _stripExceptionPrefixes(String value) {
  var result = value;
  const prefixes = [
    'Exception: ',
    'ClientException with SocketException: ',
    'ClientException: ',
  ];

  var changed = true;
  while (changed) {
    changed = false;
    for (final prefix in prefixes) {
      if (result.startsWith(prefix)) {
        result = result.substring(prefix.length);
        changed = true;
      }
    }
  }

  return result;
}
