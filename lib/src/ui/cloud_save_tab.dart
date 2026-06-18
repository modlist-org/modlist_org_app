import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:overlayer_ui_flutter/overlayer_ui_flutter.dart';
import '../core/installer_state.dart';

class CloudSaveTab extends StatefulWidget {
  final InstallerState state;
  const CloudSaveTab({super.key, required this.state});

  @override
  State<CloudSaveTab> createState() => _CloudSaveTabState();
}

class _CloudSaveTabState extends State<CloudSaveTab> {
  @override
  void initState() {
    super.initState();
    widget.state.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    widget.state.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _openProfileLink() async {
    final String url = '${widget.state.apiUrl}/profile';
    try {
      if (Platform.isWindows) {
        await Process.run('start', [url], runInShell: true);
      } else if (Platform.isMacOS) {
        await Process.run('open', [url]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [url]);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open link: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLinked = widget.state.integrationToken != null && widget.state.integrationToken!.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Text(
            widget.state.t('tab_cloud_save').toUpperCase(),
            style: const TextStyle(
              fontSize: 22.0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 24.0),

          if (!isLinked) ...[
            // Link Account Screen
            _buildCard(
              title: widget.state.t('cloud_link_title'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.cloud_outlined,
                    color: Color(0xFF919AFF),
                    size: 72.0,
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    widget.state.t('cloud_premium_desc'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    widget.state.t('cloud_premium_sub'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 13.0,
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  
                  // Premium Features List
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16151D).withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                    ),
                    child: Column(
                      children: [
                        _buildBenefitItem(
                          icon: Icons.cloud_sync_outlined,
                          title: widget.state.t('cloud_benefit_1_title'),
                          desc: widget.state.t('cloud_benefit_1_desc'),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10.0),
                          child: Divider(color: Colors.white10),
                        ),
                        _buildBenefitItem(
                          icon: Icons.share_outlined,
                          title: widget.state.t('cloud_benefit_2_title'),
                          desc: widget.state.t('cloud_benefit_2_desc'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28.0),
                  
                  // Link Account Button
                  SizedBox(
                    width: 280.0,
                    child: UIButton(
                      label: widget.state.t('cloud_btn_link'),
                      fontSize: 14.5,
                      onClick: _openProfileLink,
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    widget.state.t('cloud_link_guide'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white30, fontSize: 11.5, height: 1.4),
                  ),
                  const SizedBox(height: 20.0),
                  
                  // Patreon Support CTA
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 16.0),
                  Text(
                    widget.state.t('cloud_patreon_cta_text'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFFFA500),
                      fontSize: 13.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  TextButton.icon(
                    onPressed: _openPatreonLink,
                    icon: const Icon(Icons.star, color: Color(0xFFFFA500), size: 18.0),
                    label: Text(
                      widget.state.t('cloud_patreon_btn'),
                      style: const TextStyle(
                        color: Color(0xFFFFA500),
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Storage Quota
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
                            try {
                              await widget.state.backupCloudSave();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(widget.state.t('status_cloud_backup_success')),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: const Color(0xFF1E1C28),
                                    title: Text(
                                      widget.state.t('status_cloud_backup_failed', args: {'error': ''}).replaceAll(': ', ''),
                                      style: const TextStyle(color: Colors.redAccent, fontSize: 16.0, fontWeight: FontWeight.bold),
                                    ),
                                    content: Text(
                                      e.toString(),
                                      style: const TextStyle(color: Colors.white70, fontSize: 14.0),
                                    ),
                                    actions: [
                                      UIButton(
                                        label: 'OK',
                                        fontSize: 14.0,
                                        onClick: () => Navigator.pop(context),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24.0),

                  // Backups List
                  Text(
                    widget.state.t('cloud_backups_title'),
                    style: const TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  _buildBackupsList(),

                  const SizedBox(height: 24.0),

                  // Shared Presets List
                  Text(
                    widget.state.t('cloud_presets_title'),
                    style: const TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  _buildPresetsList(),

                  const SizedBox(height: 24.0),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 12.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.state.t('cloud_connected_account'),
                        style: const TextStyle(color: Colors.white38, fontSize: 13.0),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.logout, size: 16.0, color: Colors.redAccent),
                        label: Text(widget.state.t('cloud_btn_disconnect'), style: const TextStyle(color: Colors.redAccent, fontSize: 13.0)),
                        onPressed: () async {
                          await widget.state.setIntegrationToken('');
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1C28).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.04),
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
        final isAttachedToPreset = widget.state.myPresets.any((p) => p['sourceFileKey'] == fileKey || p['fileKey'] == fileKey);
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            save['fileName'] as String? ?? 'backup.zip',
                            style: const TextStyle(color: Colors.white70, fontSize: 13.0, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isAttachedToPreset) ...[
                          const SizedBox(width: 8.0),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: Text(
                              widget.state.t('backup_badge_sharing'),
                              style: const TextStyle(color: Colors.orange, fontSize: 10.0, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
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
                      try {
                        await widget.state.restoreCloudSave(fileKey);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(widget.state.t('status_cloud_restore_success')),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: const Color(0xFF1E1C28),
                              title: Text(
                                widget.state.t('status_cloud_restore_failed', args: {'error': ''}).replaceAll(': ', ''),
                                style: const TextStyle(color: Colors.redAccent, fontSize: 16.0, fontWeight: FontWeight.bold),
                              ),
                              content: Text(
                                e.toString(),
                                style: const TextStyle(color: Colors.white70, fontSize: 14.0),
                              ),
                              actions: [
                                UIButton(
                                  label: 'OK',
                                  fontSize: 14.0,
                                  onClick: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                          );
                        }
                      }
                    },
                  ),
                  IconButton(
                    tooltip: widget.state.t('settings_cloud_btn_delete'),
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20.0),
                    onPressed: widget.state.isProcessing ? null : () async {
                      final confirmDelete = await showDialog<bool>(
                        context: context,
                        barrierColor: Colors.black87,
                        builder: (context) => Dialog(
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
                                  widget.state.t('settings_cloud_btn_delete'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16.0),
                                Text(
                                  isAttachedToPreset
                                      ? widget.state.t('backup_delete_warning_attached')
                                      : widget.state.t('backup_delete_warning_normal'),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13.5,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 24.0),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    SizedBox(
                                      height: 42.0,
                                      child: UIButton(
                                        label: widget.state.t('btn_delete_confirm'),
                                        fontSize: 13.0,
                                        color: const Color(0xFFC56363),
                                        hoverColor: const Color(0xFFD67474),
                                        pressedColor: const Color(0xFFE28A8A),
                                        onClick: () => Navigator.pop(context, true),
                                      ),
                                    ),
                                    const SizedBox(height: 10.0),
                                    SizedBox(
                                      height: 42.0,
                                      child: UIButton(
                                        label: widget.state.t('btn_cancel'),
                                        fontSize: 13.0,
                                        color: const Color(0xFF383946),
                                        hoverColor: const Color(0xFF494A5B),
                                        pressedColor: const Color(0xFF5D5E72),
                                        onClick: () => Navigator.pop(context, false),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                      if (confirmDelete != true) return;
                      try {
                        await widget.state.deleteCloudSave(fileKey);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(widget.state.t('status_cloud_delete_success')),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: const Color(0xFF1E1C28),
                              title: Text(
                                widget.state.t('status_cloud_delete_failed', args: {'error': ''}).replaceAll(': ', ''),
                                style: const TextStyle(color: Colors.redAccent, fontSize: 16.0, fontWeight: FontWeight.bold),
                              ),
                              content: Text(
                                e.toString(),
                                style: const TextStyle(color: Colors.white70, fontSize: 14.0),
                              ),
                              actions: [
                                UIButton(
                                  label: 'OK',
                                  fontSize: 14.0,
                                  onClick: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                          );
                        }
                      }
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

  Widget _buildPresetsList() {
    final presets = widget.state.myPresets.where((p) => p['game'] == widget.state.game.id).toList();
    if (presets.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Text(
          widget.state.t('cloud_presets_empty'),
          style: const TextStyle(color: Colors.white30, fontSize: 13.0, fontStyle: FontStyle.italic),
        ),
      );
    }

    return Column(
      children: presets.map<Widget>((preset) {
        final presetId = preset['id'] as String;
        final name = preset['name'] as String? ?? 'Shared Preset';
        final modsCount = preset['modsCount'] as int? ?? 0;
        final hasAttachedSaves = preset['fileKey'] != null;
        
        final updatedAtStr = preset['createdAt'] as String? ?? '';
        String formattedDate = '';
        if (updatedAtStr.isNotEmpty) {
          try {
            final date = DateTime.parse(updatedAtStr).toLocal();
            formattedDate = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          } catch (_) {}
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
              const Icon(Icons.share_outlined, color: Color(0xFF919AFF), size: 20.0),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(color: Colors.white70, fontSize: 13.0, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasAttachedSaves) ...[
                          const SizedBox(width: 8.0),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: const Text(
                              'Save Attached',
                              style: TextStyle(color: Colors.orange, fontSize: 10.0, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      'Mods: $modsCount | $formattedDate',
                      style: const TextStyle(color: Colors.white38, fontSize: 11.0),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: widget.state.t('cloud_presets_copy_link'),
                    icon: const Icon(Icons.copy, color: Color(0xFF919AFF), size: 18.0),
                    onPressed: () {
                      final shareUrl = '${widget.state.apiUrl}/presets/$presetId';
                      Clipboard.setData(ClipboardData(text: shareUrl));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(widget.state.t('settings_preset_created_body'))),
                      );
                    },
                  ),
                  IconButton(
                    tooltip: widget.state.t('settings_cloud_btn_delete'),
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20.0),
                    onPressed: widget.state.isProcessing ? null : () async {
                      final confirmDelete = await showDialog<bool>(
                        context: context,
                        barrierColor: Colors.black87,
                        builder: (context) => Dialog(
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
                                  widget.state.t('settings_cloud_btn_delete'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16.0),
                                Text(
                                  widget.state.t('cloud_presets_delete_confirm'),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13.5,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 24.0),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    SizedBox(
                                      height: 42.0,
                                      child: UIButton(
                                        label: widget.state.t('btn_delete_confirm'),
                                        fontSize: 13.0,
                                        color: const Color(0xFFC56363),
                                        hoverColor: const Color(0xFFD67474),
                                        pressedColor: const Color(0xFFE28A8A),
                                        onClick: () => Navigator.pop(context, true),
                                      ),
                                    ),
                                    const SizedBox(height: 10.0),
                                    SizedBox(
                                      height: 42.0,
                                      child: UIButton(
                                        label: widget.state.t('btn_cancel'),
                                        fontSize: 13.0,
                                        color: const Color(0xFF383946),
                                        hoverColor: const Color(0xFF494A5B),
                                        pressedColor: const Color(0xFF5D5E72),
                                        onClick: () => Navigator.pop(context, false),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                      if (confirmDelete != true) return;
                      try {
                        await widget.state.deletePreset(presetId);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Preset deleted successfully.'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: const Color(0xFF1E1C28),
                              title: const Text(
                                'Delete Failed',
                                style: TextStyle(color: Colors.redAccent, fontSize: 16.0, fontWeight: FontWeight.bold),
                              ),
                              content: Text(
                                e.toString(),
                                style: const TextStyle(color: Colors.white70, fontSize: 14.0),
                              ),
                              actions: [
                                UIButton(
                                  label: 'OK',
                                  fontSize: 14.0,
                                  onClick: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                          );
                        }
                      }
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

  Widget _buildBenefitItem({required IconData icon, required String title, required String desc}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF919AFF), size: 24.0),
        const SizedBox(width: 12.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                desc,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 12.5,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openPatreonLink() async {
    const String url = 'https://www.patreon.com/c/modlist_org/membership';
    try {
      if (Platform.isWindows) {
        await Process.run('start', [url], runInShell: true);
      } else if (Platform.isMacOS) {
        await Process.run('open', [url]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [url]);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open link: $e')),
        );
      }
    }
  }
}
