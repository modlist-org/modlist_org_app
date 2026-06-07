import 'package:flutter_test/flutter_test.dart';
import 'package:modlist_org_app/src/core/melon_loader_platform.dart';

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
  });
}
