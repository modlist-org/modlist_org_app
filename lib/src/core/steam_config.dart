import 'dart:io';
import 'package:path/path.dart' as p;

/// Result of a Steam Launch Options write/clear.
class SteamLaunchOptionsResult {
  /// Number of per-account `localconfig.vdf` files that were updated (or
  /// already held the desired value).
  final int updatedCount;

  /// Whether Steam appeared to be running when the edit happened. Steam
  /// rewrites `localconfig.vdf` on exit, so edits made while it is running do
  /// not stick until it is fully restarted.
  final bool steamRunning;

  /// Whether any `localconfig.vdf` file was found at all.
  final bool configFound;

  const SteamLaunchOptionsResult({
    required this.updatedCount,
    required this.steamRunning,
    required this.configFound,
  });

  bool get applied => updatedCount > 0;

  static const SteamLaunchOptionsResult none = SteamLaunchOptionsResult(
    updatedCount: 0,
    steamRunning: false,
    configFound: false,
  );
}

/// Reads and edits Steam's per-account `localconfig.vdf` to set (or clear) the
/// Launch Options for a given app, so the MelonLoader `setup_helper.sh` wrapper
/// runs automatically. We do a targeted edit (backing the file up first) rather
/// than a full re-serialize, so the rest of the file is preserved byte-for-byte.
///
/// Ported from the reference Swift implementation in sbrothers7/UMMInstall.
class SteamConfig {
  // ASCII code units used while scanning the (mostly-ASCII) VDF structure.
  static const int _quote = 0x22; // "
  static const int _backslash = 0x5C; // \
  static const int _openBrace = 0x7B; // {
  static const int _closeBrace = 0x7D; // }
  static const int _space = 0x20;
  static const int _tab = 0x09;
  static const int _nl = 0x0A;
  static const int _cr = 0x0D;

  static int _lower(int c) => (c >= 0x41 && c <= 0x5A) ? c + 0x20 : c;

  // MARK: - Public API

  /// Sets the Launch Options for [appId] to [value] across every Steam account
  /// on this machine. [value] is the raw Steam Launch Options string (e.g.
  /// `"/path/setup_helper.sh" %command%`); embedded quotes/backslashes are
  /// escaped before being written into the VDF.
  static Future<SteamLaunchOptionsResult> setLaunchOptions({
    required String appId,
    required String value,
  }) async {
    final paths = _localConfigPaths();
    final running = await isSteamRunning();
    if (paths.isEmpty) {
      return SteamLaunchOptionsResult(
        updatedCount: 0,
        steamRunning: running,
        configFound: false,
      );
    }

    final escaped = value
        .replaceAll('\\', r'\\')
        .replaceAll('"', r'\"');

    var updated = 0;
    for (final path in paths) {
      String text;
      try {
        text = await File(path).readAsString();
      } catch (_) {
        continue;
      }
      final newText = setLaunchOptionsInVdf(
        text,
        appId: appId,
        escapedValue: escaped,
      );
      if (newText == null) continue;
      if (newText == text) {
        updated++;
        continue;
      }
      if (await _backupAndWrite(path, newText)) {
        updated++;
      }
    }

    return SteamLaunchOptionsResult(
      updatedCount: updated,
      steamRunning: running,
      configFound: true,
    );
  }

  /// Clears the Launch Options we set for [appId] — but only when the current
  /// value still references one of our wrappers, so a user's own custom option
  /// is left untouched.
  static Future<SteamLaunchOptionsResult> clearLaunchOptions({
    required String appId,
  }) async {
    final paths = _localConfigPaths();
    final running = await isSteamRunning();
    if (paths.isEmpty) {
      return SteamLaunchOptionsResult(
        updatedCount: 0,
        steamRunning: running,
        configFound: false,
      );
    }

    var updated = 0;
    for (final path in paths) {
      String text;
      try {
        text = await File(path).readAsString();
      } catch (_) {
        continue;
      }
      final newText = clearLaunchOptionsInVdf(text, appId: appId);
      if (newText == null || newText == text) continue;
      if (await _backupAndWrite(path, newText)) {
        updated++;
      }
    }

    return SteamLaunchOptionsResult(
      updatedCount: updated,
      steamRunning: running,
      configFound: true,
    );
  }

  /// Best-effort check of whether the Steam client is currently running.
  static Future<bool> isSteamRunning() async {
    try {
      if (Platform.isWindows) {
        final r = await Process.run('tasklist', [
          '/FI',
          'IMAGENAME eq steam.exe',
          '/NH',
        ]);
        return r.stdout.toString().toLowerCase().contains('steam.exe');
      }
      // macOS process is `steam_osx`; Linux is `steam`. `pgrep -i steam`
      // matches both (and the helper processes), which is all we need here.
      final r = await Process.run('pgrep', ['-i', 'steam']);
      return r.exitCode == 0 && r.stdout.toString().trim().isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // MARK: - Pure VDF editing (filesystem-free, unit-testable)

  /// Returns [text] with app [appId]'s LaunchOptions set to [escapedValue]
  /// (already VDF-escaped, without surrounding quotes), or null if the file's
  /// `apps` structure couldn't be located.
  static String? setLaunchOptionsInVdf(
    String text, {
    required String appId,
    required String escapedValue,
  }) {
    final chars = List<int>.of(text.codeUnits);

    // The relevant app block lives inside Steam's "apps" block; scope the
    // search there so an unrelated id elsewhere in the file can't match.
    final apps = _blockRange(chars, 'apps', 0, chars.length);
    if (apps == null) return null;

    final block = _blockRange(chars, appId, apps.start, apps.end);
    if (block != null) {
      final valueRange = _launchOptionsValueRange(chars, block.start, block.end);
      if (valueRange != null) {
        chars.replaceRange(
          valueRange.start,
          valueRange.end,
          '"$escapedValue"'.codeUnits,
        );
        return String.fromCharCodes(chars);
      }
      // App block exists but has no LaunchOptions yet — insert one.
      final insertion = '\n\t\t\t\t\t"LaunchOptions"\t\t"$escapedValue"'.codeUnits;
      chars.insertAll(block.start, insertion);
      return String.fromCharCodes(chars);
    }

    // No app block — insert one at the start of the "apps" block.
    final insertion =
        '\n\t\t\t\t"$appId"\n\t\t\t\t{\n\t\t\t\t\t"LaunchOptions"\t\t"$escapedValue"\n\t\t\t\t}'
            .codeUnits;
    chars.insertAll(apps.start, insertion);
    return String.fromCharCodes(chars);
  }

  /// Returns [text] with app [appId]'s LaunchOptions blanked, or null if there
  /// is nothing of ours to clear (no block, no value, or a value that doesn't
  /// reference one of our wrappers).
  static String? clearLaunchOptionsInVdf(String text, {required String appId}) {
    final chars = List<int>.of(text.codeUnits);

    final apps = _blockRange(chars, 'apps', 0, chars.length);
    if (apps == null) return null;
    final block = _blockRange(chars, appId, apps.start, apps.end);
    if (block == null) return null;
    final valueRange = _launchOptionsValueRange(chars, block.start, block.end);
    if (valueRange == null) return null;

    final current = String.fromCharCodes(
      chars.sublist(valueRange.start, valueRange.end),
    );
    if (!current.contains('setup_helper.sh') &&
        !current.contains('WINEDLLOVERRIDES')) {
      return null;
    }

    chars.replaceRange(valueRange.start, valueRange.end, '""'.codeUnits);
    return String.fromCharCodes(chars);
  }

  // MARK: - VDF scanning primitives

  /// Finds a `"key"` (case-insensitive) within `[rangeStart, rangeEnd)` that is
  /// followed by a `{ … }` block, returning the body range (just after `{` up
  /// to the matching `}`). The key appears many times in localconfig.vdf
  /// (key/value pairs, hex blobs); only some are blocks, so scan every match.
  static _Range? _blockRange(
    List<int> chars,
    String key,
    int rangeStart,
    int rangeEnd,
  ) {
    final needle = <int>[_quote, ...key.toLowerCase().codeUnits, _quote];
    final n = needle.length;
    if (rangeEnd - rangeStart < n) return null;

    var i = rangeStart;
    while (i <= rangeEnd - n) {
      if (chars[i] != _quote) {
        i++;
        continue;
      }
      var k = 0;
      while (k < n && _lower(chars[i + k]) == needle[k]) {
        k++;
      }
      if (k != n) {
        i++;
        continue;
      }

      // After the key, the next non-whitespace char must be `{`.
      var j = i + n;
      while (j < chars.length &&
          (chars[j] == _space ||
              chars[j] == _tab ||
              chars[j] == _nl ||
              chars[j] == _cr)) {
        j++;
      }
      if (j < chars.length && chars[j] == _openBrace) {
        final body = _matchBraces(chars, j);
        if (body != null) return body;
      }
      i++;
    }
    return null;
  }

  /// Given the index of `{`, returns the body range (after `{` to its match
  /// `}`), honoring quoted strings so braces inside values don't miscount.
  static _Range? _matchBraces(List<int> chars, int openBrace) {
    final bodyStart = openBrace + 1;
    var depth = 1;
    var j = bodyStart;
    while (j < chars.length) {
      final c = chars[j];
      if (c == _quote) {
        j = _skipQuoted(chars, j);
        continue;
      }
      if (c == _openBrace) {
        depth++;
      } else if (c == _closeBrace) {
        depth--;
        if (depth == 0) return _Range(bodyStart, j);
      }
      j++;
    }
    return null;
  }

  /// Within `[bodyStart, bodyEnd)`, finds `"LaunchOptions"` (case-insensitive)
  /// and returns the range of its value token, including surrounding quotes.
  static _Range? _launchOptionsValueRange(
    List<int> chars,
    int bodyStart,
    int bodyEnd,
  ) {
    final needle = <int>[_quote, ...'launchoptions'.codeUnits, _quote];
    final n = needle.length;
    var i = bodyStart;
    while (i <= bodyEnd - n) {
      if (chars[i] == _quote) {
        var k = 0;
        while (k < n && _lower(chars[i + k]) == needle[k]) {
          k++;
        }
        if (k == n) {
          // Skip whitespace to the value's opening quote.
          var v = i + n;
          while (v < bodyEnd && (chars[v] == _space || chars[v] == _tab)) {
            v++;
          }
          if (v >= bodyEnd || chars[v] != _quote) return null;
          final end = _skipQuoted(chars, v); // index just past closing quote
          return _Range(v, end);
        }
      }
      i++;
    }
    return null;
  }

  /// Given the index of an opening `"`, returns the index just past the closing
  /// `"`, honoring `\"` escapes.
  static int _skipQuoted(List<int> chars, int openQuote) {
    var i = openQuote + 1;
    while (i < chars.length) {
      if (chars[i] == _backslash) {
        i += 2;
        continue;
      }
      if (chars[i] == _quote) return i + 1;
      i++;
    }
    return i;
  }

  // MARK: - Filesystem helpers

  /// Every existing `userdata/<id>/config/localconfig.vdf` across all detected
  /// Steam install roots, de-duplicated.
  static List<String> _localConfigPaths() {
    final paths = <String>{};
    for (final root in _steamRoots()) {
      final userdata = Directory(p.join(root, 'userdata'));
      if (!userdata.existsSync()) continue;
      try {
        for (final entity in userdata.listSync(followLinks: false)) {
          if (entity is Directory) {
            final cfg = File(p.join(entity.path, 'config', 'localconfig.vdf'));
            if (cfg.existsSync()) paths.add(cfg.path);
          }
        }
      } catch (_) {}
    }
    return paths.toList();
  }

  /// Candidate Steam install roots per platform (mirrors the detection used for
  /// locating game installs elsewhere in the app).
  static List<String> _steamRoots() {
    final env = Platform.environment;
    final home = env['HOME'] ?? env['USERPROFILE'] ?? '';
    final roots = <String>[];

    if (Platform.isWindows) {
      final pf86 = env['ProgramFiles(x86)'] ?? env['PROGRAMFILES(X86)'];
      final pf = env['ProgramFiles'];
      if (pf86 != null && pf86.isNotEmpty) roots.add(p.join(pf86, 'Steam'));
      if (pf != null && pf.isNotEmpty) roots.add(p.join(pf, 'Steam'));
      roots.add(r'C:\Program Files (x86)\Steam');
      roots.add(r'C:\Program Files\Steam');
    } else if (Platform.isMacOS) {
      roots.add(p.join(home, 'Library', 'Application Support', 'Steam'));
    } else {
      roots.add(p.join(home, '.steam', 'steam'));
      roots.add(p.join(home, '.steam', 'root'));
      roots.add(p.join(home, '.local', 'share', 'Steam'));
      roots.add(p.join(
        home,
        '.var',
        'app',
        'com.valvesoftware.Steam',
        '.local',
        'share',
        'Steam',
      ));
    }

    return roots
        .where((r) => r.isNotEmpty && Directory(r).existsSync())
        .toSet()
        .toList();
  }

  /// Writes [newText] to [path] atomically (temp file + rename) after taking a
  /// one-shot backup. Returns true on success.
  static Future<bool> _backupAndWrite(String path, String newText) async {
    try {
      final backup = File('$path.modlist.bak');
      if (backup.existsSync()) await backup.delete();
      await File(path).copy(backup.path);
    } catch (_) {
      // A missing backup is non-fatal; proceed with the write.
    }
    try {
      final tmp = '$path.modlist.tmp';
      await File(tmp).writeAsString(newText, flush: true);
      await File(tmp).rename(path);
      return true;
    } catch (_) {
      return false;
    }
  }
}

class _Range {
  final int start;
  final int end;
  const _Range(this.start, this.end);
}
