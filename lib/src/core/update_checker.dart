import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'version_utils.dart';

class UpdateCheckResult {
  final String latestVersion;
  final String releaseUrl;
  final bool hasUpdate;

  const UpdateCheckResult({
    required this.latestVersion,
    required this.releaseUrl,
    required this.hasUpdate,
  });
}

class UpdateChecker {
  static const String currentVersion = '0.6.0';
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
    );
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
