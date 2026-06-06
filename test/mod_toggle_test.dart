import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:modlist_org_app/src/core/adofai_game.dart';
import 'package:modlist_org_app/src/models/mod_model.dart';

void main() {
  late Directory tempDir;
  late String gamePath;
  final game = AdofaiGame();

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('modlist_test');
    gamePath = tempDir.path;
  });

  tearDown(() async {
    try {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  test('toggleModActive and getInstalledMods works with disabled mods', () async {
    // 1. Create a fake Mods folder and a fake DLL file
    final modsDir = Directory(p.join(gamePath, 'Mods'));
    await modsDir.create();

    final dllFile = File(p.join(modsDir.path, 'my_mod.dll'));
    await dllFile.writeAsString('fake binary content');

    // 2. Create the modlist_installed.json metadata file
    final installedMod = InstalledMod(
      id: 'my-mod',
      slug: 'my-mod',
      name: 'My Mod',
      version: '1.0.0',
      isBeta: false,
      installedAt: DateTime.now().toIso8601String(),
      installedFiles: ['Mods/my_mod.dll'],
      isEnabled: true,
    );

    await game.saveInstalledMods(gamePath, [installedMod]);

    // 3. Scan installed mods (should find the mod as enabled)
    var list = await game.getInstalledMods(gamePath);
    expect(list.length, 1);
    expect(list.first.id, 'my-mod');
    expect(list.first.isEnabled, isTrue);
    expect(dllFile.existsSync(), isTrue);

    // 4. Disable the mod
    await game.toggleModActive(gamePath, list.first, false);

    // Verify DLL was renamed to .disabled
    expect(dllFile.existsSync(), isFalse);
    expect(File('${dllFile.path}.disabled').existsSync(), isTrue);

    // Update metadata (simulating InstallerState behavior)
    final disabledMod = InstalledMod(
      id: 'my-mod',
      slug: 'my-mod',
      name: 'My Mod',
      version: '1.0.0',
      isBeta: false,
      installedAt: installedMod.installedAt,
      installedFiles: ['Mods/my_mod.dll'],
      isEnabled: false,
    );
    await game.saveInstalledMods(gamePath, [disabledMod]);

    // 5. Scan installed mods again (should find the mod as disabled)
    list = await game.getInstalledMods(gamePath);
    expect(list.length, 1);
    expect(list.first.id, 'my-mod');
    expect(list.first.isEnabled, isFalse);

    // 6. Enable the mod back
    await game.toggleModActive(gamePath, list.first, true);

    // Verify DLL was renamed back to .dll
    expect(dllFile.existsSync(), isTrue);
    expect(File('${dllFile.path}.disabled').existsSync(), isFalse);
  });
}
