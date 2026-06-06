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
      return r'''
#!/bin/bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DYLD_LIBRARY_PATH="$DIR:$DYLD_LIBRARY_PATH"
export DYLD_INSERT_LIBRARIES="$DIR/libMelonLoader.dylib${DYLD_INSERT_LIBRARIES:+:$DYLD_INSERT_LIBRARIES}"

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
      final libDylibPath = p.join(gamePath, 'libMelonLoader.dylib');
      if (File(libDylibPath).existsSync()) {
        await _runIgnored('chmod', ['+x', libDylibPath]);
        await _runIgnored('xattr', [
          '-d',
          'com.apple.quarantine',
          libDylibPath,
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
