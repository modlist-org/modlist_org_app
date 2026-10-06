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
import 'debug_log.dart';

class AdofaiGame extends Game {
  @override
  String get id => 'adofai';

  @override
  String get name => 'A Dance of Fire and Ice';

  @override
  String? get steamAppId => '977950';

  @override
  List<String> getSteamInstallFolderNames() => const [
    'A Dance of Fire and Ice',
    'ADanceOfFireAndIce',
    'ADOFAI',
  ];

  // UMMBridge 는 서버에서 호환성을 위해 구 슬러그(ummcompat)를 유지
  @override
  Map<String, String> get modSlugAliases => const {'ummbridge': 'ummcompat'};

  @override
  Map<String, String> get modFileAliases => const {
    'plugins/ummbridge.dll': 'ummcompat',
    'plugins/ummbridge.dll.disabled': 'ummcompat',
  };

  @override
  String getPlatformExeName() {
    if (Platform.isWindows) {
      return 'A Dance of Fire and Ice.exe';
    } else if (Platform.isMacOS) {
      return 'ADanceOfFireAndIce.app';
    } else {
      // Linux
      return 'ADanceOfFireAndIce';
    }
  }

  @override
  String getModArchiveGameName(String gamePath) {
    if (Platform.isLinux) {
      if (File(p.join(gamePath, 'A Dance of Fire and Ice.exe')).existsSync()) {
        return 'A Dance of Fire and Ice';
      }
      return 'ADanceOfFireAndIce';
    }
    return p.basenameWithoutExtension(getPlatformExeName());
  }

  // MelonLoader가 설치되었는지 파일 및 디렉토리 구조 검증
  @override
  bool isLoaderInstalled(String gamePath) {
    if (gamePath.isEmpty) return false;

    final melonFolder = Directory(p.join(gamePath, 'MelonLoader'));
    if (!melonFolder.existsSync()) return false;

    final winhttpDll = File(p.join(gamePath, 'winhttp.dll'));
    final winhttpDllAlt = File(p.join(gamePath, 'WinHttp.dll'));
    final versionDll = File(p.join(gamePath, 'version.dll'));
    final versionDllAlt = File(p.join(gamePath, 'Version.dll'));
    final melonLoaderBootstrapSo = File(
      p.join(gamePath, 'MelonLoader.Bootstrap.so'),
    );
    final libMelonLoaderDylib = File(p.join(gamePath, 'libMelonLoader.dylib'));
    final setupHelper = File(p.join(gamePath, 'setup_helper.sh'));

    final hasWinHttp = winhttpDll.existsSync() || winhttpDllAlt.existsSync();
    final hasVersionDll = versionDll.existsSync() || versionDllAlt.existsSync();
    final hasLibMelonLoader =
        melonLoaderBootstrapSo.existsSync() || libMelonLoaderDylib.existsSync();
    final hasSetupHelper = setupHelper.existsSync();

    return hasWinHttp || hasVersionDll || hasLibMelonLoader || hasSetupHelper;
  }

  @override
  String getLoaderVersion(String gamePath) {
    if (gamePath.isEmpty) return 'None';

    // 우리가 기록해 둔 버전 파일 확인
    final versionFile = File(
      p.join(gamePath, 'MelonLoader', 'MelonLoader.version'),
    );
    if (versionFile.existsSync()) {
      try {
        return versionFile.readAsStringSync().trim();
      } catch (_) {}
    }

    // 버전 파일이 없다면 MelonLoader가 설치는 되어 있지만 구버전이거나 알 수 없는 버전임
    if (isLoaderInstalled(gamePath)) {
      // 최신 로그 파일에서 버전을 파싱해보기 시도
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
    void Function(LoaderInstallPhase)? onPhase,
  }) async {
    if (!isValidGamePath(gamePath)) {
      await DebugLog.info(
        'ADOFAI installLoader rejected invalid path: $gamePath',
      );
      throw Exception('Invalid ADOFAI game path. Cannot install MelonLoader.');
    }

    await DebugLog.info('ADOFAI installLoader start: gamePath=$gamePath');

    // 0. UMM(Unity Mod Manager) 잔재 청소
    final ummFolder = Directory(p.join(gamePath, 'UnityModManager'));
    final doorstopConfig = File(p.join(gamePath, 'DoorstopConfig.ini'));
    final doorstopDll = File(p.join(gamePath, 'Doorstop.dll'));
    try {
      if (ummFolder.existsSync()) await ummFolder.delete(recursive: true);
      if (doorstopConfig.existsSync()) await doorstopConfig.delete();
      if (doorstopDll.existsSync()) await doorstopDll.delete();
      await _removeUmmDoorstop(gamePath);

      // UMM Assembly 모드로 설치된 경우 백업본 복구 및 UMM 폴더 삭제
      String? managedPath;
      String? assemblyPath;
      if (Platform.isMacOS) {
        final macManaged = Directory(
          p.join(
            gamePath,
            'A Dance of Fire and Ice.app',
            'Contents',
            'Resources',
            'Data',
            'Managed',
          ),
        );
        if (macManaged.existsSync()) {
          managedPath = macManaged.path;
        } else {
          final macManagedAlt = Directory(
            p.join(gamePath, 'Contents', 'Resources', 'Data', 'Managed'),
          );
          if (macManagedAlt.existsSync()) {
            managedPath = macManagedAlt.path;
          }
        }

        final macAssembly = Directory(
          p.join(
            gamePath,
            'A Dance of Fire and Ice.app',
            'Contents',
            'Resources',
            'Data',
            'Assembly',
          ),
        );
        if (macAssembly.existsSync()) {
          assemblyPath = macAssembly.path;
        } else {
          final macAssemblyAlt = Directory(
            p.join(gamePath, 'Contents', 'Resources', 'Data', 'Assembly'),
          );
          if (macAssemblyAlt.existsSync()) {
            assemblyPath = macAssemblyAlt.path;
          }
        }
      } else {
        final winLinuxManaged = Directory(
          p.join(gamePath, 'A Dance of Fire and Ice_Data', 'Managed'),
        );
        if (winLinuxManaged.existsSync()) {
          managedPath = winLinuxManaged.path;
        }
        final winLinuxAssembly = Directory(
          p.join(gamePath, 'A Dance of Fire and Ice_Data', 'Assembly'),
        );
        if (winLinuxAssembly.existsSync()) {
          assemblyPath = winLinuxAssembly.path;
        }
      }

      if (managedPath != null) {
        await _restoreUmmPatchedAssemblies(managedPath);

        // Managed/UnityModManager 폴더 삭제
        final ummManagedFolder = Directory(
          p.join(managedPath, 'UnityModManager'),
        );
        if (ummManagedFolder.existsSync()) {
          await ummManagedFolder.delete(recursive: true);
        }
      }

      if (assemblyPath != null) {
        // Assembly/UnityModManager 폴더 삭제
        final ummAssemblyFolder = Directory(
          p.join(assemblyPath, 'UnityModManager'),
        );
        if (ummAssemblyFolder.existsSync()) {
          await ummAssemblyFolder.delete(recursive: true);
        }
      }
      await DebugLog.info(
        'ADOFAI UMM cleanup finished: managedPath=$managedPath '
        'assemblyPath=$assemblyPath',
      );
    } catch (e, stackTrace) {
      await DebugLog.error(
        'ADOFAI UMM cleanup failed; continuing',
        error: e,
        stackTrace: stackTrace,
      );
    }

    final hasWindowsExe = File(
      p.join(gamePath, 'A Dance of Fire and Ice.exe'),
    ).existsSync();
    final isProtonOrWine = !Platform.isWindows && hasWindowsExe;
    await DebugLog.info(
      'ADOFAI platform detection: os=${Platform.operatingSystem} '
      'hasWindowsExe=$hasWindowsExe protonOrWine=$isProtonOrWine',
    );

    // 0.7.3 버전 다운로드 주소 정의
    final downloadUrl = MelonLoaderPlatform.downloadUrl(
      isProtonOrWine: isProtonOrWine,
      gamePath: gamePath,
    );

    // 임시 파일 다운로드 경로 설정
    final tempDir = await getTemporaryDirectory();
    final tempZipPath = p.join(tempDir.path, 'MelonLoader_temp.zip');
    await DebugLog.info(
      'ADOFAI MelonLoader download prepared: url=$downloadUrl '
      'tempZipPath=$tempZipPath',
    );

    // 1. MelonLoader 다운로드
    await MelonLoaderPlatform.downloadArchive(
      downloadUrl,
      tempZipPath,
      onProgress: onProgress,
    );
    await DebugLog.info('ADOFAI MelonLoader download returned');

    // 2. 압축 해제
    onPhase?.call(LoaderInstallPhase.extracting);
    await DebugLog.info('ADOFAI extraction start');
    final file = File(tempZipPath);
    final bytes = await file.readAsBytes();
    await DebugLog.info('ADOFAI temp zip read: bytes=${bytes.length}');
    final decodedArchive = await decodeModArchive(bytes);
    final archive = decodedArchive.archive;
    if (archive == null) {
      throw Exception('MelonLoader archive format is not supported.');
    }
    await DebugLog.info('ADOFAI archive decoded: entries=${archive.length}');

    var extractedFiles = 0;
    var extractedDirs = 0;
    var extractedBytes = 0;
    for (final archiveFile in archive) {
      final filename = archiveFile.name;
      final outPath = p.join(gamePath, filename);

      if (archiveFile.isFile) {
        final data = archiveFile.content as List<int>;
        final outFile = File(outPath);
        await outFile.create(recursive: true);
        await outFile.writeAsBytes(data);
        extractedFiles += 1;
        extractedBytes += data.length;
      } else {
        await Directory(outPath).create(recursive: true);
        extractedDirs += 1;
      }
    }
    await DebugLog.info(
      'ADOFAI extraction finished: files=$extractedFiles dirs=$extractedDirs '
      'bytes=$extractedBytes',
    );

    // 임시 zip 파일 삭제
    await file.delete();
    await DebugLog.info('ADOFAI temp zip deleted');

    onPhase?.call(LoaderInstallPhase.configuring);
    await DebugLog.info('ADOFAI configuring native install');
    await MelonLoaderPlatform.configureNativeInstall(
      gamePath,
      isProtonOrWine: isProtonOrWine,
    );
    await DebugLog.info('ADOFAI native configure returned');

    // MelonLoader 버전 정보 파일 기록
    onPhase?.call(LoaderInstallPhase.finalizing);
    final versionFile = File(
      p.join(gamePath, 'MelonLoader', 'MelonLoader.version'),
    );
    try {
      if (!versionFile.parent.existsSync()) {
        await versionFile.parent.create(recursive: true);
      }
      await versionFile.writeAsString(MelonLoaderPlatform.version, flush: true);
      await DebugLog.info('ADOFAI version file written: ${versionFile.path}');
    } catch (e, stackTrace) {
      await DebugLog.error(
        'ADOFAI version file write failed',
        error: e,
        stackTrace: stackTrace,
      );
    }

    // 모드 폴더 미리 생성
    final modsDir = Directory(p.join(gamePath, 'Mods'));
    if (!modsDir.existsSync()) {
      await modsDir.create();
    }
    await DebugLog.info('ADOFAI installLoader finished');
  }

  // MelonLoader 환경에 남아 있는 UMM 자체 로더(Doorstop 프록시, Assembly 패치)를 제거합니다.
  // 남아 있으면 UMMBridge가 UnityModManager.dll 을 다시 설치하는 순간 UMM이 두 번 시작되어 게임이 크래시합니다.
  @override
  Future<void> repairLoaderConflicts(String gamePath) async {
    if (gamePath.isEmpty || !isLoaderInstalled(gamePath)) return;
    try {
      await _removeUmmDoorstop(gamePath);
      for (final managedPath in _managedPaths(gamePath)) {
        await _restoreUmmPatchedAssemblies(managedPath);
      }
    } catch (e, stackTrace) {
      await DebugLog.error(
        'ADOFAI UMM loader conflict repair failed',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  List<String> _managedPaths(String gamePath) {
    final candidates = [
      p.join(gamePath, 'A Dance of Fire and Ice_Data', 'Managed'),
      p.join(gamePath, 'ADanceOfFireAndIce_Data', 'Managed'),
      p.join(
        gamePath,
        'A Dance of Fire and Ice.app',
        'Contents',
        'Resources',
        'Data',
        'Managed',
      ),
      p.join(
        gamePath,
        'ADanceOfFireAndIce.app',
        'Contents',
        'Resources',
        'Data',
        'Managed',
      ),
      p.join(gamePath, 'Contents', 'Resources', 'Data', 'Managed'),
    ];
    return candidates.where((d) => Directory(d).existsSync()).toList();
  }

  static bool _containsAscii(List<int> bytes, String needle) {
    final pattern = needle.codeUnits;
    final last = bytes.length - pattern.length;
    outer:
    for (var i = 0; i <= last; i++) {
      for (var j = 0; j < pattern.length; j++) {
        if (bytes[i + j] != pattern[j]) continue outer;
      }
      return true;
    }
    return false;
  }

  static Future<bool> _isUmmPatchedAssembly(File file) async {
    if (!await file.exists()) return false;
    return _containsAscii(await file.readAsBytes(), 'UnityModManager');
  }

  // UMM DoorstopProxy 설치(winhttp.dll + doorstop_config.ini) 제거.
  // MelonLoader(Windows)는 version.dll 을 사용하므로 winhttp.dll 이 덮어써지지 않고 남습니다.
  Future<void> _removeUmmDoorstop(String gamePath) async {
    final config = File(p.join(gamePath, 'doorstop_config.ini'));
    if (!await config.exists()) return;

    final configContent = await config.readAsString();
    if (!configContent.toLowerCase().contains('unitymodmanager')) return;

    await config.delete();
    await DebugLog.info('Removed UMM doorstop config: ${config.path}');

    final proxy = File(p.join(gamePath, 'winhttp.dll'));
    if (await proxy.exists()) {
      final bytes = await proxy.readAsBytes();
      if (!_containsAscii(bytes, 'MelonLoader')) {
        await proxy.delete();
        await DebugLog.info('Removed UMM doorstop proxy: ${proxy.path}');
      }
    }
  }

  // UMM Assembly 설치 방식으로 패치된 Unity DLL 을 원본으로 복구합니다.
  // UMM 은 원본을 '<dll>.original_', 설치 직전 상태를 '<dll>.backup_' 으로 보관합니다.
  Future<void> _restoreUmmPatchedAssemblies(String managedPath) async {
    const targetDlls = ['UnityEngine.CoreModule.dll', 'UnityEngine.dll'];
    const backupSuffixes = ['.original_', '.backup_', '.original', '.bak'];

    for (final dllName in targetDlls) {
      final dllFile = File(p.join(managedPath, dllName));
      final backups = backupSuffixes
          .map((suffix) => File('${dllFile.path}$suffix'))
          .where((f) => f.existsSync())
          .toList();
      if (backups.isEmpty) continue;
      if (!await _isUmmPatchedAssembly(dllFile)) continue;

      File? clean;
      for (final backup in backups) {
        if (!await _isUmmPatchedAssembly(backup)) {
          clean = backup;
          break;
        }
      }
      if (clean == null) {
        await DebugLog.info(
          'UMM-patched $dllName has no clean backup; verify game files',
        );
        continue;
      }

      await clean.copy(dllFile.path);
      await DebugLog.info('Restored $dllName from ${p.basename(clean.path)}');
    }
  }

  @override
  Future<void> uninstallLoader(String gamePath) async {
    await MelonLoaderPlatform.cleanupNativeInstall(gamePath);

    // 멜론로더 관련 파일 및 폴더 목록
    final targets = [
      'MelonLoader',
      'winhttp.dll',
      'version.dll',
      'setup_helper.sh',
      'melonloader-launch.sh',
      'MelonLoader.Bootstrap.dylib',
      'MelonLoader.Bootstrap.so',
      'MelonLoader.Bootstrap.dylib.dSYM',
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
    // 임시 파일 다운로드 경로 설정
    final tempDir = await getTemporaryDirectory();
    final tempFilePath = p.join(tempDir.path, '${mod.slug}_temp_${DateTime.now().microsecondsSinceEpoch}');

    // 1. 모드 파일 다운로드
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

    // Downloads run concurrently; extracting and updating the installed-mods metadata is serialized
    final release = await Game.fsLock.acquire();
    try {

    final List<String> installedFiles = [];
    final fileBytes = await file.readAsBytes();

    // 아카이브 확인 및 스캔
    final decodedArchive = await decodeModArchive(fileBytes);
    final archive = decodedArchive.archive;
    final decodedBytes = decodedArchive.bytes;

    final List<String> infoJsonPaths = [];
    bool isUmm = false;
    String finalSlug = mod.slug;
    String finalName = mod.name;
    String ummFolder = mod.slug;

    if (archive != null) {
      // 2. 모드 포맷(UMM vs MelonLoader) 감지

      for (final archiveFile in archive) {
        final filename = archiveFile.name;
        final baseName = p.basename(filename).toLowerCase();
        if (baseName == 'info.json' && archiveFile.isFile) {
          isUmm = true;
          infoJsonPaths.add(filename);
        }
      }

      if (isUmm) {
        // UMM 인 경우 info.json 파일을 먼저 찾아서 Id를 획득해 slug 및 name 동기화
        ArchiveFile? firstInfoFile;
        for (final archiveFile in archive) {
          if (p.basename(archiveFile.name).toLowerCase() == 'info.json' &&
              archiveFile.isFile) {
            firstInfoFile = archiveFile;
            break;
          }
        }

        if (firstInfoFile != null) {
          try {
            final data = firstInfoFile.content as List<int>;
            final content = utf8.decode(data);
            final Map<String, dynamic> infoJson = jsonDecode(content);
            final String id = infoJson['Id'] ?? mod.slug;
            final String displayName = infoJson['DisplayName'] ?? mod.name;
            finalSlug = 'umm-$id';
            finalName = '$displayName (UMM)';
            ummFolder = id;
          } catch (_) {
            finalSlug = 'umm-${mod.slug}';
            finalName = '${mod.name} (UMM)';
          }
        }
      }
    }

    // 파일 추출 전에 로컬 메타데이터를 불러오고, 기존에 동일한 모드가 설치되어 있는 경우 안전하게 먼저 언인스톨을 수행합니다.
    final installedMods = await getInstalledMods(gamePath);
    try {
      final matchingMods = installedMods
          .where(
            (m) =>
                isModMatched(m.slug, mod.slug) ||
                m.id.toLowerCase() == finalSlug.toLowerCase(),
          )
          .toList();
      for (final matching in matchingMods) {
        await uninstallMod(gamePath, matching.slug);
      }
    } catch (_) {
      // 기존 모드 삭제 실패 시에도 설치 계속 진행
    }

    // 언인스톨 수행 후의 최신 로컬 메타데이터 목록 로드
    final updatedInstalledMods = await getInstalledMods(gamePath);

    if (archive != null) {
      if (isUmm) {
        // UMM 모드 설치 로직
        final ummBaseDir = Directory(p.join(gamePath, 'UMMMods'));
        if (!ummBaseDir.existsSync()) {
          await ummBaseDir.create(recursive: true);
        }

        // info.json들의 부모 폴더 경로 추출
        final parentFolders = infoJsonPaths
            .map((path) => p.dirname(path))
            .toList();

        // 만약 부모 폴더가 루트("")밖에 없다면, 아카이브 내용물을 UMMMods/<ummFolder> 폴더 아래에 생성
        final bool isRootOnly = parentFolders.every(
          (parent) => parent == '.' || parent == '',
        );

        for (final archiveFile in archive) {
          final filename = resolveModArchivePath(archiveFile.name, gamePath);
          String outPath;
          String relativePath;

          if (isRootOnly) {
            outPath = p.join(ummBaseDir.path, ummFolder, filename);
            relativePath = p.join('UMMMods', ummFolder, filename);
          } else {
            outPath = p.join(ummBaseDir.path, filename);
            relativePath = p.join('UMMMods', filename);
          }

          if (archiveFile.isFile) {
            final data = archiveFile.content as List<int>;
            final outFile = File(outPath);
            await outFile.create(recursive: true);
            await outFile.writeAsBytes(data);
            installedFiles.add(relativePath);
          } else {
            await Directory(outPath).create(recursive: true);
            if (!isProtectedGameDirectory(relativePath)) {
              installedFiles.add(relativePath);
            }
          }
        }
      } else {
        // MelonLoader 모드 설치
        bool hasStructuredDirs = false;
        bool hasGameRootPath = false;
        for (final archiveFile in archive) {
          if (isModArchiveGameRootPath(archiveFile.name)) {
            hasGameRootPath = true;
          }
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
          }
        }

        final String targetBaseDir = hasStructuredDirs || hasGameRootPath
            ? gamePath
            : p.join(gamePath, 'Mods');

        for (final archiveFile in archive) {
          final filename = resolveModArchivePath(archiveFile.name, gamePath);
          final outPath = p.join(targetBaseDir, filename);
          final relativePath = hasStructuredDirs || hasGameRootPath
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
            if (!isProtectedGameDirectory(relativePath)) {
              installedFiles.add(relativePath);
            }
          }
        }
      }
    } else {
      // 아카이브가 아니면 단일 DLL 파일로 저장
      final modsDir = Directory(p.join(gamePath, 'Mods'));
      if (!modsDir.existsSync()) {
        await modsDir.create(recursive: true);
      }
      final destPath = p.join(modsDir.path, '${mod.slug}.dll');
      final destFile = File(destPath);
      await destFile.writeAsBytes(decodedBytes);
      installedFiles.add(p.join('Mods', '${mod.slug}.dll'));
    }

    // 임시 다운로드 파일 삭제
    await file.delete();

    // 기존에 이미 동일한 모드가 설치되어 있었으면 제거 후 갱신
    updatedInstalledMods.removeWhere(
      (m) =>
          isModMatched(m.slug, mod.slug) ||
          m.id.toLowerCase() == finalSlug.toLowerCase(),
    );

    updatedInstalledMods.add(
      InstalledMod(
        id: finalSlug, // 'umm-Tweaks'
        slug: mod.slug, // 'adofai-tweaks' (본래 서버 슬러그를 보존하여 매칭에 사용)
        name: finalName,
        version: version,
        isBeta: isBeta,
        installedAt: DateTime.now().toIso8601String(),
        installedFiles: installedFiles,
      ),
    );

    await saveInstalledMods(gamePath, updatedInstalledMods);
      } finally {
      release();
      if (await file.exists()) await file.delete().catchError((_) => file);
    }
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
    final cleanName = filenameNoExt.replaceAll(
      RegExp(r'[-_\s]+v?[0-9]+(?:\.[0-9]+)*.*$'),
      '',
    );
    final baseSlug = cleanName.isEmpty ? filenameNoExt : cleanName;

    final List<String> installedFiles = [];
    final fileBytes = await file.readAsBytes();

    // 파일 추출 전에 로컬 메타데이터를 먼저 불러옵니다.
    final installedMods = await getInstalledMods(gamePath);

    final decodedArchive = await decodeModArchive(fileBytes);
    final archive = decodedArchive.archive;
    final decodedBytes = decodedArchive.bytes;

    final List<String> infoJsonPaths = [];
    bool isUmm = false;
    String finalSlug = baseSlug.toLowerCase();
    String finalName = baseSlug;
    String finalVersion = 'Local';
    String ummFolder = baseSlug;

    if (archive != null) {
      // UMM vs MelonLoader 감지
      for (final archiveFile in archive) {
        final filename = archiveFile.name;
        final baseName = p.basename(filename).toLowerCase();
        if (baseName == 'info.json' && archiveFile.isFile) {
          isUmm = true;
          infoJsonPaths.add(filename);
        }
      }

      if (isUmm) {
        // UMM 인 경우 info.json 내용을 먼저 읽어서 metadata 획득
        ArchiveFile? firstInfoFile;
        for (final archiveFile in archive) {
          if (p.basename(archiveFile.name).toLowerCase() == 'info.json' &&
              archiveFile.isFile) {
            firstInfoFile = archiveFile;
            break;
          }
        }

        if (firstInfoFile != null) {
          try {
            final data = firstInfoFile.content as List<int>;
            final content = utf8.decode(data);
            final Map<String, dynamic> infoJson = jsonDecode(content);
            final String id = infoJson['Id'] ?? finalSlug;
            final String displayName = infoJson['DisplayName'] ?? finalName;
            finalVersion = infoJson['Version'] ?? 'Local';
            finalSlug = 'umm-$id';
            finalName = '$displayName (UMM)';
            ummFolder = id;
          } catch (_) {
            finalSlug = 'umm-$finalSlug';
            finalName = '$finalName (UMM)';
          }
        }
      }
    }

    // MelonLoader DLL 파싱 (MelonInfo 속성 추출)
    if (!isUmm) {
      if (archive != null) {
        for (final archiveFile in archive) {
          if (archiveFile.isFile &&
              p.extension(archiveFile.name).toLowerCase() == '.dll') {
            try {
              final tempDir = await getTemporaryDirectory();
              final tempDllFile = File(
                p.join(
                  tempDir.path,
                  'temp_parse_${DateTime.now().microsecondsSinceEpoch}.dll',
                ),
              );
              await tempDllFile.writeAsBytes(archiveFile.content as List<int>);
              final info = MelonDllParser.parse(tempDllFile.path);
              try {
                await tempDllFile.delete();
              } catch (_) {}
              if (info != null) {
                finalName = info.name;
                finalVersion = info.version;
                finalSlug = info.name.toLowerCase().replaceAll(
                  RegExp(r'[^a-z0-9_-]'),
                  '-',
                );
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
            finalSlug = info.name.toLowerCase().replaceAll(
              RegExp(r'[^a-z0-9_-]'),
              '-',
            );
          }
        } catch (_) {}
      }
    }

    finalSlug = canonicalModSlug(finalSlug);

    // 기존 모드가 설치되어 있는 경우 안전하게 먼저 언인스톨을 수행합니다.
    try {
      final matchingMods = installedMods
          .where(
            (m) =>
                isModMatched(m.slug, finalSlug) ||
                m.id.toLowerCase() == finalSlug.toLowerCase(),
          )
          .toList();
      for (final matching in matchingMods) {
        await uninstallMod(gamePath, matching.slug);
      }
    } catch (_) {
      // 기존 모드 삭제 실패 시에도 설치 계속 진행
    }

    // 언인스톨 후의 최신 로컬 메타데이터 목록 로드
    final updatedInstalledMods = await getInstalledMods(gamePath);

    if (archive != null) {
      if (isUmm) {
        // UMM 모드 설치
        final ummBaseDir = Directory(p.join(gamePath, 'UMMMods'));
        if (!ummBaseDir.existsSync()) {
          await ummBaseDir.create(recursive: true);
        }

        final parentFolders = infoJsonPaths
            .map((path) => p.dirname(path))
            .toList();
        final bool isRootOnly = parentFolders.every(
          (parent) => parent == '.' || parent == '',
        );

        for (final archiveFile in archive) {
          final filename = resolveModArchivePath(archiveFile.name, gamePath);
          String outPath;
          String relativePath;

          if (isRootOnly) {
            outPath = p.join(ummBaseDir.path, ummFolder, filename);
            relativePath = p.join('UMMMods', ummFolder, filename);
          } else {
            outPath = p.join(ummBaseDir.path, filename);
            relativePath = p.join('UMMMods', filename);
          }

          if (archiveFile.isFile) {
            final data = archiveFile.content as List<int>;
            final outFile = File(outPath);
            await outFile.create(recursive: true);
            await outFile.writeAsBytes(data);
            installedFiles.add(relativePath);
          } else {
            await Directory(outPath).create(recursive: true);
            if (!isProtectedGameDirectory(relativePath)) {
              installedFiles.add(relativePath);
            }
          }
        }
      } else {
        // MelonLoader 모드 설치
        bool hasStructuredDirs = false;
        bool hasGameRootPath = false;
        for (final archiveFile in archive) {
          if (isModArchiveGameRootPath(archiveFile.name)) {
            hasGameRootPath = true;
          }
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
          }
        }

        final String targetBaseDir = hasStructuredDirs || hasGameRootPath
            ? gamePath
            : p.join(gamePath, 'Mods');

        for (final archiveFile in archive) {
          final filename = resolveModArchivePath(archiveFile.name, gamePath);
          final outPath = p.join(targetBaseDir, filename);
          final relativePath = hasStructuredDirs || hasGameRootPath
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
            if (!isProtectedGameDirectory(relativePath)) {
              installedFiles.add(relativePath);
            }
          }
        }
      }
    } else {
      // DLL 파일 단일 설치
      final modsDir = Directory(p.join(gamePath, 'Mods'));
      if (!modsDir.existsSync()) {
        await modsDir.create(recursive: true);
      }
      final sanitizedFileName = finalName.replaceAll(
        RegExp(r'[\\/:*?"<>|]'),
        '',
      );
      final destFileName =
          decodedArchive.wasCompressed && decodedArchive.hasDllSignature
          ? (sanitizedFileName.toLowerCase().endsWith('.dll')
                ? sanitizedFileName
                : '$sanitizedFileName.dll')
          : '$sanitizedFileName$ext';
      final destPath = p.join(modsDir.path, destFileName);
      final destFile = File(destPath);
      await destFile.writeAsBytes(decodedBytes);
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
        slug: finalSlug, // 수동 설치이므로 id와 동일하게 처리
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
    final cleanTargetSlug = modSlug.startsWith('umm-')
        ? modSlug.substring(4)
        : modSlug;

    // 타겟 모드가 설치한 파일 목록 중, 다른 모드에서도 공유하는 파일이 있는지 체크
    final otherMods = installedMods
        .where((m) => !isModMatched(m.slug, modSlug))
        .toList();
    final Set<String> sharedFiles = {};
    for (final other in otherMods) {
      for (final file in other.installedFiles) {
        sharedFiles.add(file.toLowerCase().replaceAll('\\', '/'));
      }
    }

    // 안전하게 디렉토리를 지우면서 배포 파일만 삭제하고 세이브데이터/커스텀 리소스를 보존하는 헬퍼 함수
    Future<void> safeDeleteDirectory(Directory dir) async {
      if (!dir.existsSync()) return;
      try {
        final entities = dir.listSync(recursive: true);

        // 1. 배포 바이너리 및 메타데이터 파일만 삭제
        for (final entity in entities) {
          if (entity is File) {
            final relativeEntityPath = p
                .relative(entity.path, from: gamePath)
                .toLowerCase()
                .replaceAll('\\', '/');
            if (sharedFiles.contains(relativeEntityPath)) {
              // 다른 모드에서 의존하거나 공유하는 파일이므로 삭제하지 않고 건너뜁니다.
              continue;
            }

            final filename = p.basename(entity.path).toLowerCase();
            final ext = p.extension(entity.path).toLowerCase();

            // 삭제 대상 핵심 배포 파일 규칙:
            // - info.json / Info.json
            // - *.dll / *.pdb / *.mdb / *.so / *.dylib (바이너리 라이브러리)
            // - readme / changelog / license 관련 텍스트/마크다운 파일
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

            final shouldDelete = isInfoJson || isBinary || isDoc;
            if (shouldDelete) {
              try {
                await entity.delete();
              } catch (_) {}
            }
          }
        }

        // 2. 비어있는 하위 폴더들을 안쪽부터 순서대로 삭제 (사용자 파일이 남아있는 폴더는 삭제 시 실패하여 안전하게 유지됨)
        final subDirs = entities.whereType<Directory>().toList();
        subDirs.sort((a, b) => b.path.length.compareTo(a.path.length));
        for (final subDir in subDirs) {
          if (subDir.existsSync()) {
            try {
              await subDir.delete();
            } catch (_) {}
          }
        }

        // 3. 루트 폴더 자체도 비어있으면 삭제 시도 (비어있지 않으면 그대로 유지)
        try {
          await dir.delete();
        } catch (_) {}
      } catch (_) {}
    }

    // 기록되어 있던 설치 파일들을 차례대로 삭제
    for (final relPath in targetMod.installedFiles) {
      final normalizedRelPath = relPath.toLowerCase().replaceAll('\\', '/');
      if (sharedFiles.contains(normalizedRelPath)) {
        // 다른 모드에서도 의존하거나 공유하는 파일이므로 삭제하지 않고 건너뜁니다.
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
        // 공용 폴더(Mods, Plugins, UserLibs, UMMMods 등) 자체는 삭제하거나 내부를 전체 스캔하여 지우지 않도록 보호합니다.
        final relativeToGame = p
            .relative(fullPath, from: gamePath)
            .toLowerCase()
            .replaceAll('\\', '/');
        if (!isProtectedGameDirectory(relativeToGame)) {
          final dir = Directory(fullPath);
          await safeDeleteDirectory(dir);
        }
      }
    }

    // 혹시라도 지워지지 않았을 경우를 대비해 slug.dll 이 존재하면 삭제
    final fallbackDll = File(p.join(gamePath, 'Mods', '$cleanTargetSlug.dll'));
    final fallbackDllD = File(
      p.join(gamePath, 'Mods', '$cleanTargetSlug.dll.disabled'),
    );
    if (fallbackDll.existsSync() &&
        !sharedFiles.contains('mods/${cleanTargetSlug.toLowerCase()}.dll')) {
      await fallbackDll.delete();
    }
    if (fallbackDllD.existsSync() &&
        !sharedFiles.contains('mods/${cleanTargetSlug.toLowerCase()}.dll')) {
      await fallbackDllD.delete();
    }
    final fallbackDllLower = File(
      p.join(gamePath, 'Mods', '${cleanTargetSlug.toLowerCase()}.dll'),
    );
    final fallbackDllLowerD = File(
      p.join(gamePath, 'Mods', '${cleanTargetSlug.toLowerCase()}.dll.disabled'),
    );
    if (fallbackDllLower.existsSync() &&
        !sharedFiles.contains('mods/${cleanTargetSlug.toLowerCase()}.dll')) {
      await fallbackDllLower.delete();
    }
    if (fallbackDllLowerD.existsSync() &&
        !sharedFiles.contains('mods/${cleanTargetSlug.toLowerCase()}.dll')) {
      await fallbackDllLowerD.delete();
    }

    // 메타데이터 리스트에서 제거 및 저장
    installedMods.removeWhere((m) => isModMatched(m.slug, modSlug));
    await saveInstalledMods(gamePath, installedMods);
  }

  @override
  Future<List<InstalledMod>> getInstalledMods(String gamePath) async {
    final List<InstalledMod> result = [];
    final Set<String> claimedFiles = {};

    // 1. modlist_installed.json (메타데이터 파일) 로드
    final metaFile = File(getInstalledModsMetaPath(gamePath));
    final List<InstalledMod> metaMods = [];
    if (metaFile.existsSync()) {
      try {
        final content = metaFile.readAsStringSync();
        final List<dynamic> jsonList = jsonDecode(content);
        metaMods.addAll(
          migrateInstalledMods(
            gamePath,
            jsonList.map((j) => InstalledMod.fromJson(j)).toList(),
          ),
        );
      } catch (_) {}
    }

    // 파일 개수가 많은(상세 정보가 있는) 메타데이터 모드를 우선 처리하여
    // 나중에 단순 스캔 모드가 클레임되거나 중복 검사로 스킵되도록 내림차순 정렬합니다.
    metaMods.sort(
      (a, b) => b.installedFiles.length.compareTo(a.installedFiles.length),
    );

    // 2. 메타데이터에 등록된 모드 중 실제로 파일이 존재하는 모드를 결과 리스트에 추가
    for (final metaMod in metaMods) {
      bool exists = false;
      // 설치 기록된 파일 중 하나라도 실제 존재하면 설치된 것으로 간주
      for (final relPath in metaMod.installedFiles) {
        final fullPath = p.join(gamePath, relPath);
        final disabledPath = '$fullPath.disabled';
        if (FileSystemEntity.isFileSync(fullPath) ||
            FileSystemEntity.isDirectorySync(fullPath) ||
            (relPath.toLowerCase().endsWith('.dll') &&
                FileSystemEntity.isFileSync(disabledPath))) {
          exists = true;
          break;
        }
      }

      // 만약 설치 기록 파일 목록 자체가 비어있다면, UMM 폴더나 DLL이 있는지 fallback으로 체크
      if (metaMod.installedFiles.isEmpty) {
        final cleanSlug = metaMod.slug.startsWith('umm-')
            ? metaMod.slug.substring(4)
            : metaMod.slug;
        final ummDir = Directory(p.join(gamePath, 'UMMMods', cleanSlug));
        final modDll = File(p.join(gamePath, 'Mods', '$cleanSlug.dll'));
        final pluginDll = File(p.join(gamePath, 'Plugins', '$cleanSlug.dll'));
        final modDllD = File(
          p.join(gamePath, 'Mods', '$cleanSlug.dll.disabled'),
        );
        final pluginDllD = File(
          p.join(gamePath, 'Plugins', '$cleanSlug.dll.disabled'),
        );
        if (ummDir.existsSync() ||
            modDll.existsSync() ||
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

        // 만약 모드의 모든 설치 파일이 이미 다른 상세한 모드에 의해 점유(Claimed)되었다면 중복 모드로 판단하고 스킵
        if (metaMod.installedFiles.isNotEmpty && allFilesClaimed) {
          continue;
        }

        result.add(getActualModInfoFromDisk(gamePath, metaMod));
        for (final relPath in metaMod.installedFiles) {
          claimedFiles.add(relPath.toLowerCase().replaceAll('\\', '/'));
        }
      }
    }

    // 3. UMMMods/ 폴더 스캔 (메타데이터에 등록되지 않은 수동 설치 모드 감지)
    final ummModsDir = Directory(p.join(gamePath, 'UMMMods'));
    if (ummModsDir.existsSync()) {
      try {
        final entities = ummModsDir.listSync();
        for (final entity in entities) {
          if (entity is Directory) {
            final folderName = p.basename(entity.path);
            final relPath = p.join('UMMMods', folderName);
            final normalizedRelPath = relPath.toLowerCase().replaceAll(
              '\\',
              '/',
            );

            // 이미 메타데이터에 의해 클레임된 폴더인 경우 건너뜁니다.
            if (claimedFiles.contains(normalizedRelPath) ||
                claimedFiles.any((f) => f.startsWith('$normalizedRelPath/'))) {
              continue;
            }

            final infoFile = File(p.join(entity.path, 'info.json'));
            final infoFileAlt = File(p.join(entity.path, 'Info.json'));

            File? actualInfoFile;
            if (infoFile.existsSync()) {
              actualInfoFile = infoFile;
            } else if (infoFileAlt.existsSync()) {
              actualInfoFile = infoFileAlt;
            }

            if (actualInfoFile != null) {
              try {
                final content = actualInfoFile.readAsStringSync();
                final Map<String, dynamic> infoJson = jsonDecode(content);

                final String id = infoJson['Id'] ?? folderName;
                final String displayName = infoJson['DisplayName'] ?? id;
                final String version = infoJson['Version'] ?? '1.0.0';
                final String slug = 'umm-$id';

                // 이미 동일한 UMM ID를 가진 모드가 결과 목록(메타데이터 모드 등)에 존재하는 경우 건너뜁니다.
                final hasDuplicate = result.any(
                  (m) =>
                      m.id.toLowerCase() == slug.toLowerCase() ||
                      isModMatched(m.slug, slug),
                );
                if (hasDuplicate) {
                  continue;
                }

                result.add(
                  InstalledMod(
                    id: slug,
                    slug: slug,
                    name: '$displayName (UMM)',
                    version: version,
                    isBeta: false,
                    installedAt: entity.statSync().modified.toIso8601String(),
                    installedFiles: [relPath],
                  ),
                );
              } catch (_) {}
            }
          }
        }
      } catch (_) {}
    }

    // 4. Mods/ 폴더 스캔 (메타데이터에 등록되지 않은 수동 설치 MelonLoader 모드 감지)
    final modsDir = Directory(p.join(gamePath, 'Mods'));
    if (modsDir.existsSync()) {
      try {
        final entities = modsDir.listSync();
        for (final entity in entities) {
          final isDll = p.extension(entity.path).toLowerCase() == '.dll';
          final isDllDisabled = entity.path.toLowerCase().endsWith(
            '.dll.disabled',
          );
          if (entity is File && (isDll || isDllDisabled)) {
            final fileName = isDllDisabled
                ? p
                      .basename(entity.path)
                      .substring(
                        0,
                        p.basename(entity.path).length - '.disabled'.length,
                      )
                : p.basenameWithoutExtension(entity.path);
            final relPath = isDllDisabled
                ? p.join(
                    'Mods',
                    p
                        .basename(entity.path)
                        .substring(
                          0,
                          p.basename(entity.path).length - '.disabled'.length,
                        ),
                  )
                : p.join('Mods', p.basename(entity.path));
            final normalizedRelPath = relPath.toLowerCase().replaceAll(
              '\\',
              '/',
            );

            // 이미 메타데이터에 의해 클레임된 파일인 경우 건너뜁니다.
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
                slug = info.name.toLowerCase().replaceAll(
                  RegExp(r'[^a-z0-9_-]'),
                  '-',
                );
              }
            } catch (_) {}

            result.add(
              InstalledMod(
                id: canonicalModSlug(slug),
                slug: canonicalModSlug(slug),
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

    // 5. Plugins/ 폴더 스캔 (메타데이터에 등록되지 않은 수동 설치 MelonLoader 플러그인 감지)
    final pluginsDir = Directory(p.join(gamePath, 'Plugins'));
    if (pluginsDir.existsSync()) {
      try {
        final entities = pluginsDir.listSync();
        for (final entity in entities) {
          final isDll = p.extension(entity.path).toLowerCase() == '.dll';
          final isDllDisabled = entity.path.toLowerCase().endsWith(
            '.dll.disabled',
          );
          if (entity is File && (isDll || isDllDisabled)) {
            final fileName = isDllDisabled
                ? p
                      .basename(entity.path)
                      .substring(
                        0,
                        p.basename(entity.path).length - '.disabled'.length,
                      )
                : p.basenameWithoutExtension(entity.path);
            final relPath = isDllDisabled
                ? p.join(
                    'Plugins',
                    p
                        .basename(entity.path)
                        .substring(
                          0,
                          p.basename(entity.path).length - '.disabled'.length,
                        ),
                  )
                : p.join('Plugins', p.basename(entity.path));
            final normalizedRelPath = relPath.toLowerCase().replaceAll(
              '\\',
              '/',
            );

            // 이미 메타데이터에 의해 클레임된 파일인 경우 건너뜁니다.
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
                slug = info.name.toLowerCase().replaceAll(
                  RegExp(r'[^a-z0-9_-]'),
                  '-',
                );
              }
            } catch (_) {}

            result.add(
              InstalledMod(
                id: canonicalModSlug(slug),
                slug: canonicalModSlug(slug),
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
  String? getSteamLaunchOptionsGuideKey() {
    if (Platform.isWindows) {
      return null;
    } else if (Platform.isLinux) {
      return 'installed_steamlaunchoptionsguide_adofai_linux';
    } else if (Platform.isMacOS) {
      return 'installed_steamlaunchoptionsguide_adofai_macos';
    }
    return null;
  }
}
