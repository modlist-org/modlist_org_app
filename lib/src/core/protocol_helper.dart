import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';

class ProtocolHelper {
  static const String scheme = 'modlist';

  /// Registers the custom protocol scheme [scheme]:// on Windows and Linux.
  /// macOS is statically registered via Info.plist.
  static Future<void> register() async {
    if (kIsWeb) return;

    try {
      if (Platform.isWindows) {
        await _registerWindows();
      } else if (Platform.isLinux) {
        await _registerLinux();
      }
    } catch (e) {
      debugPrint('Failed to register protocol handler: $e');
    }
  }

  static Future<void> _registerWindows() async {
    final exePath = Platform.resolvedExecutable;
    
    // Add protocol class keys under HKCU\Software\Classes\modlist
    await Process.run('reg', [
      'add',
      'HKCU\\Software\\Classes\\$scheme',
      '/ve',
      '/d',
      'URL:$scheme Protocol',
      '/f',
    ]);
    
    await Process.run('reg', [
      'add',
      'HKCU\\Software\\Classes\\$scheme',
      '/v',
      'URL Protocol',
      '/d',
      '',
      '/f',
    ]);
    
    await Process.run('reg', [
      'add',
      'HKCU\\Software\\Classes\\$scheme\\shell\\open\\command',
      '/ve',
      '/d',
      '"$exePath" "%1"',
      '/f',
    ]);
  }

  static Future<void> _registerLinux() async {
    final home = Platform.environment['HOME'] ?? '';
    if (home.isEmpty) return;

    final desktopFileContent = '''
[Desktop Entry]
Name=modlist.org app
Exec="${Platform.resolvedExecutable}" %u
Type=Application
Terminal=false
MimeType=x-scheme-handler/$scheme;
''';

    final desktopDir = Directory(p.join(home, '.local', 'share', 'applications'));
    if (!desktopDir.existsSync()) {
      await desktopDir.create(recursive: true);
    }

    final desktopFile = File(p.join(desktopDir.path, '$scheme.desktop'));
    await desktopFile.writeAsString(desktopFileContent);

    // Register with xdg-mime
    await Process.run('xdg-mime', [
      'default',
      '$scheme.desktop',
      'x-scheme-handler/$scheme',
    ]);

    // Update desktop database
    await Process.run('update-desktop-database', [desktopDir.path]);
  }
}
