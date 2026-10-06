import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:modlist_org_app/src/core/adofai_game.dart';

void main() {
  late Directory tempDir;
  late String gamePath;
  late String managedPath;
  final game = AdofaiGame();

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('modlist_umm_conflict');
    gamePath = tempDir.path;
    managedPath = p.join(gamePath, 'A Dance of Fire and Ice_Data', 'Managed');
    await Directory(managedPath).create(recursive: true);
    await Directory(p.join(gamePath, 'MelonLoader')).create();
    await File(
      p.join(gamePath, 'version.dll'),
    ).writeAsString('MelonLoader proxy');
  });

  tearDown(() async {
    try {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  test('removes UMM doorstop proxy left next to MelonLoader', () async {
    final proxy = File(p.join(gamePath, 'winhttp.dll'));
    final config = File(p.join(gamePath, 'doorstop_config.ini'));
    await proxy.writeAsString('UnityDoorstop proxy');
    await config.writeAsString(
      '[General]\nenabled = true\ntarget_assembly = '
      'A Dance of Fire and Ice_Data\\Managed\\UnityModManager\\UnityModManager.dll',
    );

    await game.repairLoaderConflicts(gamePath);

    expect(config.existsSync(), isFalse);
    expect(proxy.existsSync(), isFalse);
    expect(File(p.join(gamePath, 'version.dll')).existsSync(), isTrue);
    expect(game.isLoaderInstalled(gamePath), isTrue);
  });

  test('keeps doorstop setups that do not target UMM', () async {
    final proxy = File(p.join(gamePath, 'winhttp.dll'));
    final config = File(p.join(gamePath, 'doorstop_config.ini'));
    await proxy.writeAsString('UnityDoorstop proxy');
    await config.writeAsString(
      '[General]\nenabled = true\ntarget_assembly = BepInEx\\core\\BepInEx.Preloader.dll',
    );

    await game.repairLoaderConflicts(gamePath);

    expect(config.existsSync(), isTrue);
    expect(proxy.existsSync(), isTrue);
  });

  test('restores UMM-patched CoreModule from the clean original', () async {
    final dll = File(p.join(managedPath, 'UnityEngine.CoreModule.dll'));
    await dll.writeAsString('core + UnityModManagerStarter');
    await File('${dll.path}.backup_').writeAsString('core + UnityModManagerStarter');
    await File('${dll.path}.original_').writeAsString('clean core');

    await game.repairLoaderConflicts(gamePath);

    expect(await dll.readAsString(), 'clean core');
  });

  test('leaves unpatched CoreModule alone', () async {
    final dll = File(p.join(managedPath, 'UnityEngine.CoreModule.dll'));
    await dll.writeAsString('updated core');
    await File('${dll.path}.original_').writeAsString('old core');

    await game.repairLoaderConflicts(gamePath);

    expect(await dll.readAsString(), 'updated core');
  });
}
