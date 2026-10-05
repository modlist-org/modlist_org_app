import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:modlist_org_app/src/core/adofai_game.dart';
import 'package:modlist_org_app/src/models/mod_model.dart';

void main() {
  late Directory tempDir;
  late String gamePath;
  final game = AdofaiGame();
  const dataDir = 'A Dance of Fire and Ice_Data';

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('modlist_ummbridge_test');
    gamePath = tempDir.path;

    await File(
      p.join(gamePath, dataDir, 'Managed', 'Assembly-CSharp.dll'),
    ).create(recursive: true);
    await File(
      p.join(gamePath, dataDir, 'Managed', 'UnityEngine.dll'),
    ).create(recursive: true);
    await File(
      p.join(gamePath, dataDir, 'Plugins', 'x86_64', 'steam_api64.dll'),
    ).create(recursive: true);
    await File(
      p.join(gamePath, dataDir, 'Managed', 'UnityModManager', 'UnityModManager.dll'),
    ).create(recursive: true);
    await File(
      p.join(gamePath, 'Plugins', 'UMMBridge.dll'),
    ).create(recursive: true);
  });

  tearDown(() async {
    try {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  InstalledMod legacyEntry({required String id, required String slug}) {
    return InstalledMod(
      id: id,
      slug: slug,
      name: 'UMMBridge',
      version: '1.1.0',
      isBeta: false,
      installedAt: DateTime.now().toIso8601String(),
      installedFiles: [
        'Plugins/',
        'Plugins/UMMBridge.dll',
        '$dataDir/',
        '$dataDir/Managed/',
        '$dataDir/Managed/UnityModManager/',
        '$dataDir/Managed/UnityModManager/UnityModManager.dll',
      ],
    );
  }

  test('protects game root, shared and data directories', () {
    expect(game.isProtectedGameDirectory('.'), isTrue);
    expect(game.isProtectedGameDirectory('Plugins/'), isTrue);
    expect(game.isProtectedGameDirectory('UMMMods'), isTrue);
    expect(game.isProtectedGameDirectory('$dataDir/'), isTrue);
    expect(game.isProtectedGameDirectory('$dataDir/Managed/'), isTrue);
    expect(game.isProtectedGameDirectory('$dataDir\\Managed'), isTrue);
    expect(
      game.isProtectedGameDirectory('$dataDir/Managed/UnityModManager/'),
      isFalse,
    );
    expect(game.isProtectedGameDirectory('UMMMods/Tweaks/'), isFalse);
  });

  test('ummbridge slug matches the ummcompat server slug', () {
    expect(game.canonicalModSlug('ummbridge'), 'ummcompat');
    expect(game.canonicalModSlug('UMMBridge'), 'ummcompat');
    expect(game.isModMatched('ummbridge', 'ummcompat'), isTrue);
  });

  test('migrates ummbridge entries to ummcompat and strips data dirs', () async {
    await game.saveInstalledMods(gamePath, [
      legacyEntry(id: 'ummbridge', slug: 'ummbridge'),
      InstalledMod(
        id: 'ummcompat',
        slug: 'ummcompat',
        name: 'UMMBridge',
        version: '1.2.0',
        isBeta: false,
        installedAt: DateTime.now().toIso8601String(),
        installedFiles: ['Plugins/UMMBridge.dll'],
      ),
    ]);

    final mods = await game.getInstalledMods(gamePath);
    final bridge = mods.where((m) => m.slug == 'ummcompat').toList();
    expect(bridge.length, 1);
    expect(mods.any((m) => m.slug == 'ummbridge'), isFalse);
    expect(bridge.first.id, 'ummcompat');
    expect(
      bridge.first.installedFiles.any(
        (f) => game.isProtectedGameDirectory(f),
      ),
      isFalse,
    );
  });

  test('scanned UMMBridge plugin without metadata uses ummcompat slug', () async {
    final mods = await game.getInstalledMods(gamePath);
    expect(mods.any((m) => m.slug == 'ummcompat'), isTrue);
    expect(mods.any((m) => m.slug == 'ummbridge'), isFalse);
  });

  test('uninstalling legacy ummcompat keeps game data intact', () async {
    await game.saveInstalledMods(gamePath, [
      legacyEntry(id: 'ummcompat', slug: 'ummcompat'),
    ]);

    await game.uninstallMod(gamePath, 'ummcompat');

    expect(
      File(p.join(gamePath, dataDir, 'Managed', 'Assembly-CSharp.dll')).existsSync(),
      isTrue,
    );
    expect(
      File(p.join(gamePath, dataDir, 'Managed', 'UnityEngine.dll')).existsSync(),
      isTrue,
    );
    expect(
      File(p.join(gamePath, dataDir, 'Plugins', 'x86_64', 'steam_api64.dll')).existsSync(),
      isTrue,
    );
    expect(File(p.join(gamePath, 'Plugins', 'UMMBridge.dll')).existsSync(), isFalse);
    expect(
      File(p.join(gamePath, dataDir, 'Managed', 'UnityModManager', 'UnityModManager.dll')).existsSync(),
      isFalse,
    );
    expect(await game.getInstalledMods(gamePath), isEmpty);
  });
}
