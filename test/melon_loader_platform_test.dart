import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:modlist_org_app/src/core/melon_loader_platform.dart';
import 'package:path/path.dart' as p;

void main() {
  group('MelonLoaderPlatform', () {
    test('maps macOS architecture aliases to archive names', () {
      expect(
        MelonLoaderPlatform.macOSArchiveNameForArchitecture('arm64'),
        'MelonLoader.macOS.arm64.zip',
      );
      expect(
        MelonLoaderPlatform.macOSArchiveNameForArchitecture('aarch64'),
        'MelonLoader.macOS.arm64.zip',
      );
      expect(
        MelonLoaderPlatform.macOSArchiveNameForArchitecture('x86_64'),
        'MelonLoader.macOS.x64.zip',
      );
      expect(
        MelonLoaderPlatform.macOSArchiveNameForArchitecture('amd64'),
        'MelonLoader.macOS.x64.zip',
      );
    });

    test('downloads macOS archives from the fork release repository', () {
      expect(
        MelonLoaderPlatform.downloadUrlForArchive(
          'MelonLoader.macOS.arm64.zip',
        ),
        'https://github.com/kkorenn/MelonLoader/releases/download/v0.7.3/MelonLoader.macOS.arm64.zip',
      );
    });

    test('keeps non-macOS archives on upstream releases', () {
      expect(
        MelonLoaderPlatform.downloadUrlForArchive('MelonLoader.x64.zip'),
        'https://github.com/LavaGang/MelonLoader/releases/download/v0.7.3/MelonLoader.x64.zip',
      );
    });

    test('detects x64-only macOS game executables', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'modlist_macho_x64_',
      );
      try {
        final executablePath = await _writeMacOSApp(
          tempDir.path,
          executableName: 'TestGame',
          cpuType: _cpuTypeX64,
        );

        expect(
          MelonLoaderPlatform.macOSExecutablePathForGamePath(tempDir.path),
          executablePath,
        );
        expect(MelonLoaderPlatform.machOArchitectures(executablePath), {'x64'});
        expect(
          MelonLoaderPlatform.macOSArchitectureForGamePath(tempDir.path),
          'x64',
        );
      } finally {
        await tempDir.delete(recursive: true);
      }
    });

    test('detects arm64 macOS game executables', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'modlist_macho_arm64_',
      );
      try {
        final executablePath = await _writeMacOSApp(
          tempDir.path,
          executableName: 'TestGame',
          cpuType: _cpuTypeArm64,
        );

        expect(MelonLoaderPlatform.machOArchitectures(executablePath), {
          'arm64',
        });
        expect(
          MelonLoaderPlatform.macOSArchitectureForGamePath(tempDir.path),
          'arm64',
        );
      } finally {
        await tempDir.delete(recursive: true);
      }
    });
  });
}

const _cpuTypeX64 = 0x01000007;
const _cpuTypeArm64 = 0x0100000c;

Future<String> _writeMacOSApp(
  String parentPath, {
  required String executableName,
  required int cpuType,
}) async {
  final appPath = p.join(parentPath, 'Test Game.app');
  final contentsPath = p.join(appPath, 'Contents');
  final macOSPath = p.join(contentsPath, 'MacOS');
  await Directory(macOSPath).create(recursive: true);

  await File(p.join(contentsPath, 'Info.plist')).writeAsString('''
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>$executableName</string>
</dict>
</plist>
''');

  final header = ByteData(32)
    ..setUint32(0, 0xfeedfacf, Endian.little)
    ..setUint32(4, cpuType, Endian.little);
  final executablePath = p.join(macOSPath, executableName);
  await File(executablePath).writeAsBytes(header.buffer.asUint8List());
  return executablePath;
}
