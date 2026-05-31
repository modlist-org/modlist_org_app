import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'installer_state.dart';

class UpdateChecker {
  static const String currentVersion = '0.1.5';
  static const String repoOwner = 'modlist-org';
  static const String repoName = 'modlist_org_app';

  static Future<void> check(
    BuildContext context,
    InstallerState state, {
    bool showNoUpdate = false,
  }) async {
    try {
      final url = Uri.parse(
        'https://api.github.com/repos/$repoOwner/$repoName/releases/latest',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return;

      final data = json.decode(response.body);
      final latestVersion = data['tag_name'] as String? ?? '';
      if (latestVersion.isEmpty) return;

      if (_isNewerVersion(currentVersion, latestVersion)) {
        if (!context.mounted) return;
        _showUpdateDialog(
          context,
          state,
          latestVersion,
          data['html_url'] as String? ?? '',
        );
      } else if (showNoUpdate) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.t('update_status_latest'))),
        );
      }
    } catch (_) {
      if (showNoUpdate && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(state.t('update_status_error'))));
      }
    }
  }

  static bool _isNewerVersion(String current, String latest) {
    final cleanCurrent = current.replaceAll(RegExp(r'[^\d.]'), '');
    final cleanLatest = latest.replaceAll(RegExp(r'[^\d.]'), '');

    final currentParts = cleanCurrent.split('.').map(int.tryParse).toList();
    final latestParts = cleanLatest.split('.').map(int.tryParse).toList();

    final maxLength = currentParts.length > latestParts.length
        ? currentParts.length
        : latestParts.length;
    for (int i = 0; i < maxLength; i++) {
      final currentVal = i < currentParts.length ? (currentParts[i] ?? 0) : 0;
      final latestVal = i < latestParts.length ? (latestParts[i] ?? 0) : 0;
      if (latestVal > currentVal) return true;
      if (currentVal > latestVal) return false;
    }
    return false;
  }

  static void _showUpdateDialog(
    BuildContext context,
    InstallerState state,
    String latestVersion,
    String releaseUrl,
  ) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: const Color(0xFF1E1C28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Container(
            width: 450.0,
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  state.t('update_dialog_title'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16.0),
                Text(
                  state.t(
                    'update_dialog_body',
                    args: {
                      'version': latestVersion,
                      'currentVersion': currentVersion,
                    },
                  ),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14.0,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: Text(
                        state.t('update_dialog_btn_no'),
                        style: const TextStyle(color: Colors.white54),
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        _launchUrl(releaseUrl);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF919AFF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: Text(state.t('update_dialog_btn_yes')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<void> _launchUrl(String url) async {
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
