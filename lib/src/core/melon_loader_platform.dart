import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

class MelonLoaderPlatform {
  static const version = '0.7.3';
  static const _releaseBase =
      'https://github.com/LavaGang/MelonLoader/releases/download/v$version';

  static String downloadUrl({required bool isProtonOrWine}) {
    return '$_releaseBase/${archiveName(isProtonOrWine: isProtonOrWine)}';
  }

  static String archiveName({required bool isProtonOrWine}) {
    if (isProtonOrWine || Platform.isWindows) {
      return 'MelonLoader.x64.zip';
    }
    if (Platform.isLinux) {
      return 'MelonLoader.Linux.x64.zip';
    }
    if (Platform.isMacOS) {
      // v0.7.3 only ships an x64 macOS archive. The generated launch script
      // runs the game through Rosetta on Apple Silicon.
      return 'MelonLoader.macOS.x64.zip';
    }
    throw UnsupportedError('Unsupported platform for MelonLoader installation');
  }

  static String setupHelperScript() {
    if (Platform.isMacOS) {
      // Steam Launch Options must reference this script by ABSOLUTE path:
      //   "/full/path/setup_helper.sh" %command%
      // Steam on macOS does not resolve "./setup_helper.sh".
      return r'''
#!/bin/bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP="$DIR/MelonLoader.Bootstrap.dylib"

export DYLD_LIBRARY_PATH="$DIR${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}"
if [ -n "$STEAM_DYLD_INSERT_LIBRARIES" ]; then
  export DYLD_INSERT_LIBRARIES="$BOOTSTRAP:$STEAM_DYLD_INSERT_LIBRARIES"
else
  export DYLD_INSERT_LIBRARIES="$BOOTSTRAP${DYLD_INSERT_LIBRARIES:+:$DYLD_INSERT_LIBRARIES}"
fi

# Steam passes the .app bundle as %command%. DYLD_INSERT_LIBRARIES is dropped
# when LaunchServices opens a .app, so exec the inner Mach-O binary directly.
if [ -d "${1:-}" ] && [ "${1%.app}" != "$1" ]; then
  APP="$1"; shift
  BIN_NAME="$(/usr/libexec/PlistBuddy -c "Print CFBundleExecutable" "$APP/Contents/Info.plist" 2>/dev/null)"
  set -- "$APP/Contents/MacOS/$BIN_NAME" "$@"
fi

# v0.7.3 ships an x86_64 bootstrap only; force the game's x64 slice through
# Rosetta so the dylib can inject on Apple Silicon.
if [ "$(uname -m)" = "arm64" ]; then
  exec arch -x86_64 "$@"
fi

exec "$@"
''';
    }

    return r'''
#!/bin/bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export LD_LIBRARY_PATH="$DIR:$LD_LIBRARY_PATH"
export LD_PRELOAD="$DIR/libMelonLoader.so${LD_PRELOAD:+:$LD_PRELOAD}"
exec "$@"
''';
  }

  static Future<void> configureNativeInstall(
    String gamePath, {
    required bool isProtonOrWine,
  }) async {
    if (!Platform.isWindows && !isProtonOrWine) {
      final setupHelper = File(p.join(gamePath, 'setup_helper.sh'));
      final scriptContent = setupHelperScript();
      await setupHelper.writeAsString('${scriptContent.trim()}\n', flush: true);
    }

    if (Platform.isWindows) return;

    final setupHelperPath = p.join(gamePath, 'setup_helper.sh');
    if (File(setupHelperPath).existsSync()) {
      await _runIgnored('chmod', ['+x', setupHelperPath]);
    }

    if (isProtonOrWine) return;

    if (Platform.isLinux) {
      final libSoPath = p.join(gamePath, 'libMelonLoader.so');
      if (File(libSoPath).existsSync()) {
        await _runIgnored('chmod', ['+x', libSoPath]);
      }
    } else if (Platform.isMacOS) {
      // v0.7.3 ships MelonLoader.Bootstrap.dylib (the old libMelonLoader.dylib
      // no longer exists). Clear its quarantine so dyld can inject it.
      final bootstrapDylibPath = p.join(gamePath, 'MelonLoader.Bootstrap.dylib');
      if (File(bootstrapDylibPath).existsSync()) {
        await _runIgnored('xattr', [
          '-d',
          'com.apple.quarantine',
          bootstrapDylibPath,
        ]);
      }

      if (File(setupHelperPath).existsSync()) {
        await _runIgnored('xattr', [
          '-d',
          'com.apple.quarantine',
          setupHelperPath,
        ]);
      }

      final melonDir = Directory(p.join(gamePath, 'MelonLoader'));
      if (melonDir.existsSync()) {
        await _runIgnored('xattr', [
          '-dr',
          'com.apple.quarantine',
          melonDir.path,
        ]);
      }
    }
  }

  static Future<void> _runIgnored(
    String executable,
    List<String> arguments, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    try {
      final process = await Process.start(executable, arguments);
      final stdoutDone = process.stdout.drain<void>();
      final stderrDone = process.stderr.drain<void>();

      await process.exitCode.timeout(
        timeout,
        onTimeout: () {
          process.kill(ProcessSignal.sigkill);
          return -1;
        },
      );

      await Future.wait([stdoutDone, stderrDone]).timeout(
        const Duration(seconds: 1),
        onTimeout: () => <void>[],
      );
    } catch (_) {}
  }

  static Future<void> downloadArchive(
    String downloadUrl,
    String tempZipPath, {
    void Function(double)? onProgress,
  }) async {
    final client = http.Client();
    final file = File(tempZipPath);
    IOSink? sink;

    try {
      if (await file.exists()) {
        await file.delete();
      }

      final request = http.Request('GET', Uri.parse(downloadUrl));
      final response =
          await client.send(request).timeout(const Duration(seconds: 20));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'MelonLoader download failed (${response.statusCode}) from ${Uri.parse(downloadUrl).host}',
        );
      }

      final totalBytes = response.contentLength ?? 0;
      var downloadedBytes = 0;
      sink = file.openWrite();

      await for (final chunk
          in response.stream.timeout(const Duration(seconds: 30))) {
        sink.add(chunk);
        downloadedBytes += chunk.length;
        if (totalBytes > 0 && onProgress != null) {
          onProgress(downloadedBytes / totalBytes);
        }
      }

      await sink.flush();
      await sink.close();
      sink = null;
    } catch (_) {
      try {
        await sink?.close();
      } catch (_) {}
      try {
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
      rethrow;
    } finally {
      client.close();
    }
  }
}
