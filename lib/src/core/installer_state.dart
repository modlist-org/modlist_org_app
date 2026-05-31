import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import 'game.dart';
import 'adofai_game.dart';
import 'localization.dart';
import '../models/mod_model.dart';
import '../services/api_service.dart';

class InstallerState extends ChangeNotifier {
  final Game game = AdofaiGame();
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

  InstallerState() {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 언어 설정 로드
    _locale = prefs.getString('modlist_app_locale') ?? 'en-US';
    
    // API URL 로드
    _apiUrl = prefs.getString('modlist_api_base_url') ?? 'https://modlist.org';
    await apiService.setBaseUrl(_apiUrl);

    // 저장된 게임 경로 로드, 없으면 기본 경로 자동 감지 시도
    _gamePath = prefs.getString('adofai_install_path') ?? '';
    if (_gamePath.isEmpty) {
      final defaultPath = game.getPlatformDefaultPath();
      if (game.isValidGamePath(defaultPath)) {
        _gamePath = defaultPath;
        await prefs.setString('adofai_install_path', _gamePath);
      }
    }

    await refreshStatus();
  }

  // 게임 경로 변경 및 저장
  Future<void> setGamePath(String path) async {
    _gamePath = path;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('adofai_install_path', path);
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
    } else {
      _isLoaderInstalled = false;
      _installedMods = [];
      _isUmmDetected = false;
      _loaderVersion = 'None';
      _isLoaderOutdated = false;
    }
    notifyListeners();
  }

  // MelonLoader 설치
  Future<void> installMelonLoader({bool installUmmCompat = false}) async {
    if (_isProcessing || !_isValidPath) return;
    
    _isProcessing = true;
    _progress = 0.0;
    _statusMessage = t('status_loader_downloading');
    notifyListeners();

    try {
      if (_isUmmDetected) {
        _statusMessage = t('status_loader_migrating_umm');
        notifyListeners();
        await _moveUmmModsToUmmModsFolder();
      }

      await game.installLoader(_gamePath, onProgress: (val) {
        _progress = val;
        _statusMessage = t('status_loader_installing', args: {'progress': (val * 100).toStringAsFixed(1)});
        notifyListeners();
      });

      if (_isUmmDetected && installUmmCompat) {
        _statusMessage = t('status_loader_checking_ummcompat');
        notifyListeners();
        try {
          final result = await apiService.fetchModDetails('ummcompat');
          final mod = result['mod'] as ModItem;
          
          await _installModInternal(mod);
          _statusMessage = t('status_loader_install_success_with_ummcompat');
        } catch (e) {
          _statusMessage = t('status_loader_install_success_fail_ummcompat', args: {'error': e.toString()});
        }
      } else {
        _statusMessage = t('status_loader_install_success');
      }
    } catch (e) {
      _statusMessage = t('status_loader_install_failed', args: {'error': e.toString()});
    } finally {
      _isProcessing = false;
      await refreshStatus();
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
      _statusMessage = t('status_ummcompat_failed', args: {'error': e.toString()});
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
      _statusMessage = t('status_loader_uninstall_failed', args: {'error': e.toString()});
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

  // 모드 설치
  Future<void> installMod(ModItem mod, {String? version, bool isBeta = false}) async {
    if (_isProcessing || !_isValidPath) return;

    _isProcessing = true;
    _progress = 0.0;
    _statusMessage = t('status_mod_preparing', args: {'name': mod.name});
    notifyListeners();

    try {
      await _installModInternal(mod, version: version, isBeta: isBeta);
      _statusMessage = t('status_mod_install_success', args: {'name': mod.name});
    } catch (e) {
      _statusMessage = t('status_mod_install_failed', args: {'name': mod.name, 'error': e.toString()});
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
      _statusMessage = t('status_mod_local_install_failed', args: {'error': e.toString()});
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
      _statusMessage = t('status_mod_delete_failed', args: {'name': name, 'error': e.toString()});
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
}
