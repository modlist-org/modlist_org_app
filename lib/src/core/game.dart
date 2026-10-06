import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/mod_model.dart';
import 'archive_decoder.dart';
import 'melon_dll_parser.dart';

enum LoaderInstallPhase { extracting, configuring, finalizing }

abstract class Game {
  Future<DecodedArchive> decodeModArchive(List<int> bytes) {
    return ModArchiveDecoder.decode(bytes);
  }

  // 게임 고유 식별자 (예: 'adofai')
  String get id;

  // 게임명 (예: 'A Dance of Fire and Ice')
  String get name;

  // 플랫폼별 실행 파일 이름
  String getPlatformExeName() {
    if (Platform.isWindows) {
      return '$name.exe';
    } else if (Platform.isMacOS) {
      return '$name.app';
    } else {
      // Linux
      return name;
    }
  }

  String getModArchiveGameName(String gamePath) {
    return p.basenameWithoutExtension(getPlatformExeName());
  }

  String resolveModArchivePath(String archivePath, String gamePath) {
    return archivePath
        .replaceAll('\\', '/')
        .replaceAll('__gamename__', getModArchiveGameName(gamePath));
  }

  bool isModArchiveGameRootPath(String archivePath) {
    final firstPathPart = archivePath
        .replaceAll('\\', '/')
        .split('/')
        .firstWhere((part) => part.isNotEmpty && part != '.', orElse: () => '');
    return firstPathPart.contains('__gamename__');
  }

  // 플랫폼별 스팀 라이브러리 기본 경로
  String getPlatformDefaultPath() {
    final home =
        Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        '';
    if (Platform.isWindows) {
      return r'C:\Program Files (x86)\Steam\steamapps\common\' + name;
    } else if (Platform.isMacOS) {
      return p.join(
        home,
        'Library',
        'Application Support',
        'Steam',
        'steamapps',
        'common',
        name,
      );
    } else {
      // Linux
      // 일반적인 스팀 설치 경로 2가지 대응
      final path1 = p.join(
        home,
        '.steam',
        'steam',
        'steamapps',
        'common',
        name,
      );
      final path2 = p.join(
        home,
        '.local',
        'share',
        'Steam',
        'steamapps',
        'common',
        name,
      );
      if (Directory(path1).existsSync()) {
        return path1;
      }
      return path2;
    }
  }

  // Steam app manifest id, when known.
  String? get steamAppId => null;

  // Folder names Steam may use under steamapps/common.
  List<String> getSteamInstallFolderNames() => [name];

  String? findSteamInstallPath() {
    for (final candidate in getSteamInstallCandidatePaths()) {
      if (isValidGamePath(candidate)) {
        return candidate;
      }
    }
    return null;
  }

  List<String> getSteamInstallCandidatePaths() {
    final candidates = <String>[getPlatformDefaultPath()];

    for (final steamLibrary in _steamLibraryPaths()) {
      final steamApps = _steamAppsPathForLibrary(steamLibrary);
      final common = p.join(steamApps, 'common');

      final appId = steamAppId;
      if (appId != null) {
        final manifest = File(p.join(steamApps, 'appmanifest_$appId.acf'));
        final installDir = _readVdfValue(manifest, 'installdir');
        if (installDir != null && installDir.isNotEmpty) {
          candidates.add(p.join(common, installDir));
        }
      }

      for (final folderName in getSteamInstallFolderNames()) {
        candidates.add(p.join(common, folderName));
      }

      final commonDir = Directory(common);
      if (commonDir.existsSync()) {
        try {
          for (final entity in commonDir.listSync(followLinks: false)) {
            if (entity is Directory) {
              final folderName = p.basename(entity.path);
              if (_couldBeSteamInstallFolder(folderName)) {
                candidates.add(entity.path);
              }
            }
          }
        } catch (_) {}
      }
    }

    return _dedupePaths(candidates);
  }

  bool _couldBeSteamInstallFolder(String folderName) {
    final normalized = _normalizeSteamFolderName(folderName);
    if (normalized.isEmpty) return false;

    for (final expected in getSteamInstallFolderNames()) {
      final expectedNormalized = _normalizeSteamFolderName(expected);
      if (normalized == expectedNormalized ||
          normalized.contains(expectedNormalized) ||
          expectedNormalized.contains(normalized)) {
        return true;
      }
    }
    return false;
  }

  String _normalizeSteamFolderName(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }

  List<String> _steamLibraryPaths() {
    final roots = _steamRootCandidates();
    final libraries = <String>[...roots];

    for (final root in roots) {
      final vdfFiles = [
        File(p.join(root, 'steamapps', 'libraryfolders.vdf')),
        File(p.join(root, 'config', 'libraryfolders.vdf')),
      ];
      for (final vdfFile in vdfFiles) {
        libraries.addAll(_parseLibraryFolders(vdfFile));
      }
    }

    return _dedupePaths(libraries);
  }

  List<String> _steamRootCandidates() {
    final env = Platform.environment;
    final home = env['HOME'] ?? env['USERPROFILE'] ?? '';
    final candidates = <String>[];

    if (Platform.isWindows) {
      candidates.addAll([
        env['ProgramFiles(x86)'] == null
            ? ''
            : p.join(env['ProgramFiles(x86)']!, 'Steam'),
        env['PROGRAMFILES(X86)'] == null
            ? ''
            : p.join(env['PROGRAMFILES(X86)']!, 'Steam'),
        env['ProgramFiles'] == null
            ? ''
            : p.join(env['ProgramFiles']!, 'Steam'),
        r'C:\Program Files (x86)\Steam',
        r'C:\Program Files\Steam',
      ]);
    } else if (Platform.isMacOS) {
      candidates.add(p.join(home, 'Library', 'Application Support', 'Steam'));
    } else {
      candidates.addAll([
        p.join(home, '.steam', 'steam'),
        p.join(home, '.local', 'share', 'Steam'),
        p.join(
          home,
          '.var',
          'app',
          'com.valvesoftware.Steam',
          '.local',
          'share',
          'Steam',
        ),
      ]);
    }

    return _dedupePaths(candidates.where((path) => path.isNotEmpty));
  }

  String _steamAppsPathForLibrary(String libraryPath) {
    if (p.basename(libraryPath).toLowerCase() == 'steamapps') {
      return libraryPath;
    }
    return p.join(libraryPath, 'steamapps');
  }

  List<String> _parseLibraryFolders(File vdfFile) {
    if (!vdfFile.existsSync()) return [];

    try {
      final content = vdfFile.readAsStringSync();
      final matches = <String>[];

      final pathMatches = RegExp(
        r'"path"\s+"((?:\\.|[^"\\])*)"',
        caseSensitive: false,
      ).allMatches(content);
      for (final match in pathMatches) {
        matches.add(_unescapeVdfString(match.group(1)!));
      }

      final legacyMatches = RegExp(
        r'"\d+"\s+"((?:\\.|[^"\\])*)"',
      ).allMatches(content);
      for (final match in legacyMatches) {
        final value = _unescapeVdfString(match.group(1)!);
        if (value.contains('/') || value.contains(r'\')) {
          matches.add(value);
        }
      }

      return matches;
    } catch (_) {
      return [];
    }
  }

  String? _readVdfValue(File vdfFile, String key) {
    if (!vdfFile.existsSync()) return null;

    try {
      final content = vdfFile.readAsStringSync();
      final match = RegExp(
        '"$key"\\s+"((?:\\\\.|[^"\\\\])*)"',
        caseSensitive: false,
      ).firstMatch(content);
      if (match == null) return null;
      return _unescapeVdfString(match.group(1)!);
    } catch (_) {
      return null;
    }
  }

  String _unescapeVdfString(String value) {
    return value.replaceAll(r'\"', '"').replaceAll(r'\\', '\\');
  }

  List<String> _dedupePaths(Iterable<String> paths) {
    final seen = <String>{};
    final result = <String>[];
    for (final path in paths) {
      if (path.trim().isEmpty) continue;
      final normalized = p.normalize(path);
      if (seen.add(normalized)) {
        result.add(path);
      }
    }
    return result;
  }

  // 모드 로더가 설치되었는지 여부 확인
  bool isLoaderInstalled(String gamePath);

  // 모드 로더 설치
  Future<void> installLoader(
    String gamePath, {
    void Function(double)? onProgress,
    void Function(LoaderInstallPhase)? onPhase,
  });

  // 모드 로더 제거
  Future<void> uninstallLoader(String gamePath);

  // 설치된 모드 로더와 충돌하는 다른 로더의 잔재 정리
  Future<void> repairLoaderConflicts(String gamePath) async {}

  // 모드 설치
  Future<void> installMod(
    String gamePath,
    ModItem mod,
    String downloadUrl, {
    required String version,
    bool isBeta,
    void Function(double)? onProgress,
  });

  // 파일에서 모드 설치
  Future<void> installModFromFile(String gamePath, String filePath);

  // 모드 제거
  Future<void> uninstallMod(String gamePath, String modSlug);

  // 로컬에 기록된 설치된 모드 리스트 파일명
  String getInstalledModsMetaPath(String gamePath) {
    return p.join(gamePath, 'modlist_installed.json');
  }

  // 로컬 설치 모드 메타데이터 조회
  Future<List<InstalledMod>> getInstalledMods(String gamePath) async {
    final metaFile = File(getInstalledModsMetaPath(gamePath));
    if (!await metaFile.exists()) {
      return [];
    }

    try {
      final content = await metaFile.readAsString();
      final List<dynamic> jsonList = jsonDecode(content);
      return jsonList.map((j) => InstalledMod.fromJson(j)).toList();
    } catch (e) {
      // 파싱 에러 발생 시 빈 배열 반환
      return [];
    }
  }

  // 로컬 설치 모드 메타데이터 기록
  Future<void> saveInstalledMods(
    String gamePath,
    List<InstalledMod> installedMods,
  ) async {
    final metaFile = File(getInstalledModsMetaPath(gamePath));
    final jsonList = installedMods.map((m) => m.toJson()).toList();
    await metaFile.writeAsString(jsonEncode(jsonList), flush: true);
  }

  // UMM(Unity Mod Manager) 감지 여부
  bool isUmmDetected(String gamePath) {
    if (gamePath.isEmpty) return false;
    if (_hasUmmBridgePlugin(gamePath)) return false;

    // 1. UnityModManager 폴더 존재 여부
    final ummFolder = Directory(p.join(gamePath, 'UnityModManager'));
    if (ummFolder.existsSync()) return true;

    // 2. Managed 및 Assembly 폴더 경로 구성
    String? managedPath;
    String? assemblyPath;
    final exeName = getPlatformExeName();
    final exeNameNoExt = p.basenameWithoutExtension(exeName);

    if (Platform.isMacOS) {
      final appName = exeName.endsWith('.app') ? exeName : '$exeName.app';

      final macManaged = Directory(
        p.join(gamePath, appName, 'Contents', 'Resources', 'Data', 'Managed'),
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
        p.join(gamePath, appName, 'Contents', 'Resources', 'Data', 'Assembly'),
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
        p.join(gamePath, '${exeNameNoExt}_Data', 'Managed'),
      );
      if (winLinuxManaged.existsSync()) {
        managedPath = winLinuxManaged.path;
      }
      final winLinuxAssembly = Directory(
        p.join(gamePath, '${exeNameNoExt}_Data', 'Assembly'),
      );
      if (winLinuxAssembly.existsSync()) {
        assemblyPath = winLinuxAssembly.path;
      }
    }

    // 3. 파일 존재 여부 검사 (Managed)
    if (managedPath != null) {
      if (File(p.join(managedPath, 'UnityModManager.dll')).existsSync()) {
        return true;
      }
      if (File(
        p.join(managedPath, 'UnityModManager', 'UnityModManager.dll'),
      ).existsSync()) {
        return true;
      }
    }

    // 4. 파일 존재 여부 검사 (Assembly)
    if (assemblyPath != null) {
      if (File(p.join(assemblyPath, 'UnityModManager.dll')).existsSync()) {
        return true;
      }
      if (File(
        p.join(assemblyPath, 'UnityModManager', 'UnityModManager.dll'),
      ).existsSync()) {
        return true;
      }
    }

    return false;
  }

  bool _hasUmmBridgePlugin(String gamePath) {
    final pluginsDir = Directory(p.join(gamePath, 'Plugins'));
    if (!pluginsDir.existsSync()) return false;

    try {
      return pluginsDir
          .listSync(followLinks: false)
          .any(
            (entity) =>
                entity is File &&
                p.basename(entity.path).toLowerCase() == 'ummbridge.dll',
          );
    } catch (_) {
      return false;
    }
  }

  // 특정 게임 경로의 유효성 검사 (실행 파일 존재 여부 등)
  bool isValidGamePath(String gamePath) {
    if (gamePath.isEmpty) return false;
    final dir = Directory(gamePath);
    if (!dir.existsSync()) return false;

    // 대소문자나 플랫폼에 상관없이 유연하게 게임 실행 파일 검색
    try {
      final entities = dir.listSync();
      for (final entity in entities) {
        final name = p.basename(entity.path).toLowerCase();

        if (Platform.isWindows && name.endsWith('.exe')) {
          if (name.contains('dance') ||
              name.contains('fire') ||
              name.contains('ice') ||
              name.contains('adofai')) {
            return true;
          }
        } else if (Platform.isMacOS && name.endsWith('.app')) {
          if (name.contains('dance') ||
              name.contains('fire') ||
              name.contains('ice') ||
              name.contains('adofai')) {
            return true;
          }
        } else if (Platform.isLinux) {
          // 리눅스 네이티브 실행 파일 또는 Proton용 exe 감지
          if (name.endsWith('.exe') &&
              (name.contains('dance') ||
                  name.contains('fire') ||
                  name.contains('ice') ||
                  name.contains('adofai'))) {
            return true;
          }
          if (entity is File &&
              (name.endsWith('.x86_64') ||
                  name.endsWith('.x86') ||
                  !name.contains('.'))) {
            if (name.contains('dance') ||
                name.contains('fire') ||
                name.contains('ice') ||
                name.contains('adofai')) {
              return true;
            }
          }
        }
      }
    } catch (_) {
      // 스캔 도중 오류가 발생할 경우 폴더명 기반 감지로 fallback
    }

    // 폴더명 기반 백업 감지 (경로가 스팀 게임 디렉토리 구조면 유효한 것으로 판정)
    final folderName = p.basename(gamePath).toLowerCase();
    if (folderName.contains('dance of fire') || folderName.contains('adofai')) {
      return true;
    }

    return false;
  }

  // 모드 로더 버전 정보 조회 (멜론로더 등)
  String getLoaderVersion(String gamePath) => 'None';

  // 스팀 런치 옵션 가이드 스트링 (Linux/macOS 비네이티브용)
  String? getSteamLaunchOptionsGuideKey();

  // 로컬에서 감지되는 이름(소문자) -> 서버 슬러그. 이름이 바뀌었지만 서버 슬러그는 호환성을 위해 유지된 모드용
  Map<String, String> get modSlugAliases => const {};

  // 특정 파일(소문자, '/' 구분)이 설치되어 있으면 해당 서버 슬러그의 모드로 간주
  Map<String, String> get modFileAliases => const {};

  String canonicalModSlug(String slug) {
    return modSlugAliases[slug.toLowerCase()] ?? slug;
  }

  // 게임 루트, 공용 모드 폴더, 게임 데이터 폴더 등 모드가 소유할 수 없는 디렉토리인지 확인
  bool isProtectedGameDirectory(String relPath) {
    final segments = relPath
        .replaceAll('\\', '/')
        .toLowerCase()
        .split('/')
        .where((s) => s.isNotEmpty && s != '.')
        .toList();

    if (segments.isEmpty) return true;
    if (segments.contains('..')) return true;
    if (segments.length == 1 &&
        const {
          'mods',
          'plugins',
          'userlibs',
          'userdata',
          'ummmods',
          'melonloader',
        }.contains(segments.first)) {
      return true;
    }
    // <Game>_Data, <Game>_Data/Managed 등
    if (segments.first.endsWith('_data') && segments.length <= 2) return true;
    // macOS: <Game>.app/Contents/Resources/Data/Managed 까지
    if (segments.first.endsWith('.app') && segments.length <= 5) return true;
    return false;
  }

  // 메타데이터의 installedFiles 에서 보호 대상 디렉토리 항목을 제거
  List<String> sanitizeInstalledFiles(
    String gamePath,
    List<String> installedFiles,
  ) {
    return installedFiles
        .where(
          (relPath) =>
              !isProtectedGameDirectory(relPath) ||
              FileSystemEntity.isFileSync(p.join(gamePath, relPath)),
        )
        .toList();
  }

  // 메타데이터 마이그레이션: 보호 디렉토리 항목 제거, 이름이 바뀐 모드의 슬러그 정규화 및 중복 병합
  List<InstalledMod> migrateInstalledMods(
    String gamePath,
    List<InstalledMod> mods,
  ) {
    final migrated = <InstalledMod>[];
    for (final mod in mods) {
      final files = sanitizeInstalledFiles(gamePath, mod.installedFiles);

      String? aliasTarget;
      final canonical = canonicalModSlug(mod.slug);
      if (canonical != mod.slug) {
        aliasTarget = canonical;
      } else if (canonicalModSlug(mod.id) != mod.id) {
        aliasTarget = canonicalModSlug(mod.id);
      } else {
        for (final file in files) {
          final target =
              modFileAliases[file.toLowerCase().replaceAll('\\', '/')];
          if (target != null) {
            aliasTarget = target;
            break;
          }
        }
      }

      migrated.add(
        InstalledMod(
          id: aliasTarget ?? mod.id,
          slug: aliasTarget ?? mod.slug,
          name: mod.name,
          version: mod.version,
          isBeta: mod.isBeta,
          installedAt: mod.installedAt,
          installedFiles: files,
          isEnabled: mod.isEnabled,
        ),
      );
    }

    final aliasTargets = {
      ...modSlugAliases.values,
      ...modFileAliases.values,
    }.map((s) => s.toLowerCase()).toSet();
    if (aliasTargets.isEmpty) return migrated;

    final result = <InstalledMod>[];
    final mergedIndex = <String, int>{};
    for (final mod in migrated) {
      final key = mod.slug.toLowerCase();
      if (!aliasTargets.contains(key)) {
        result.add(mod);
        continue;
      }
      final existingIndex = mergedIndex[key];
      if (existingIndex == null) {
        mergedIndex[key] = result.length;
        result.add(mod);
        continue;
      }

      final existing = result[existingIndex];
      final primary =
          existing.installedFiles.length >= mod.installedFiles.length
          ? existing
          : mod;
      final secondary = identical(primary, existing) ? mod : existing;
      final seen = <String>{};
      final mergedFiles = <String>[];
      for (final file in [
        ...primary.installedFiles,
        ...secondary.installedFiles,
      ]) {
        if (seen.add(file.toLowerCase().replaceAll('\\', '/'))) {
          mergedFiles.add(file);
        }
      }
      result[existingIndex] = InstalledMod(
        id: primary.id,
        slug: primary.slug,
        name: primary.name,
        version: primary.version,
        isBeta: primary.isBeta,
        installedAt: primary.installedAt,
        installedFiles: mergedFiles,
        isEnabled: primary.isEnabled,
      );
    }
    return result;
  }

  // UMM ID(예: Tweaks)와 서버 슬러그(예: adofai-tweaks) 간의 유연한 매칭 지원 헬퍼
  bool isModMatched(String localSlug, String serverSlug) {
    localSlug = canonicalModSlug(localSlug);
    serverSlug = canonicalModSlug(serverSlug);
    final cleanLocal = localSlug.startsWith('umm-')
        ? localSlug.substring(4).toLowerCase()
        : localSlug.toLowerCase();
    final cleanServer = serverSlug.startsWith('umm-')
        ? serverSlug.substring(4).toLowerCase()
        : serverSlug.toLowerCase();

    if (cleanLocal == cleanServer) return true;

    final normLocal = cleanLocal
        .replaceAll('-', '')
        .replaceAll('_', '')
        .replaceAll(' ', '');
    final normServer = cleanServer
        .replaceAll('-', '')
        .replaceAll('_', '')
        .replaceAll(' ', '');

    if (normServer == normLocal) return true;
    if (normServer.endsWith(normLocal)) return true;
    if (normLocal.endsWith(normServer)) return true;

    return false;
  }

  // 디스크 상의 실제 파일 정보(info.json, MelonLoader DLL 등)를 파싱하여 최신 모드명과 버전을 반환
  InstalledMod getActualModInfoFromDisk(String gamePath, InstalledMod metaMod) {
    String displayName = metaMod.name;
    String displayVersion = metaMod.version;

    final isUmm =
        metaMod.id.startsWith('umm-') ||
        metaMod.installedFiles.any(
          (f) => f.toLowerCase().replaceAll('\\', '/').contains('ummmods/'),
        );

    if (isUmm) {
      final cleanSlug = metaMod.slug.startsWith('umm-')
          ? metaMod.slug.substring(4)
          : metaMod.slug;
      File? infoFile;
      for (final relPath in metaMod.installedFiles) {
        if (p.basename(relPath).toLowerCase() == 'info.json') {
          final fullPath = p.join(gamePath, relPath);
          if (FileSystemEntity.isFileSync(fullPath)) {
            infoFile = File(fullPath);
            break;
          }
        }
      }
      if (infoFile == null) {
        final f1 = File(p.join(gamePath, 'UMMMods', cleanSlug, 'info.json'));
        final f2 = File(p.join(gamePath, 'UMMMods', cleanSlug, 'Info.json'));
        final f3 = File(
          p.join(gamePath, 'UnityModManager', cleanSlug, 'info.json'),
        );
        final f4 = File(
          p.join(gamePath, 'UnityModManager', cleanSlug, 'Info.json'),
        );
        if (f1.existsSync()) {
          infoFile = f1;
        } else if (f2.existsSync()) {
          infoFile = f2;
        } else if (f3.existsSync()) {
          infoFile = f3;
        } else if (f4.existsSync()) {
          infoFile = f4;
        }
      }

      if (infoFile != null && infoFile.existsSync()) {
        try {
          final content = infoFile.readAsStringSync();
          final Map<String, dynamic> infoJson = jsonDecode(content);
          final String id = infoJson['Id'] ?? cleanSlug;
          final String nameVal = infoJson['DisplayName'] ?? id;
          displayName = '$nameVal (UMM)';
          displayVersion = infoJson['Version'] ?? metaMod.version;
        } catch (_) {}
      }
    } else {
      // MelonLoader DLL
      File? dllFile;
      for (final relPath in metaMod.installedFiles) {
        final lowerPath = relPath.toLowerCase();
        if (lowerPath.endsWith('.dll') || lowerPath.endsWith('.dll.disabled')) {
          final fullPath = p.join(gamePath, relPath);
          final disabledPath = lowerPath.endsWith('.dll.disabled')
              ? fullPath
              : '$fullPath.disabled';
          final normalPath = lowerPath.endsWith('.dll.disabled')
              ? fullPath.substring(0, fullPath.length - '.disabled'.length)
              : fullPath;

          if (FileSystemEntity.isFileSync(normalPath)) {
            dllFile = File(normalPath);
            break;
          } else if (FileSystemEntity.isFileSync(disabledPath)) {
            dllFile = File(disabledPath);
            break;
          }
        }
      }
      if (dllFile == null) {
        final cleanSlug = metaMod.slug.startsWith('umm-')
            ? metaMod.slug.substring(4)
            : metaMod.slug;
        final f1 = File(p.join(gamePath, 'Mods', '$cleanSlug.dll'));
        final f2 = File(p.join(gamePath, 'Plugins', '$cleanSlug.dll'));
        final f1d = File(p.join(gamePath, 'Mods', '$cleanSlug.dll.disabled'));
        final f2d = File(
          p.join(gamePath, 'Plugins', '$cleanSlug.dll.disabled'),
        );
        if (f1.existsSync()) {
          dllFile = f1;
        } else if (f2.existsSync()) {
          dllFile = f2;
        } else if (f1d.existsSync()) {
          dllFile = f1d;
        } else if (f2d.existsSync()) {
          dllFile = f2d;
        }
      }

      if (dllFile != null && dllFile.existsSync()) {
        try {
          final info = MelonDllParser.parse(dllFile.path);
          if (info != null) {
            final isPlugin = dllFile.path.toLowerCase().contains('plugins');
            displayName = isPlugin ? '${info.name} (Plugin)' : info.name;
            displayVersion = info.version;
          }
        } catch (_) {}
      }
    }

    return InstalledMod(
      id: metaMod.id,
      slug: metaMod.slug,
      name: displayName,
      version: displayVersion,
      isBeta: metaMod.isBeta,
      installedAt: metaMod.installedAt,
      installedFiles: metaMod.installedFiles,
      isEnabled: metaMod.isEnabled,
    );
  }

  // 모드 활성화 / 비활성화 (MelonLoader 모드 대상)
  Future<void> toggleModActive(
    String gamePath,
    InstalledMod mod,
    bool enable,
  ) async {
    if (mod.id.startsWith('umm-')) {
      return; // UMM 모드는 자체 기능이 있으므로 제외
    }

    for (final relPath in mod.installedFiles) {
      final lowerPath = relPath.toLowerCase();
      if (lowerPath.endsWith('.dll') || lowerPath.endsWith('.dll.disabled')) {
        final fullPath = p.join(gamePath, relPath);
        final disabledPath = lowerPath.endsWith('.dll.disabled')
            ? fullPath
            : '$fullPath.disabled';
        final normalPath = lowerPath.endsWith('.dll.disabled')
            ? fullPath.substring(0, fullPath.length - '.disabled'.length)
            : fullPath;

        if (enable) {
          final disabledFile = File(disabledPath);
          if (await disabledFile.exists()) {
            await disabledFile.rename(normalPath);
          }
        } else {
          final dllFile = File(normalPath);
          if (await dllFile.exists()) {
            await dllFile.rename(disabledPath);
          }
        }
      }
    }
  }
}
