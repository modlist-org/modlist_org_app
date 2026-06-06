import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/mod_model.dart';
import 'melon_dll_parser.dart';

abstract class Game {
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

  // 모드 로더가 설치되었는지 여부 확인
  bool isLoaderInstalled(String gamePath);

  // 모드 로더 설치
  Future<void> installLoader(
    String gamePath, {
    void Function(double)? onProgress,
  });

  // 모드 로더 제거
  Future<void> uninstallLoader(String gamePath);

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

  // UMM ID(예: Tweaks)와 서버 슬러그(예: adofai-tweaks) 간의 유연한 매칭 지원 헬퍼
  bool isModMatched(String localSlug, String serverSlug) {
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
        final f2d = File(p.join(gamePath, 'Plugins', '$cleanSlug.dll.disabled'));
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
  Future<void> toggleModActive(String gamePath, InstalledMod mod, bool enable) async {
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
