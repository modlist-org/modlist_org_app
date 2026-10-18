import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'background_service.dart';
import 'version_utils.dart';

class UpdateCheckResult {
  final String latestVersion;
  final String releaseUrl;
  final bool hasUpdate;
  /// 이 설치 형태에서 자체 업데이트할 수 있는 릴리스 파일 (없으면 릴리스 페이지로 안내)
  final Map? selfUpdateAsset;

  const UpdateCheckResult({
    required this.latestVersion,
    required this.releaseUrl,
    required this.hasUpdate,
    this.selfUpdateAsset,
  });
}

class UpdateChecker {
  static const String currentVersion = '0.8.3';
  static const String repoOwner = 'modlist-org';
  static const String repoName = 'modlist_org_app';

  /// Fetches the latest GitHub release.
  /// Returns null when the release info is unavailable (non-200 response or
  /// missing tag); throws on network/parse errors.
  static Future<UpdateCheckResult?> fetchLatest() async {
    final url = Uri.parse(
      'https://api.github.com/repos/$repoOwner/$repoName/releases/latest',
    );
    final response = await http.get(url).timeout(const Duration(seconds: 5));
    if (response.statusCode != 200) return null;

    final data = json.decode(response.body);
    final latestVersion = data['tag_name'] as String? ?? '';
    if (latestVersion.isEmpty) return null;

    return UpdateCheckResult(
      latestVersion: latestVersion,
      releaseUrl: data['html_url'] as String? ?? '',
      hasUpdate: VersionUtils.isNewerVersion(currentVersion, latestVersion),
      selfUpdateAsset: _pickAsset(data['assets'] as List? ?? const []),
    );
  }

  // 자체 업데이트 가능한 설치 형태만 asset 반환, 나머지(zip/dmg/deb/rpm)는 null
  static Map? _pickAsset(List assets) {
    String? suffix;
    if (Platform.isWindows &&
        File(p.join(File(Platform.resolvedExecutable).parent.path, 'unins000.exe')).existsSync()) {
      suffix = '.exe';
    } else if (Platform.isLinux && Platform.environment['APPIMAGE'] != null) {
      suffix = '.appimage';
    }
    if (suffix == null) return null;
    for (final a in assets) {
      if (a is Map && (a['name'] as String? ?? '').toLowerCase().endsWith(suffix)) return a;
    }
    return null;
  }

  /// 새 버전을 받아 설치하고 앱을 재시작 (성공하면 반환하지 않음, 실패 시 throw)
  static Future<void> selfUpdate(Map asset) async {
    final response = await http.get(Uri.parse(asset['browser_download_url'] as String));
    if (response.statusCode != 200) throw HttpException('HTTP ${response.statusCode}');

    final tempDir = await getTemporaryDirectory();
    final file = File(p.join(tempDir.path, asset['name'] as String));
    await file.writeAsBytes(response.bodyBytes, flush: true);

    // 재실행된 새 인스턴스가 기존 인스턴스로 전달되고 꺼지는 것 방지
    await BackgroundService.instance.releaseInstanceLock();
    if (Platform.isWindows) {
      // 앱 종료 후 Inno Setup 설치본을 조용히 실행하고, 끝나면 앱 재실행 (cmd 인자 따옴표 문제 피하려고 .bat 사용)
      final bat = File(p.join(tempDir.path, 'modlist_update.bat'));
      await bat.writeAsString(
        '@echo off\r\n'
        'timeout /t 2 /nobreak >nul\r\n'
        '"${file.path}" /VERYSILENT /SUPPRESSMSGBOXES /NORESTART\r\n'
        'start "" "${Platform.resolvedExecutable}"\r\n',
      );
      await Process.start('cmd', ['/c', bat.path], mode: ProcessStartMode.detached);
    } else {
      final appImage = Platform.environment['APPIMAGE']!;
      // 임시 폴더가 다른 파일시스템일 수 있으므로 같은 폴더에 복사한 뒤 rename으로 교체
      final staged = '$appImage.new';
      await file.copy(staged);
      await Process.run('chmod', ['+x', staged]);
      await File(staged).rename(appImage);
      await Process.start(appImage, [], mode: ProcessStartMode.detached);
    }
    exit(0);
  }

  static Future<void> launchUrl(String url) async {
    try {
      if (Platform.isWindows) {
        await Process.run('start', [url], runInShell: true);
      } else if (Platform.isMacOS) {
        await Process.run('open', [url]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [url]);
      }
    } catch (_) {}
  }
}
