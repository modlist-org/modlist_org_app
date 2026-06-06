import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import 'game.dart';
import '../models/mod_model.dart';
import 'melon_dll_parser.dart';
import 'melon_loader_platform.dart';

class RhythmDoctorGame extends Game {
  @override
  String get id => 'rhythm-doctor';

  @override
  String get name => 'Rhythm Doctor';

  @override
  String? get steamAppId => '774181';

  @override
  List<String> getSteamInstallFolderNames() => const [
        'Rhythm Doctor',
        'RhythmDoctor',
      ];

  @override
  String getPlatformExeName() {
    if (Platform.isWindows) {
      return 'Rhythm Doctor.exe';
    } else if (Platform.isMacOS) {
      return 'Rhythm Doctor.app';
    } else {
      // Linux native
      return 'Rhythm Doctor';
    }
  }

  @override
  String getPlatformDefaultPath() {
    final home =
        Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        '';
    if (Platform.isWindows) {
      return r'C:\Program Files (x86)\Steam\steamapps\common\Rhythm Doctor';
    } else if (Platform.isMacOS) {
      return p.join(
        home,
        'Library',
        'Application Support',
        'Steam',
        'steamapps',
        'common',
        'Rhythm Doctor',
      );
    } else {
      // Linux
      final path1 = p.join(
        home,
        '.steam',
        'steam',
        'steamapps',
        'common',
        'Rhythm Doctor',
      );
      final path2 = p.join(
        home,
        '.local',
        'share',
        'Steam',
        'steamapps',
        'common',
        'Rhythm Doctor',
      );
      if (Directory(path1).existsSync()) {
        return path1;
      }
      return path2;
    }
  }

  @override
  bool isLoaderInstalled(String gamePath) {
    if (gamePath.isEmpty) return false;

    final melonFolder = Directory(p.join(gamePath, 'MelonLoader'));
    if (!melonFolder.existsSync()) return false;

    final winhttpDll = File(p.join(gamePath, 'winhttp.dll'));
    final winhttpDllAlt = File(p.join(gamePath, 'WinHttp.dll'));
    final versionDll = File(p.join(gamePath, 'version.dll'));
    final versionDllAlt = File(p.join(gamePath, 'Version.dll'));
    final libMelonLoaderSo = File(p.join(gamePath, 'libMelonLoader.so'));
    final libMelonLoaderDylib = File(p.join(gamePath, 'libMelonLoader.dylib'));
    final setupHelper = File(p.join(gamePath, 'setup_helper.sh'));

    final hasWinHttp = winhttpDll.existsSync() || winhttpDllAlt.existsSync();
    final hasVersionDll = versionDll.existsSync() || versionDllAlt.existsSync();
    final hasLibMelonLoader =
        libMelonLoaderSo.existsSync() || libMelonLoaderDylib.existsSync();
    final hasSetupHelper = setupHelper.existsSync();

    return hasWinHttp || hasVersionDll || hasLibMelonLoader || hasSetupHelper;
  }

  @override
  String getLoaderVersion(String gamePath) {
    if (gamePath.isEmpty) return 'None';

    final versionFile = File(
      p.join(gamePath, 'MelonLoader', 'MelonLoader.version'),
    );
    if (versionFile.existsSync()) {
      try {
        return versionFile.readAsStringSync().trim();
      } catch (_) {}
    }

    if (isLoaderInstalled(gamePath)) {
      final logFile = File(p.join(gamePath, 'MelonLoader', 'Latest.log'));
      if (logFile.existsSync()) {
        try {
          final lines = logFile.readAsLinesSync().take(10);
          for (final line in lines) {
            if (line.contains('MelonLoader v')) {
              final match = RegExp(r'MelonLoader v([0-9\.]+)').firstMatch(line);
              if (match != null && match.groupCount >= 1) {
                return match.group(1)!;
              }
            }
          }
        } catch (_) {}
      }
      return 'Unknown (Outdated)';
    }

    return 'None';
  }

  @override
  Future<void> installLoader(
    String gamePath, {
    void Function(double)? onProgress,
  }) async {
    if (!isValidGamePath(gamePath)) {
      throw Exception(
        'Invalid Rhythm Doctor game path. Cannot install MelonLoader.',
      );
    }

    final hasWindowsExe =
        File(p.join(gamePath, 'Rhythm Doctor.exe')).existsSync() ||
        File(p.join(gamePath, 'RhythmDoctor.exe')).existsSync();
    final isProtonOrWine = !Platform.isWindows && hasWindowsExe;

    final downloadUrl =
        MelonLoaderPlatform.downloadUrl(isProtonOrWine: isProtonOrWine);

    final tempDir = await getTemporaryDirectory();
    final tempZipPath = p.join(tempDir.path, 'MelonLoader_rd_temp.zip');

    await MelonLoaderPlatform.downloadArchive(
      downloadUrl,
      tempZipPath,
      onProgress: onProgress,
    );

    final file = File(tempZipPath);
    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    for (final archiveFile in archive) {
      final filename = archiveFile.name;
      final outPath = p.join(gamePath, filename);

      if (archiveFile.isFile) {
        final data = archiveFile.content as List<int>;
        final outFile = File(outPath);
        await outFile.create(recursive: true);
        await outFile.writeAsBytes(data);
      } else {
        await Directory(outPath).create(recursive: true);
      }
    }

    await file.delete();

    if (!Platform.isWindows && !isProtonOrWine) {
      final setupHelper = File(p.join(gamePath, 'setup_helper.sh'));
      final scriptContent = MelonLoaderPlatform.setupHelperScript();
      await setupHelper.writeAsString('${scriptContent.trim()}\n', flush: true);
    }

    if (!Platform.isWindows) {
      final setupHelperPath = p.join(gamePath, 'setup_helper.sh');
      if (File(setupHelperPath).existsSync()) {
        try {
          await Process.run('chmod', ['+x', setupHelperPath]);
        } catch (_) {}
      }

      if (!isProtonOrWine) {
        if (Platform.isLinux) {
          final libSoPath = p.join(gamePath, 'libMelonLoader.so');
          if (File(libSoPath).existsSync()) {
            try {
              await Process.run('chmod', ['+x', libSoPath]);
            } catch (_) {}
          }
        } else if (Platform.isMacOS) {
          final libDylibPath = p.join(gamePath, 'libMelonLoader.dylib');
          if (File(libDylibPath).existsSync()) {
            try {
              await Process.run('chmod', ['+x', libDylibPath]);
              await Process.run('xattr', [
                '-d',
                'com.apple.quarantine',
                libDylibPath,
              ]);
            } catch (_) {}
          }
          final melonDir = Directory(p.join(gamePath, 'MelonLoader'));
          if (melonDir.existsSync()) {
            try {
              await Process.run('xattr', [
                '-d',
                'com.apple.quarantine',
                melonDir.path,
              ]);
            } catch (_) {}
          }
        }
      }
    }

    final versionFile = File(
      p.join(gamePath, 'MelonLoader', 'MelonLoader.version'),
    );
    try {
      if (!versionFile.parent.existsSync()) {
        await versionFile.parent.create(recursive: true);
      }
      await versionFile.writeAsString('0.7.3', flush: true);
    } catch (_) {}

    final modsDir = Directory(p.join(gamePath, 'Mods'));
    if (!modsDir.existsSync()) {
      await modsDir.create();
    }
  }

  @override
  Future<void> uninstallLoader(String gamePath) async {
    final targets = [
      'MelonLoader',
      'winhttp.dll',
      'version.dll',
      'setup_helper.sh',
      'libMelonLoader.so',
      'libMelonLoader.dylib',
      'NOTICE.txt',
    ];

    for (final target in targets) {
      final fullPath = p.join(gamePath, target);
      if (FileSystemEntity.isFileSync(fullPath)) {
        await File(fullPath).delete();
      } else if (FileSystemEntity.isDirectorySync(fullPath)) {
        await Directory(fullPath).delete(recursive: true);
      }
    }
  }

  @override
  Future<void> installMod(
    String gamePath,
    ModItem mod,
    String downloadUrl, {
    required String version,
    bool isBeta = false,
    void Function(double)? onProgress,
  }) async {
    try {
      final installed = await getInstalledMods(gamePath);
      final matchingMods = installed
          .where((m) => isModMatched(m.slug, mod.slug))
          .toList();
      for (final matching in matchingMods) {
        await uninstallMod(gamePath, matching.slug);
      }
    } catch (_) {}

    final tempDir = await getTemporaryDirectory();
    final tempFilePath = p.join(tempDir.path, '${mod.slug}_rd_temp');

    final client = http.Client();
    final response = await client.send(
      http.Request('GET', Uri.parse(downloadUrl)),
    );
    final totalBytes = response.contentLength ?? 0;
    var downloadedBytes = 0;

    final file = File(tempFilePath);
    final sink = file.openWrite();

    await for (final chunk in response.stream) {
      sink.add(chunk);
      downloadedBytes += chunk.length;
      if (totalBytes > 0 && onProgress != null) {
        onProgress(downloadedBytes / totalBytes);
      }
    }
    await sink.flush();
    await sink.close();
    client.close();

    final List<String> installedFiles = [];
    final fileBytes = await file.readAsBytes();

    final installedMods = await getInstalledMods(gamePath);

    bool isZip = false;
    Archive? archive;
    try {
      archive = ZipDecoder().decodeBytes(fileBytes);
      isZip = archive.isNotEmpty;
    } catch (_) {
      isZip = false;
    }

    if (isZip && archive != null) {
      bool hasStructuredDirs = false;
      for (final archiveFile in archive) {
        final normalizedPath = archiveFile.name
            .replaceAll('\\', '/')
            .toLowerCase();
        final parts = normalizedPath.split('/');
        final firstDir = parts.firstWhere(
          (p) => p.isNotEmpty && p != '.',
          orElse: () => '',
        );
        if (firstDir == 'mods' ||
            firstDir == 'plugins' ||
            firstDir == 'userlibs') {
          hasStructuredDirs = true;
          break;
        }
      }

      final String targetBaseDir = hasStructuredDirs
          ? gamePath
          : p.join(gamePath, 'Mods');

      for (final archiveFile in archive) {
        final filename = archiveFile.name;
        final outPath = p.join(targetBaseDir, filename);
        final relativePath = hasStructuredDirs
            ? filename
            : p.join('Mods', filename);

        if (archiveFile.isFile) {
          final data = archiveFile.content as List<int>;
          final outFile = File(outPath);
          await outFile.create(recursive: true);
          await outFile.writeAsBytes(data);
          installedFiles.add(relativePath);
        } else {
          await Directory(outPath).create(recursive: true);
          installedFiles.add(relativePath);
        }
      }
    } else {
      final modsDir = Directory(p.join(gamePath, 'Mods'));
      if (!modsDir.existsSync()) {
        await modsDir.create(recursive: true);
      }
      final destPath = p.join(modsDir.path, '${mod.slug}.dll');
      final destFile = File(destPath);
      await destFile.writeAsBytes(fileBytes);
      installedFiles.add(p.join('Mods', '${mod.slug}.dll'));
    }

    await file.delete();

    installedMods.removeWhere(
      (m) =>
          isModMatched(m.slug, mod.slug) ||
          m.id.toLowerCase() == mod.slug.toLowerCase(),
    );

    installedMods.add(
      InstalledMod(
        id: mod.slug,
        slug: mod.slug,
        name: mod.name,
        version: version,
        isBeta: isBeta,
        installedAt: DateTime.now().toIso8601String(),
        installedFiles: installedFiles,
      ),
    );

    await saveInstalledMods(gamePath, installedMods);
  }

  @override
  Future<void> installModFromFile(String gamePath, String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw Exception('File does not exist: $filePath');
    }

    final filenameNoExt = p.basenameWithoutExtension(filePath);
    final ext = p.extension(filePath).toLowerCase();

    // 파일명에서 버전 정보 제거하여 일관된 slug 획득 (예: Tweaks_v1.0.0 -> Tweaks)
    final cleanName = filenameNoExt.replaceAll(RegExp(r'[-_\s]+v?[0-9]+(?:\.[0-9]+)*.*$'), '');
    final baseSlug = cleanName.isEmpty ? filenameNoExt : cleanName;

    final List<String> installedFiles = [];
    final fileBytes = await file.readAsBytes();

    final installedMods = await getInstalledMods(gamePath);

    bool isZip = ext == '.zip';
    Archive? archive;
    if (isZip) {
      try {
        archive = ZipDecoder().decodeBytes(fileBytes);
        isZip = archive.isNotEmpty;
      } catch (_) {
        isZip = false;
      }
    }

    String finalSlug = baseSlug.toLowerCase();
    String finalName = baseSlug;
    String finalVersion = 'Local';

    // MelonLoader DLL 파싱 (MelonInfo 속성 추출)
    if (isZip && archive != null) {
      for (final archiveFile in archive) {
        if (archiveFile.isFile && p.extension(archiveFile.name).toLowerCase() == '.dll') {
          try {
            final tempDir = await getTemporaryDirectory();
            final tempDllFile = File(p.join(
              tempDir.path,
              'temp_parse_${DateTime.now().microsecondsSinceEpoch}.dll',
            ));
            await tempDllFile.writeAsBytes(archiveFile.content as List<int>);
            final info = MelonDllParser.parse(tempDllFile.path);
            try {
              await tempDllFile.delete();
            } catch (_) {}
            if (info != null) {
              finalName = info.name;
              finalVersion = info.version;
              finalSlug = info.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_-]'), '-');
              break;
            }
          } catch (_) {}
        }
      }
    } else if (ext == '.dll') {
      try {
        final info = MelonDllParser.parse(filePath);
        if (info != null) {
          finalName = info.name;
          finalVersion = info.version;
          finalSlug = info.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_-]'), '-');
        }
      } catch (_) {}
    }

    // 기존 모드가 설치되어 있는 경우 안전하게 먼저 언인스톨을 수행합니다.
    try {
      final matchingMods = installedMods
          .where((m) =>
              isModMatched(m.slug, finalSlug) ||
              m.id.toLowerCase() == finalSlug.toLowerCase())
          .toList();
      for (final matching in matchingMods) {
        await uninstallMod(gamePath, matching.slug);
      }
    } catch (_) {
      // 기존 모드 삭제 실패 시에도 설치 계속 진행
    }

    // 언인스톨 후의 최신 로컬 메타데이터 목록 로드
    final updatedInstalledMods = await getInstalledMods(gamePath);

    if (isZip && archive != null) {
      bool hasStructuredDirs = false;
      for (final archiveFile in archive) {
        final normalizedPath = archiveFile.name
            .replaceAll('\\', '/')
            .toLowerCase();
        final parts = normalizedPath.split('/');
        final firstDir = parts.firstWhere(
          (p) => p.isNotEmpty && p != '.',
          orElse: () => '',
        );
        if (firstDir == 'mods' ||
            firstDir == 'plugins' ||
            firstDir == 'userlibs') {
          hasStructuredDirs = true;
          break;
        }
      }

      final String targetBaseDir = hasStructuredDirs
          ? gamePath
          : p.join(gamePath, 'Mods');

      for (final archiveFile in archive) {
        final filename = archiveFile.name;
        final outPath = p.join(targetBaseDir, filename);
        final relativePath = hasStructuredDirs
            ? filename
            : p.join('Mods', filename);

        if (archiveFile.isFile) {
          final data = archiveFile.content as List<int>;
          final outFile = File(outPath);
          await outFile.create(recursive: true);
          await outFile.writeAsBytes(data);
          installedFiles.add(relativePath);
        } else {
          await Directory(outPath).create(recursive: true);
          installedFiles.add(relativePath);
        }
      }
    } else {
      final modsDir = Directory(p.join(gamePath, 'Mods'));
      if (!modsDir.existsSync()) {
        await modsDir.create(recursive: true);
      }
      final sanitizedFileName = finalName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '');
      final destFileName = '$sanitizedFileName$ext';
      final destPath = p.join(modsDir.path, destFileName);
      final destFile = File(destPath);
      await destFile.writeAsBytes(fileBytes);
      installedFiles.add(p.join('Mods', destFileName));
    }

    updatedInstalledMods.removeWhere(
      (m) =>
          isModMatched(m.slug, finalSlug) ||
          m.id.toLowerCase() == finalSlug.toLowerCase(),
    );

    updatedInstalledMods.add(
      InstalledMod(
        id: finalSlug,
        slug: finalSlug,
        name: finalName,
        version: finalVersion,
        isBeta: false,
        installedAt: DateTime.now().toIso8601String(),
        installedFiles: installedFiles,
      ),
    );

    await saveInstalledMods(gamePath, updatedInstalledMods);
  }

  @override
  Future<void> uninstallMod(String gamePath, String modSlug) async {
    final installedMods = await getInstalledMods(gamePath);

    final modIndex = installedMods.indexWhere(
      (m) => isModMatched(m.slug, modSlug),
    );
    if (modIndex == -1) return;

    final targetMod = installedMods[modIndex];

    final otherMods = installedMods
        .where((m) => !isModMatched(m.slug, modSlug))
        .toList();
    final Set<String> sharedFiles = {};
    for (final other in otherMods) {
      for (final file in other.installedFiles) {
        sharedFiles.add(file.toLowerCase().replaceAll('\\', '/'));
      }
    }

    Future<void> safeDeleteDirectory(Directory dir) async {
      if (!dir.existsSync()) return;
      try {
        final entities = dir.listSync(recursive: true);

        for (final entity in entities) {
          if (entity is File) {
            final relativeEntityPath = p
                .relative(entity.path, from: gamePath)
                .toLowerCase()
                .replaceAll('\\', '/');
            if (sharedFiles.contains(relativeEntityPath)) {
              continue;
            }

            final filename = p.basename(entity.path).toLowerCase();
            final ext = p.extension(entity.path).toLowerCase();

            final isInfoJson = filename == 'info.json';
            final isBinary =
                ext == '.dll' ||
                ext == '.pdb' ||
                ext == '.mdb' ||
                ext == '.so' ||
                ext == '.dylib';
            final isDoc =
                filename.startsWith('readme') ||
                filename.startsWith('changelog') ||
                filename.startsWith('license');

            if (isInfoJson || isBinary || isDoc) {
              try {
                await entity.delete();
              } catch (_) {}
            }
          }
        }

        final subDirs = entities.whereType<Directory>().toList();
        subDirs.sort((a, b) => b.path.length.compareTo(a.path.length));
        for (final subDir in subDirs) {
          if (subDir.existsSync()) {
            try {
              await subDir.delete();
            } catch (_) {}
          }
        }

        try {
          await dir.delete();
        } catch (_) {}
      } catch (_) {}
    }

    for (final relPath in targetMod.installedFiles) {
      final normalizedRelPath = relPath.toLowerCase().replaceAll('\\', '/');
      if (sharedFiles.contains(normalizedRelPath)) {
        continue;
      }

      final fullPath = p.join(gamePath, relPath);
      final disabledPath = '$fullPath.disabled';
      if (FileSystemEntity.isFileSync(fullPath)) {
        try {
          await File(fullPath).delete();
        } catch (_) {}
      } else if (FileSystemEntity.isFileSync(disabledPath)) {
        try {
          await File(disabledPath).delete();
        } catch (_) {}
      } else if (FileSystemEntity.isDirectorySync(fullPath)) {
        final relativeToGame = p
            .relative(fullPath, from: gamePath)
            .toLowerCase()
            .replaceAll('\\', '/');
        final isSharedDir =
            relativeToGame == '.' ||
            relativeToGame == 'mods' ||
            relativeToGame == 'plugins' ||
            relativeToGame == 'userlibs';

        if (!isSharedDir) {
          final dir = Directory(fullPath);
          await safeDeleteDirectory(dir);
        }
      }
    }

    final fallbackDll = File(p.join(gamePath, 'Mods', '$modSlug.dll'));
    final fallbackDllD = File(p.join(gamePath, 'Mods', '$modSlug.dll.disabled'));
    if (fallbackDll.existsSync() &&
        !sharedFiles.contains('mods/${modSlug.toLowerCase()}.dll')) {
      await fallbackDll.delete();
    }
    if (fallbackDllD.existsSync() &&
        !sharedFiles.contains('mods/${modSlug.toLowerCase()}.dll')) {
      await fallbackDllD.delete();
    }
    final fallbackDllLower = File(
      p.join(gamePath, 'Mods', '${modSlug.toLowerCase()}.dll'),
    );
    final fallbackDllLowerD = File(
      p.join(gamePath, 'Mods', '${modSlug.toLowerCase()}.dll.disabled'),
    );
    if (fallbackDllLower.existsSync() &&
        !sharedFiles.contains('mods/${modSlug.toLowerCase()}.dll')) {
      await fallbackDllLower.delete();
    }
    if (fallbackDllLowerD.existsSync() &&
        !sharedFiles.contains('mods/${modSlug.toLowerCase()}.dll')) {
      await fallbackDllLowerD.delete();
    }

    installedMods.removeWhere((m) => isModMatched(m.slug, modSlug));
    await saveInstalledMods(gamePath, installedMods);
  }

  @override
  Future<List<InstalledMod>> getInstalledMods(String gamePath) async {
    final List<InstalledMod> result = [];
    final Set<String> claimedFiles = {};

    final metaFile = File(getInstalledModsMetaPath(gamePath));
    final List<InstalledMod> metaMods = [];
    if (metaFile.existsSync()) {
      try {
        final content = metaFile.readAsStringSync();
        final List<dynamic> jsonList = jsonDecode(content);
        metaMods.addAll(jsonList.map((j) => InstalledMod.fromJson(j)));
      } catch (_) {}
    }

    metaMods.sort(
      (a, b) => b.installedFiles.length.compareTo(a.installedFiles.length),
    );

    for (final metaMod in metaMods) {
      bool exists = false;
      for (final relPath in metaMod.installedFiles) {
        final fullPath = p.join(gamePath, relPath);
        final disabledPath = '$fullPath.disabled';
        if (FileSystemEntity.isFileSync(fullPath) ||
            FileSystemEntity.isDirectorySync(fullPath) ||
            (relPath.toLowerCase().endsWith('.dll') && FileSystemEntity.isFileSync(disabledPath))) {
          exists = true;
          break;
        }
      }

      if (metaMod.installedFiles.isEmpty) {
        final modDll = File(p.join(gamePath, 'Mods', '${metaMod.slug}.dll'));
        final pluginDll = File(p.join(gamePath, 'Plugins', '${metaMod.slug}.dll'));
        final modDllD = File(p.join(gamePath, 'Mods', '${metaMod.slug}.dll.disabled'));
        final pluginDllD = File(p.join(gamePath, 'Plugins', '${metaMod.slug}.dll.disabled'));
        if (modDll.existsSync() ||
            pluginDll.existsSync() ||
            modDllD.existsSync() ||
            pluginDllD.existsSync()) {
          exists = true;
        }
      }

      if (exists) {
        bool allFilesClaimed = true;
        for (final relPath in metaMod.installedFiles) {
          final normalized = relPath.toLowerCase().replaceAll('\\', '/');
          if (!claimedFiles.contains(normalized)) {
            allFilesClaimed = false;
            break;
          }
        }

        if (metaMod.installedFiles.isNotEmpty && allFilesClaimed) {
          continue;
        }

        result.add(getActualModInfoFromDisk(gamePath, metaMod));
        for (final relPath in metaMod.installedFiles) {
          claimedFiles.add(relPath.toLowerCase().replaceAll('\\', '/'));
        }
      }
    }

    final modsDir = Directory(p.join(gamePath, 'Mods'));
    if (modsDir.existsSync()) {
      try {
        final entities = modsDir.listSync();
        for (final entity in entities) {
          final isDll = p.extension(entity.path).toLowerCase() == '.dll';
          final isDllDisabled = entity.path.toLowerCase().endsWith('.dll.disabled');
          if (entity is File && (isDll || isDllDisabled)) {
            final fileName = isDllDisabled
                ? p.basename(entity.path).substring(0, p.basename(entity.path).length - '.disabled'.length)
                : p.basenameWithoutExtension(entity.path);
            final relPath = isDllDisabled
                ? p.join('Mods', p.basename(entity.path).substring(0, p.basename(entity.path).length - '.disabled'.length))
                : p.join('Mods', p.basename(entity.path));
            final normalizedRelPath = relPath.toLowerCase().replaceAll(
              '\\',
              '/',
            );

            if (claimedFiles.contains(normalizedRelPath)) continue;

            String finalName = isDllDisabled
                ? p.basenameWithoutExtension(fileName)
                : fileName;
            String finalVersion = 'Local';
            String slug = isDllDisabled
                ? p.basenameWithoutExtension(fileName).toLowerCase()
                : fileName.toLowerCase();

            try {
              final info = MelonDllParser.parse(entity.path);
              if (info != null) {
                finalName = info.name;
                finalVersion = info.version;
                slug = info.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_-]'), '-');
              }
            } catch (_) {}

            result.add(
              InstalledMod(
                id: slug,
                slug: slug,
                name: finalName,
                version: finalVersion,
                isBeta: false,
                installedAt: entity.statSync().modified.toIso8601String(),
                installedFiles: [relPath],
                isEnabled: !isDllDisabled,
              ),
            );
          }
        }
      } catch (_) {}
    }

    final pluginsDir = Directory(p.join(gamePath, 'Plugins'));
    if (pluginsDir.existsSync()) {
      try {
        final entities = pluginsDir.listSync();
        for (final entity in entities) {
          final isDll = p.extension(entity.path).toLowerCase() == '.dll';
          final isDllDisabled = entity.path.toLowerCase().endsWith('.dll.disabled');
          if (entity is File && (isDll || isDllDisabled)) {
            final fileName = isDllDisabled
                ? p.basename(entity.path).substring(0, p.basename(entity.path).length - '.disabled'.length)
                : p.basenameWithoutExtension(entity.path);
            final relPath = isDllDisabled
                ? p.join('Plugins', p.basename(entity.path).substring(0, p.basename(entity.path).length - '.disabled'.length))
                : p.join('Plugins', p.basename(entity.path));
            final normalizedRelPath = relPath.toLowerCase().replaceAll(
              '\\',
              '/',
            );

            if (claimedFiles.contains(normalizedRelPath)) continue;

            String finalName = isDllDisabled
                ? '${p.basenameWithoutExtension(fileName)} (Plugin)'
                : '$fileName (Plugin)';
            String finalVersion = 'Local';
            String slug = isDllDisabled
                ? p.basenameWithoutExtension(fileName).toLowerCase()
                : fileName.toLowerCase();

            try {
              final info = MelonDllParser.parse(entity.path);
              if (info != null) {
                finalName = '${info.name} (Plugin)';
                finalVersion = info.version;
                slug = info.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_-]'), '-');
              }
            } catch (_) {}

            result.add(
              InstalledMod(
                id: slug,
                slug: slug,
                name: finalName,
                version: finalVersion,
                isBeta: false,
                installedAt: entity.statSync().modified.toIso8601String(),
                installedFiles: [relPath],
                isEnabled: !isDllDisabled,
              ),
            );
          }
        }
      } catch (_) {}
    }

    return result;
  }

  @override
  bool isValidGamePath(String gamePath) {
    if (gamePath.isEmpty) return false;
    final dir = Directory(gamePath);
    if (!dir.existsSync()) return false;

    try {
      final entities = dir.listSync();
      for (final entity in entities) {
        final name = p.basename(entity.path).toLowerCase();

        if (Platform.isWindows && name.endsWith('.exe')) {
          if (name.contains('rhythm') || name.contains('doctor')) {
            return true;
          }
        } else if (Platform.isMacOS && name.endsWith('.app')) {
          if (name.contains('rhythm') || name.contains('doctor')) {
            return true;
          }
        } else if (Platform.isLinux) {
          // Linux native binary or Proton exe
          if (name.endsWith('.exe') &&
              (name.contains('rhythm') || name.contains('doctor'))) {
            return true;
          }
          if (entity is File &&
              (name.endsWith('.x86_64') ||
                  name.endsWith('.x86') ||
                  !name.contains('.'))) {
            if (name.contains('rhythm') || name.contains('doctor')) {
              return true;
            }
          }
        }
      }
    } catch (_) {}

    final folderName = p.basename(gamePath).toLowerCase();
    if (folderName.contains('rhythm doctor') || folderName.contains('rhythmdoctor')) {
      return true;
    }

    return false;
  }

  @override
  bool isUmmDetected(String gamePath) => false; // Disabled UMM migration support for Rhythm Doctor

  @override
  String? getSteamLaunchOptionsGuideKey() {
    if (Platform.isWindows) {
      return null;
    } else if (Platform.isLinux) {
      return 'installed_steamlaunchoptionsguide_rd_linux';
    } else if (Platform.isMacOS) {
      return 'installed_steamlaunchoptionsguide_rd_macos';
    }
    return null;
  }
}
