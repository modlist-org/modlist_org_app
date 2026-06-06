import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

class DebugLog {
  static Future<File>? _logFileFuture;

  static bool get enabled => kDebugMode;

  static String? get filePath {
    if (!enabled) return null;
    return _defaultLogPath();
  }

  static Future<void> info(String message) async {
    await _write(message);
  }

  static Future<void> error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) async {
    await _write(message, error: error, stackTrace: stackTrace);
  }

  static Future<void> _write(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) async {
    if (!enabled) return;

    final timestamp = DateTime.now().toIso8601String();
    final buffer = StringBuffer('[$timestamp] $message');
    if (error != null) {
      buffer.write('\n  error: $error');
    }
    if (stackTrace != null) {
      buffer.write('\n  stack: $stackTrace');
    }

    final line = buffer.toString();
    debugPrint(line);

    try {
      final file = await _logFile();
      await file.writeAsString('$line\n', mode: FileMode.append, flush: true);
    } catch (_) {
      // Debug logging should never break installer behavior.
    }
  }

  static Future<File> _logFile() {
    return _logFileFuture ??= _createLogFile();
  }

  static Future<File> _createLogFile() async {
    final path = _defaultLogPath();
    final file = File(path);
    await file.parent.create(recursive: true);
    if (!await file.exists()) {
      await file.create();
    }
    return file;
  }

  static String _defaultLogPath() {
    final home =
        Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        '';

    if (Platform.isMacOS && home.isNotEmpty) {
      return p.join(home, 'Library', 'Logs', 'modlist_org_app', 'debug.log');
    }

    if (Platform.isWindows) {
      final base = Platform.environment['LOCALAPPDATA'] ?? home;
      if (base.isNotEmpty) {
        return p.join(base, 'modlist_org_app', 'Logs', 'debug.log');
      }
    }

    if (Platform.isLinux && home.isNotEmpty) {
      final base =
          Platform.environment['XDG_STATE_HOME'] ??
          p.join(home, '.local', 'state');
      return p.join(base, 'modlist_org_app', 'debug.log');
    }

    return p.join(Directory.systemTemp.path, 'modlist_org_app_debug.log');
  }
}
