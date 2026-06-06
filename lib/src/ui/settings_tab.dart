import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:overlayer_ui_flutter/overlayer_ui_flutter.dart';
import '../core/installer_state.dart';
import '../core/update_checker.dart';

class SettingsTab extends StatefulWidget {
  final InstallerState state;
  const SettingsTab({super.key, required this.state});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  final TextEditingController _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _urlController.text = widget.state.apiUrl;
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickDirectory() async {
    final String? result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: widget.state.t(
        'settings_game_path_title_${widget.state.game.id}',
      ),
    );
    if (result != null) {
      await widget.state.setGamePath(result);
    }
  }

  Future<void> _detectPath() async {
    ScaffoldMessenger.of(context).clearSnackBars();
    final detectedPath = widget.state.game.findSteamInstallPath();
    if (detectedPath != null) {
      await widget.state.setGamePath(detectedPath);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.state.t('settings_path_detected_${widget.state.game.id}'),
          ),
          duration: Duration(milliseconds: 2100),
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.state.t('settings_path_not_found_${widget.state.game.id}'),
          ),
          backgroundColor: Colors.redAccent,
          duration: Duration(milliseconds: 2100),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Text(
            widget.state.t('settings_title'),
            style: const TextStyle(
              fontSize: 22.0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 24.0),

          // Game Path Card
          _buildCard(
            title: widget.state.t('settings_game_path_title_${widget.state.game.id}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16151D),
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(
                      color: widget.state.isValidPath
                          ? const Color(0xFF626696).withValues(alpha: 0.3)
                          : Colors.redAccent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        widget.state.isValidPath ? Icons.folder : Icons.folder_off,
                        color: widget.state.isValidPath ? const Color(0xFF919AFF) : Colors.redAccent,
                      ),
                      const SizedBox(width: 12.0),
                      Expanded(
                        child: Text(
                          widget.state.gamePath.isEmpty
                              ? widget.state.t('settings_path_empty')
                              : widget.state.gamePath,
                          style: TextStyle(
                            color: widget.state.gamePath.isEmpty
                                ? Colors.white54
                                : Colors.white70,
                            fontFamily: 'SUIT',
                            fontSize: 14.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!widget.state.isValidPath && widget.state.gamePath.isNotEmpty) ...[
                  const SizedBox(height: 8.0),
                  Text(
                    widget.state.t('settings_path_invalid_${widget.state.game.id}'),
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12.0),
                  ),
                ],
                const SizedBox(height: 16.0),
                Row(
                  children: [
                    Expanded(
                      child: UIButton(
                        label: widget.state.t('settings_btn_select_manually'),
                        fontSize: 14.0,
                        onClick: _pickDirectory,
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: UIButton(
                        label: widget.state.t('settings_btn_auto_detect'),
                        fontSize: 14.0,
                        onClick: _detectPath,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24.0),

          // API Server URL Card
          _buildCard(
            title: widget.state.t('settings_api_title'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _urlController,
                        style: const TextStyle(color: Colors.white, fontSize: 14.0),
                        decoration: InputDecoration(
                          hintText: 'https://modlist.org',
                          hintStyle: const TextStyle(color: Colors.white24),
                          filled: true,
                          fillColor: const Color(0xFF16151D),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: const BorderSide(color: Color(0xFF919AFF)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    SizedBox(
                      width: 120,
                      child: UIButton(
                        label: widget.state.t('settings_btn_save'),
                        fontSize: 14.0,
                        onClick: () async {
                          final url = _urlController.text.trim();
                          if (url.isNotEmpty) {
                            final messenger = ScaffoldMessenger.of(context);
                            await widget.state.setApiUrl(url);
                            messenger.showSnackBar(
                              SnackBar(content: Text(widget.state.t('settings_api_saved'))),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                Text(
                  widget.state.t('settings_api_guide'),
                  style: const TextStyle(color: Colors.white30, fontSize: 12.0),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24.0),

          // Language Card (New)
          _buildCard(
            title: widget.state.t('settings_lang_title'),
            child: SizedBox(
              height: 42,
              child: UIDropdown<String>(
                modelValue: widget.state.locale,
                defaultValue: 'en-US',
                values: const ['en-US', 'ko-KR', 'zh-CN'],
                display: (val) {
                  if (val == 'en-US') return 'English (en-US)';
                  if (val == 'ko-KR') return '한국어 (ko-KR)';
                  if (val == 'zh-CN') return '简体中文 (zh-CN)';
                  return val;
                },
                fontSize: 14.0,
                disableReset: true,
                onChanged: (val) async {
                  await widget.state.setLocale(val);
                },
              ),
            ),
          ),
          const SizedBox(height: 24.0),

          // System Info Card
          _buildCard(
            title: widget.state.t('settings_sys_title'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInfoRow(widget.state.t('settings_sys_os'), Platform.operatingSystem.toUpperCase()),
                _buildInfoRow(widget.state.t('settings_sys_ver'), 'v${UpdateChecker.currentVersion} (Beta)'),
                _buildInfoRow(widget.state.t('settings_sys_loader'), 'MelonLoader (Mono/IL2CPP)'),
                const SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: () {
                    UpdateChecker.check(context, widget.state, showNoUpdate: true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF919AFF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: Text(widget.state.t('settings_btn_check_updates')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1C28),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.04),
          width: 1.0,
        ),
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.w600,
              color: Color(0xFF919AFF),
            ),
          ),
          const SizedBox(height: 16.0),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 14.0)),
          Text(value, style: const TextStyle(color: Colors.white70, fontSize: 14.0, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
