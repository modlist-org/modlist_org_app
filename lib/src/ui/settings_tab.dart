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
  final TextEditingController _tokenController = TextEditingController();
  bool _obscureToken = true;

  @override
  void initState() {
    super.initState();
    _urlController.text = widget.state.apiUrl;
    _tokenController.text = widget.state.integrationToken ?? '';
  }

  @override
  void dispose() {
    _urlController.dispose();
    _tokenController.dispose();
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

          // App Integration Token Card
          _buildCard(
            title: widget.state.t('settings_token_title'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _tokenController,
                        style: const TextStyle(color: Colors.white, fontSize: 14.0),
                        obscureText: _obscureToken,
                        decoration: InputDecoration(
                          hintText: widget.state.t('settings_token_hint'),
                          hintStyle: const TextStyle(color: Colors.white24),
                          filled: true,
                          fillColor: const Color(0xFF16151D),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureToken ? Icons.visibility : Icons.visibility_off,
                              color: Colors.white38,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureToken = !_obscureToken;
                              });
                            },
                          ),
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
                          final token = _tokenController.text.trim();
                          final messenger = ScaffoldMessenger.of(context);
                          await widget.state.setIntegrationToken(token);
                          messenger.showSnackBar(
                            SnackBar(content: Text(widget.state.t('settings_token_saved'))),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                Text(
                  widget.state.t('settings_token_guide'),
                  style: const TextStyle(color: Colors.white30, fontSize: 12.0),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24.0),

          if (widget.state.integrationToken != null && widget.state.integrationToken!.isNotEmpty) ...[
            _buildCard(
              title: widget.state.t('settings_cloud_title'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.state.t('settings_cloud_desc'),
                    style: const TextStyle(color: Colors.white70, fontSize: 13.0),
                  ),
                  const SizedBox(height: 16.0),
                  
                  // Usage Info
                  _buildStorageUsage(),
                  const SizedBox(height: 20.0),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: UIButton(
                          label: widget.state.t('settings_cloud_btn_backup'),
                          fontSize: 14.0,
                          blocked: widget.state.isProcessing,
                          onClick: () async {
                            await widget.state.backupCloudSave();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20.0),

                  // Backups List
                  const Text(
                    'Cloud Backups',
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  _buildBackupsList(),
                ],
              ),
            ),
            const SizedBox(height: 24.0),
          ],

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

  Widget _buildStorageUsage() {
    final used = widget.state.cloudUsedBytes;
    final maxBytes = widget.state.cloudMaxBytes;
    final ratio = maxBytes > 0 ? (used / maxBytes).clamp(0.0, 1.0) : 0.0;
    
    final usedMb = (used / (1024 * 1024)).toStringAsFixed(1);
    final maxGb = (maxBytes / (1024 * 1024 * 1024)).toStringAsFixed(0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.state.t('settings_cloud_used', args: {
                'used': '$usedMb MB',
                'max': '$maxGb GB',
              }),
              style: const TextStyle(color: Colors.white54, fontSize: 12.0),
            ),
            Text(
              '${(ratio * 100).toStringAsFixed(1)}%',
              style: const TextStyle(color: Color(0xFF919AFF), fontSize: 12.0, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8.0),
        ClipRRect(
          borderRadius: BorderRadius.circular(4.0),
          child: LinearProgressIndicator(
            value: ratio,
            backgroundColor: const Color(0xFF16151D),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF919AFF)),
            minHeight: 8.0,
          ),
        ),
      ],
    );
  }

  Widget _buildBackupsList() {
    final saves = widget.state.cloudSaves.where((s) => s['game'] == widget.state.game.id).toList();
    if (saves.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Text(
          widget.state.t('settings_cloud_no_backup'),
          style: const TextStyle(color: Colors.white30, fontSize: 13.0, fontStyle: FontStyle.italic),
        ),
      );
    }

    return Column(
      children: saves.map<Widget>((save) {
        final fileKey = save['fileKey'] as String;
        final fileSize = save['fileSize'] as int? ?? 0;
        final sizeMb = (fileSize / (1024 * 1024)).toStringAsFixed(2);
        
        final updatedAtStr = save['updatedAt'] as String? ?? '';
        String formattedDate = '';
        if (updatedAtStr.isNotEmpty) {
          try {
            final date = DateTime.parse(updatedAtStr).toLocal();
            formattedDate = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
                '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
          } catch (_) {
            formattedDate = updatedAtStr;
          }
        }

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6.0),
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1C28),
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.04),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.cloud_done, color: Color(0xFF919AFF), size: 20.0),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      save['fileName'] as String? ?? 'backup.zip',
                      style: const TextStyle(color: Colors.white70, fontSize: 13.0, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      '$sizeMb MB | $formattedDate',
                      style: const TextStyle(color: Colors.white38, fontSize: 11.0),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: widget.state.t('settings_cloud_btn_restore'),
                    icon: const Icon(Icons.settings_backup_restore, color: Colors.greenAccent, size: 20.0),
                    onPressed: widget.state.isProcessing ? null : () async {
                      await widget.state.restoreCloudSave(fileKey);
                    },
                  ),
                  IconButton(
                    tooltip: widget.state.t('settings_cloud_btn_delete'),
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20.0),
                    onPressed: widget.state.isProcessing ? null : () async {
                      await widget.state.deleteCloudSave(fileKey);
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
