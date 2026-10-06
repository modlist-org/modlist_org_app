import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:overlayer_ui_flutter/overlayer_ui_flutter.dart';
import '../core/installer_state.dart';
import '../core/update_checker.dart';
import 'theme.dart';
import 'dialogs.dart';
import 'widgets.dart';

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
          backgroundColor: AppColors.danger,
          duration: Duration(milliseconds: 2100),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasPath = widget.state.gamePath.isNotEmpty;
    final bool isValid = widget.state.isValidPath;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32.0, 28.0, 32.0, 32.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              PageHeader(title: widget.state.t('settings_title')),
              const SizedBox(height: 24.0),

              // Game Path Card
              AppCard(
                title: widget.state.t(
                  'settings_game_path_title_${widget.state.game.id}',
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14.0,
                        vertical: 12.0,
                      ),
                      decoration: BoxDecoration(
                        color: isValid
                            ? AppColors.bgElev
                            : AppColors.dangerSoft,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isValid
                                ? Icons.folder_outlined
                                : Icons.folder_off_outlined,
                            size: 20.0,
                            color: isValid
                                ? AppColors.accent
                                : AppColors.danger,
                          ),
                          const SizedBox(width: 12.0),
                          Expanded(
                            child: SelectableText(
                              hasPath
                                  ? widget.state.gamePath
                                  : widget.state.t('settings_path_empty'),
                              style: TextStyle(
                                color: hasPath
                                    ? AppColors.text
                                    : AppColors.textTertiary,
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isValid && hasPath) ...[
                      const SizedBox(height: 8.0),
                      Text(
                        widget.state.t(
                          'settings_path_invalid_${widget.state.game.id}',
                        ),
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16.0),
                    Row(
                      children: [
                        Expanded(
                          child: OlButton(
                            expand: true,
                            label: widget.state.t(
                              'settings_btn_select_manually',
                            ),
                            icon: Icons.folder_open_outlined,
                            onClick: _pickDirectory,
                          ),
                        ),
                        const SizedBox(width: 10.0),
                        Expanded(
                          child: OlButton(
                            expand: true,
                            label: widget.state.t('settings_btn_auto_detect'),
                            icon: Icons.search_rounded,
                            onClick: _detectPath,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),

              // API Server URL Card
              AppCard(
                title: widget.state.t('settings_api_title'),
                description: widget.state.t('settings_api_guide'),
                child: Row(
                  children: [
                    Expanded(
                      child: HoverOutlineField(
                        child: TextField(
                          controller: _urlController,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 14.0,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'https://modlist.org',
                            prefixIcon: Icon(Icons.link_rounded, size: 18.0),
                            prefixIconConstraints: BoxConstraints(
                              minWidth: 40.0,
                              minHeight: 42.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10.0),
                    SizedBox(
                      width: 120.0,
                      child: OlButton(
                        expand: true,
                        height: 42.0,
                        label: widget.state.t('settings_btn_save'),
                        onClick: () async {
                          final url = _urlController.text.trim();
                          if (url.isNotEmpty) {
                            final messenger = ScaffoldMessenger.of(context);
                            await widget.state.setApiUrl(url);
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  widget.state.t('settings_api_saved'),
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),

              // Language Card
              AppCard(
                title: widget.state.t('settings_lang_title'),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: 280.0,
                    height: 42.0,
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
              ),
              const SizedBox(height: 16.0),

              // System Info Card
              AppCard(
                title: widget.state.t('settings_sys_title'),
                action: AppButton(
                  label: widget.state.t('settings_btn_check_updates'),
                  icon: Icons.refresh_rounded,
                  variant: AppButtonVariant.secondary,
                  size: AppButtonSize.sm,
                  onPressed: () {
                    checkForAppUpdate(
                      context,
                      widget.state,
                      showNoUpdate: true,
                    );
                  },
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.bgElev,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildInfoRow(
                        widget.state.t('settings_sys_os'),
                        Platform.operatingSystem.toUpperCase(),
                      ),
                      const Divider(),
                      _buildInfoRow(
                        widget.state.t('settings_sys_ver'),
                        'v${UpdateChecker.currentVersion} (Beta)',
                      ),
                      const Divider(),
                      _buildInfoRow(
                        widget.state.t('settings_sys_loader'),
                        'MelonLoader (Mono/IL2CPP)',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 11.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13.5,
            ),
          ),
          const SizedBox(width: 16.0),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
