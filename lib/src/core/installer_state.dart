import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import 'game.dart';
import 'adofai_game.dart';
import 'dancing_line_game.dart';
import 'rhythm_doctor_game.dart';
import 'localization.dart';
import 'version_utils.dart';
import 'app_errors.dart';
import 'debug_log.dart';
import 'protocol_helper.dart';
import '../models/mod_model.dart';
import '../services/api_service.dart';
import '../services/cloud_save_service.dart';

class InstallerState extends ChangeNotifier {
  Game _game = AdofaiGame();
  Game get game => _game;

  final List<Game> supportedGames = [
    AdofaiGame(),
    DancingLineGame(),
    RhythmDoctorGame(),
  ];

  final ApiService apiService = ApiService();

  String _gamePath = '';
  String _apiUrl = 'https://modlist.org';
  bool _isLoaderInstalled = false;
  bool _isValidPath = false;
  List<InstalledMod> _installedMods = [];
  
  bool _isUmmDetected = false;
  String _loaderVersion = 'None';
  bool _isLoaderOutdated = false;
  
  String _locale = 'en-US';
  
  double _progress = 0.0;
  bool _isProcessing = false;
  String? _statusMessage;

  // Mod Update Cache & Status
  final Map<String, ModItem> _onlineModsCache = {};
  List<String> _modsWithUpdates = [];
  bool _isCheckingModUpdates = false;

  String? _integrationToken;
  String? get integrationToken => _integrationToken;

  List<dynamic> _cloudSaves = [];
  List<dynamic> get cloudSaves => _cloudSaves;

  List<dynamic> _myPresets = [];
  List<dynamic> get myPresets => _myPresets;

  int _cloudUsedBytes = 0;
  int get cloudUsedBytes => _cloudUsedBytes;

  int _cloudMaxBytes = 10 * 1024 * 1024 * 1024; // 10 GB
  int get cloudMaxBytes => _cloudMaxBytes;

  String get gamePath => _gamePath;
  String get apiUrl => _apiUrl;
  bool get isLoaderInstalled => _isLoaderInstalled;
  bool get isValidPath => _isValidPath;
  List<InstalledMod> get installedMods => _installedMods;
  
  bool get isUmmDetected => _isUmmDetected;
  String get loaderVersion => _loaderVersion;
  bool get isLoaderOutdated => _isLoaderOutdated;
  
  String get locale => _locale;
  
  double get progress => _progress;
  bool get isProcessing => _isProcessing;
  String? get statusMessage => _statusMessage;

  Map<String, ModItem> get onlineModsCache => _onlineModsCache;
  List<String> get modsWithUpdates => _modsWithUpdates;
  bool get isCheckingModUpdates => _isCheckingModUpdates;

  InstallerState() {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();

    // Register protocol handler for Windows/Linux
    await ProtocolHelper.register();
    
    // 언어 설정 로드
    _locale = prefs.getString('modlist_app_locale') ?? 'en-US';
    
    // API URL 로드
    _apiUrl = prefs.getString('modlist_api_base_url') ?? 'https://modlist.org';
    await apiService.setBaseUrl(_apiUrl);

    // 저장된 게임 고유 식별자 로드
    final selectedGameId = prefs.getString('modlist_selected_game_id') ?? 'adofai';
    _game = supportedGames.firstWhere((g) => g.id == selectedGameId, orElse: () => AdofaiGame());

    // 저장된 게임 경로 로드, 없으면 기본 경로 자동 감지 시도
    _gamePath = prefs.getString('${_game.id}_install_path') ?? '';
    if (_gamePath.isEmpty) {
      final detectedPath = _game.findSteamInstallPath();
      if (detectedPath != null) {
        _gamePath = detectedPath;
        await prefs.setString('${_game.id}_install_path', _gamePath);
      }
    }

    // Load integration token
    _integrationToken = prefs.getString('modlist_integration_token');
    if (_integrationToken != null && _integrationToken!.isNotEmpty) {
      await apiService.setIntegrationToken(_integrationToken!);
      // Refresh cloud saves and presets in background
      refreshCloudSaves();
      refreshMyPresets();
    }

    await refreshStatus();
  }

  // 선택된 게임 변경
  Future<void> setSelectedGame(String gameId) async {
    if (_game.id == gameId) return;

    final target = supportedGames.firstWhere((g) => g.id == gameId, orElse: () => _game);
    if (target == _game) return;

    _game = target;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('modlist_selected_game_id', gameId);

    // 경로 로드
    _gamePath = prefs.getString('${_game.id}_install_path') ?? '';
    if (_gamePath.isEmpty) {
      final detectedPath = _game.findSteamInstallPath();
      if (detectedPath != null) {
        _gamePath = detectedPath;
        await prefs.setString('${_game.id}_install_path', _gamePath);
      }
    }

    _onlineModsCache.clear();
    _modsWithUpdates = [];

    await refreshStatus();
  }

  // 게임 경로 변경 및 저장
  Future<void> setGamePath(String path) async {
    _gamePath = path;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_game.id}_install_path', path);
    await refreshStatus();
  }

  // API URL 변경 및 저장
  Future<void> setApiUrl(String url) async {
    _apiUrl = url;
    await apiService.setBaseUrl(url);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('modlist_api_base_url', url);
    notifyListeners();
  }

  // 상태 갱신
  Future<void> refreshStatus() async {
    _isValidPath = game.isValidGamePath(_gamePath);
    if (_isValidPath) {
      _isLoaderInstalled = game.isLoaderInstalled(_gamePath);
      _installedMods = await game.getInstalledMods(_gamePath);
      
      // UMM(Unity Mod Manager) 전용 감지
      _isUmmDetected = !_isLoaderInstalled && game.isUmmDetected(_gamePath);
      
      if (_isLoaderInstalled) {
        _loaderVersion = game.getLoaderVersion(_gamePath);
        // 버전이 0.7.3이 아니면 구버전으로 판정
        _isLoaderOutdated = _loaderVersion == 'Unknown (Outdated)' || 
                            (_loaderVersion != 'None' && _loaderVersion != '0.7.3');
      } else {
        _loaderVersion = 'None';
        _isLoaderOutdated = false;
      }

      // 디스크 파일 정보와 동기화된 메타데이터를 로컬 파일에 백업
      if (_installedMods.isNotEmpty) {
        await game.saveInstalledMods(_gamePath, _installedMods);
      }
    } else {
      _isLoaderInstalled = false;
      _installedMods = [];
      _isUmmDetected = false;
      _loaderVersion = 'None';
      _isLoaderOutdated = false;
    }
    notifyListeners();

    if (_isValidPath && _installedMods.isNotEmpty) {
      checkModUpdates();
    } else {
      _modsWithUpdates = [];
      notifyListeners();
    }
  }

  // 백그라운드 모드 업데이트 확인
  Future<void> checkModUpdates() async {
    if (_isCheckingModUpdates) return;
    _isCheckingModUpdates = true;
    notifyListeners();

    try {
      final localMods = _installedMods;
      if (localMods.isEmpty) {
        _modsWithUpdates = [];
        _isCheckingModUpdates = false;
        notifyListeners();
        return;
      }

      // 캐시에 없는 모드들만 조회
      final slugsToFetch = localMods
          .map((m) => m.slug)
          .where((slug) => !_onlineModsCache.containsKey(slug))
          .toList();

      if (slugsToFetch.isNotEmpty) {
        final futures = slugsToFetch.map((slug) async {
          try {
            // UMM 모드 접두사 'umm-'가 있으면 제거하여 온라인 API 조회 시 호환성 확보
            final cleanSlug = slug.startsWith('umm-') ? slug.substring(4) : slug;
            try {
              final result = await apiService.fetchModDetails(cleanSlug);
              return {'localSlug': slug, 'data': result};
            } catch (e) {
              // 상세 조회 실패 시, 검색 API를 통해 매칭 시도 (예: UMM ID 'Tweaks' -> 'adofai-tweaks')
              final searchResult = await apiService.fetchMods(
                game: _game.id,
                search: cleanSlug,
              );
              final List<ModItem> searchMods = searchResult['mods'] as List<ModItem>;
              for (final searchMod in searchMods) {
                if (_game.isModMatched(slug, searchMod.slug)) {
                  final detailResult = await apiService.fetchModDetails(searchMod.slug);
                  return {'localSlug': slug, 'data': detailResult};
                }
              }
              rethrow;
            }
          } catch (_) {
            return null;
          }
        });

        final results = await Future.wait(futures);

        for (var result in results) {
          if (result != null) {
            final localSlug = result['localSlug'] as String;
            final data = result['data'] as Map<String, dynamic>;
            final mod = data['mod'] as ModItem;
            _onlineModsCache[localSlug] = mod;
          }
        }
      }

      // 업데이트 가능한 모드 체크 (설치 버전이 최신 버전보다 낮은 경우)
      final List<String> updatedSlugs = [];
      for (final localMod in localMods) {
        final onlineMod = _onlineModsCache[localMod.slug];
        if (onlineMod != null && onlineMod.latestVersion != null) {
          if (VersionUtils.isNewerVersion(localMod.version, onlineMod.latestVersion!.version)) {
            updatedSlugs.add(localMod.slug);
          }
        }
      }

      _modsWithUpdates = updatedSlugs;
    } catch (_) {
      // 온라인 조회 실패 시 무시
    } finally {
      _isCheckingModUpdates = false;
      notifyListeners();
    }
  }

  void _setLoaderInstallPhase(LoaderInstallPhase phase) {
    switch (phase) {
      case LoaderInstallPhase.extracting:
        _progress = 0.90;
        _statusMessage = t('status_loader_extracting');
        break;
      case LoaderInstallPhase.configuring:
        _progress = 0.95;
        _statusMessage = t('status_loader_configuring');
        break;
      case LoaderInstallPhase.finalizing:
        _progress = 0.98;
        _statusMessage = t('status_loader_finalizing');
        break;
    }
    notifyListeners();
  }

  // MelonLoader 설치
  Future<void> installMelonLoader({bool installUmmCompat = false}) async {
    if (_isProcessing || !_isValidPath) {
      await DebugLog.info(
        'Install MelonLoader ignored: processing=$_isProcessing '
        'validPath=$_isValidPath path=$_gamePath',
      );
      return;
    }
    
    _isProcessing = true;
    _progress = 0.0;
    _statusMessage = t('status_loader_downloading');
    notifyListeners();

    var installTimedOut = false;

    try {
      await DebugLog.info(
        'Install MelonLoader start: game=${game.id} path=$_gamePath '
        'ummDetected=$_isUmmDetected installUmmCompat=$installUmmCompat '
        'logFile=${DebugLog.filePath ?? 'disabled'}',
      );

      if (_isUmmDetected) {
        await DebugLog.info('Moving UMM mods before MelonLoader install');
        _statusMessage = t('status_loader_migrating_umm');
        notifyListeners();
        await _moveUmmModsToUmmModsFolder();
        await DebugLog.info('Finished moving UMM mods');
      }

      await game.installLoader(
        _gamePath,
        onProgress: (val) {
          if (installTimedOut || !_isProcessing) return;
          final downloadProgress = val.clamp(0.0, 1.0).toDouble();
          _progress = downloadProgress * 0.85;
          _statusMessage = t(
            'status_loader_installing',
            args: {
              'progress': (downloadProgress * 100).toStringAsFixed(1),
            },
          );
          notifyListeners();
        },
        onPhase: (phase) {
          if (installTimedOut || !_isProcessing) return;
          _setLoaderInstallPhase(phase);
        },
      ).timeout(
        const Duration(minutes: 3),
        onTimeout: () {
          installTimedOut = true;
          throw TimeoutException('MelonLoader install timed out after 3 minutes');
        },
      );
      await DebugLog.info('Core MelonLoader install completed');

      if (_isUmmDetected && installUmmCompat) {
        _statusMessage = t('status_loader_checking_ummcompat');
        notifyListeners();
        try {
          await DebugLog.info('Fetching UMM compatibility mod');
          final result = await apiService.fetchModDetails('ummcompat');
          final mod = result['mod'] as ModItem;
          
          await _installModInternal(mod);
          _statusMessage = t('status_loader_install_success_with_ummcompat');
          await DebugLog.info('UMM compatibility mod installed');
        } catch (e, stackTrace) {
          await DebugLog.error(
            'UMM compatibility mod install failed',
            error: e,
            stackTrace: stackTrace,
          );
          _statusMessage = t('status_loader_install_success_fail_ummcompat', args: {'error': describeAppError(e)});
        }
      } else {
        _statusMessage = t('status_loader_install_success');
      }
      await DebugLog.info('Install MelonLoader success');
    } catch (e, stackTrace) {
      await DebugLog.error(
        'Install MelonLoader failed',
        error: e,
        stackTrace: stackTrace,
      );
      _statusMessage = t('status_loader_install_failed', args: {'error': describeAppError(e)});
    } finally {
      _isProcessing = false;
      await DebugLog.info('Refreshing status after MelonLoader install');
      await refreshStatus();
      await DebugLog.info(
        'Install MelonLoader finished: installed=$_isLoaderInstalled '
        'loaderVersion=$_loaderVersion status=$_statusMessage',
      );
    }
  }

  // UMM 호환 모드(ummcompat) 설치
  Future<void> installUmmCompat() async {
    if (_isProcessing || !_isValidPath) return;

    _isProcessing = true;
    _progress = 0.0;
    _statusMessage = t('status_ummcompat_checking');
    notifyListeners();

    try {
      final result = await apiService.fetchModDetails('ummcompat');
      final mod = result['mod'] as ModItem;
      await _installModInternal(mod);
      _statusMessage = t('status_ummcompat_success');
    } catch (e) {
      _statusMessage = t('status_ummcompat_failed', args: {'error': describeAppError(e)});
    } finally {
      _isProcessing = false;
      await refreshStatus();
    }
  }

  // UMM Mods 폴더를 UMMMods 폴더로 이동
  Future<void> _moveUmmModsToUmmModsFolder() async {
    final modsDir = Directory(p.join(_gamePath, 'Mods'));
    if (!modsDir.existsSync()) return;

    final ummModsDir = Directory(p.join(_gamePath, 'UMMMods'));
    if (!ummModsDir.existsSync()) {
      try {
        await modsDir.rename(ummModsDir.path);
      } catch (_) {
        await _copyAndRemoveDirectory(modsDir, ummModsDir);
      }
    } else {
      try {
        final entities = modsDir.listSync();
        for (final entity in entities) {
          final name = p.basename(entity.path);
          final newPath = p.join(ummModsDir.path, name);
          if (entity is Directory) {
            final targetDir = Directory(newPath);
            if (targetDir.existsSync()) {
              await targetDir.delete(recursive: true);
            }
            await entity.rename(newPath);
          } else if (entity is File) {
            final targetFile = File(newPath);
            if (targetFile.existsSync()) {
              await targetFile.delete();
            }
            await entity.rename(newPath);
          }
        }
        await modsDir.delete(recursive: true);
      } catch (_) {
        await _copyAndRemoveDirectory(modsDir, ummModsDir);
      }
    }
  }

  // 디렉토리 복사 및 원본 삭제 헬퍼
  Future<void> _copyAndRemoveDirectory(Directory source, Directory destination) async {
    if (!destination.existsSync()) {
      await destination.create(recursive: true);
    }
    await for (final entity in source.list(recursive: false)) {
      final name = p.basename(entity.path);
      final newPath = p.join(destination.path, name);
      if (entity is Directory) {
        await _copyAndRemoveDirectory(entity, Directory(newPath));
      } else if (entity is File) {
        await entity.copy(newPath);
      }
    }
    await source.delete(recursive: true);
  }

  // MelonLoader 제거
  Future<void> uninstallMelonLoader() async {
    if (_isProcessing || !_isValidPath) return;
    
    _isProcessing = true;
    _statusMessage = t('status_loader_uninstalling');
    notifyListeners();

    try {
      await game.uninstallLoader(_gamePath);
      _statusMessage = t('status_loader_uninstall_success');
    } catch (e) {
      _statusMessage = t('status_loader_uninstall_failed', args: {'error': describeAppError(e)});
    } finally {
      _isProcessing = false;
      await refreshStatus();
    }
  }

  // 내부 모드 설치 헬퍼 (진행 상태가 이미 처리 중인 내부 호출용)
  Future<void> _installModInternal(ModItem mod, {String? version, bool isBeta = false}) async {
    final targetVersion = version ?? mod.latestVersion?.version ?? '';
    final redirectUrl = await apiService.getDownloadUrl(
      mod.slug,
      version: targetVersion.isNotEmpty ? targetVersion : null,
      isBeta: isBeta,
    );

    _statusMessage = t('status_mod_downloading', args: {'name': mod.name});
    notifyListeners();

    await game.installMod(
      _gamePath,
      mod,
      redirectUrl,
      version: targetVersion,
      isBeta: isBeta,
      onProgress: (val) {
        _progress = val;
        _statusMessage = t('status_mod_downloading_progress', args: {'name': mod.name, 'progress': (val * 100).toStringAsFixed(1)});
        notifyListeners();
      },
    );
  }

  Future<void> _installModWithDependencies(ModItem mod, {String? version, bool isBeta = false, Set<String>? visited}) async {
    visited ??= {};
    if (visited.contains(mod.slug)) return;
    visited.add(mod.slug);

    if (mod.dependencySlugs.isNotEmpty) {
      for (final depSlug in mod.dependencySlugs) {
        final bool isInstalled = _installedMods.any((m) {
          final cleanInstalled = m.slug.startsWith('umm-') ? m.slug.substring(4) : m.slug;
          final cleanDep = depSlug.startsWith('umm-') ? depSlug.substring(4) : depSlug;
          return cleanInstalled == cleanDep || game.isModMatched(m.slug, depSlug);
        });

        if (!isInstalled) {
          _statusMessage = t('status_mod_resolving_dependency', args: {'dependency': depSlug});
          notifyListeners();

          try {
            final result = await apiService.fetchModDetails(depSlug);
            final depMod = result['mod'] as ModItem;
            await _installModWithDependencies(depMod, visited: visited);
          } catch (e) {
            await DebugLog.error('Failed to install dependency: $depSlug', error: e);
            throw Exception('Failed to install dependency $depSlug: $e');
          }
        }
      }
    }

    await _installModInternal(mod, version: version, isBeta: isBeta);
  }

  // 모드 설치
  Future<void> installMod(ModItem mod, {String? version, bool isBeta = false}) async {
    if (_isProcessing || !_isValidPath) return;

    _isProcessing = true;
    _progress = 0.0;
    _statusMessage = t('status_mod_preparing', args: {'name': mod.name});
    notifyListeners();

    try {
      await _installModWithDependencies(mod, version: version, isBeta: isBeta);
      _statusMessage = t('status_mod_install_success', args: {'name': mod.name});
    } catch (e) {
      _statusMessage = t('status_mod_install_failed', args: {'name': mod.name, 'error': describeAppError(e)});
    } finally {
      _isProcessing = false;
      await refreshStatus();
    }
  }

  // 파일에서 모드 설치
  Future<void> installModFromFile(String filePath) async {
    if (_isProcessing || !_isValidPath) return;

    _isProcessing = true;
    _progress = 0.0;
    _statusMessage = t('status_mod_local_installing');
    notifyListeners();

    try {
      await game.installModFromFile(_gamePath, filePath);
      _statusMessage = t('status_mod_local_install_success');
    } catch (e) {
      _statusMessage = t('status_mod_local_install_failed', args: {'error': describeAppError(e)});
    } finally {
      _isProcessing = false;
      await refreshStatus();
    }
  }

  // 모드 삭제
  Future<void> uninstallMod(String slug, String name) async {
    if (_isProcessing || !_isValidPath) return;

    _isProcessing = true;
    _statusMessage = t('status_mod_deleting', args: {'name': name});
    notifyListeners();

    try {
      await game.uninstallMod(_gamePath, slug);
      _statusMessage = t('status_mod_delete_success', args: {'name': name});
    } catch (e) {
      _statusMessage = t('status_mod_delete_failed', args: {'name': name, 'error': describeAppError(e)});
    } finally {
      _isProcessing = false;
      await refreshStatus();
    }
  }

  // 모드 활성화 / 비활성화 토글
  Future<void> toggleModActive(InstalledMod mod, bool enable) async {
    if (_isProcessing || !_isValidPath) return;

    _isProcessing = true;
    _progress = 0.0;
    _statusMessage = enable 
        ? t('status_mod_enabling', args: {'name': mod.name}) 
        : t('status_mod_disabling', args: {'name': mod.name});
    notifyListeners();

    try {
      await game.toggleModActive(_gamePath, mod, enable);

      final updatedMod = InstalledMod(
        id: mod.id,
        slug: mod.slug,
        name: mod.name,
        version: mod.version,
        isBeta: mod.isBeta,
        installedAt: mod.installedAt,
        installedFiles: mod.installedFiles,
        isEnabled: enable,
      );

      final index = _installedMods.indexWhere((m) => m.id == mod.id);
      if (index != -1) {
        _installedMods[index] = updatedMod;
      }

      await game.saveInstalledMods(_gamePath, _installedMods);

      _statusMessage = enable 
          ? t('status_mod_enable_success', args: {'name': mod.name}) 
          : t('status_mod_disable_success', args: {'name': mod.name});
    } catch (e) {
      _statusMessage = t('status_mod_toggle_failed', args: {'name': mod.name, 'error': describeAppError(e)});
    } finally {
      _isProcessing = false;
      await refreshStatus();
    }
  }

  // 알림 메시지 클리어
  void clearStatusMessage() {
    _statusMessage = null;
    notifyListeners();
  }

  // 번역 헬퍼
  String t(String key, {Map<String, String>? args}) {
    return Localization.get(_locale, key, args: args);
  }

  // locale 변경 및 저장
  Future<void> setLocale(String lang) async {
    if (lang != 'ko-KR' && lang != 'en-US' && lang != 'zh-CN') return;
    _locale = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('modlist_app_locale', lang);
    notifyListeners();
  }

  Future<void> setIntegrationToken(String token) async {
    _integrationToken = token.trim();
    final prefs = await SharedPreferences.getInstance();
    if (_integrationToken!.isEmpty) {
      await prefs.remove('modlist_integration_token');
      await apiService.setIntegrationToken('');
      _cloudSaves = [];
      _myPresets = [];
      _cloudUsedBytes = 0;
    } else {
      await prefs.setString('modlist_integration_token', _integrationToken!);
      await apiService.setIntegrationToken(_integrationToken!);
      await refreshCloudSaves();
      await refreshMyPresets();
    }
    notifyListeners();
  }

  Future<void> refreshCloudSaves() async {
    if (_integrationToken == null || _integrationToken!.isEmpty) return;
    try {
      final res = await apiService.fetchSavingStatus();
      if (res['success'] == true) {
        _cloudSaves = res['files'] ?? [];
        _cloudUsedBytes = res['usedBytes'] ?? 0;
        _cloudMaxBytes = res['maxBytes'] ?? (10 * 1024 * 1024 * 1024);
      }
    } catch (e) {
      debugPrint('Failed to refresh cloud saves: $e');
    }
    notifyListeners();
  }

  Future<void> refreshMyPresets() async {
    if (_integrationToken == null || _integrationToken!.isEmpty) return;
    try {
      final res = await apiService.fetchMyPresets();
      if (res['success'] == true) {
        _myPresets = res['presets'] ?? [];
      }
    } catch (e) {
      debugPrint('Failed to refresh my presets: $e');
    }
    notifyListeners();
  }

  Future<void> deletePreset(String presetId) async {
    if (_integrationToken == null || _integrationToken!.isEmpty) return;
    try {
      final res = await apiService.deletePreset(presetId);
      if (res['success'] == true) {
        _myPresets = _myPresets.where((p) => p['id'] != presetId).toList();
        await refreshCloudSaves();
      }
    } catch (e) {
      debugPrint('Failed to delete preset: $e');
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<void> backupCloudSave() async {
    if (_isProcessing || !_isValidPath) return;

    _isProcessing = true;
    _progress = 0.0;
    _statusMessage = t('status_cloud_backup_start');
    notifyListeners();

    try {
      final List<String> installedModFiles = [];
      for (final mod in _installedMods) {
        installedModFiles.addAll(mod.installedFiles);
      }

      final res = await CloudSaveService.backup(
        gameId: game.id,
        gamePath: _gamePath,
        apiService: apiService,
        installedModFiles: installedModFiles,
        onProgress: (val) {
          _progress = val;
          _statusMessage = t('status_cloud_backup_progress', args: {
            'progress': (val * 100).toStringAsFixed(0)
          });
          notifyListeners();
        },
      );
      _statusMessage = t('status_cloud_backup_success');
      if (res['usedBytes'] != null) {
        _cloudUsedBytes = res['usedBytes'];
      }
    } catch (e) {
      _statusMessage = t('status_cloud_backup_failed', args: {'error': e.toString()});
      rethrow;
    } finally {
      _isProcessing = false;
      await refreshCloudSaves();
    }
  }

  Future<void> restoreCloudSave(String fileKey) async {
    if (_isProcessing || !_isValidPath) return;

    _isProcessing = true;
    _progress = 0.0;
    _statusMessage = t('status_cloud_restore_start');
    notifyListeners();

    try {
      await CloudSaveService.restore(
        gamePath: _gamePath,
        fileKey: fileKey,
        apiService: apiService,
        onProgress: (val) {
          _progress = val;
          _statusMessage = t('status_cloud_restore_progress', args: {
            'progress': (val * 100).toStringAsFixed(0)
          });
          notifyListeners();
        },
      );
      _statusMessage = t('status_cloud_restore_success');
    } catch (e) {
      _statusMessage = t('status_cloud_restore_failed', args: {'error': e.toString()});
      rethrow;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<void> deleteCloudSave(String fileKey) async {
    if (_isProcessing) return;

    _isProcessing = true;
    _statusMessage = t('status_cloud_delete_start');
    notifyListeners();

    try {
      await apiService.deleteCloudSave(fileKey);
      _statusMessage = t('status_cloud_delete_success');
    } catch (e) {
      _statusMessage = t('status_cloud_delete_failed', args: {'error': e.toString()});
      rethrow;
    } finally {
      _isProcessing = false;
      await refreshCloudSaves();
      await refreshMyPresets();
    }
  }
}
