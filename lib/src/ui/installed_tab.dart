import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../core/app_errors.dart';
import '../core/installer_state.dart';
import '../core/version_utils.dart';
import 'dialogs.dart';
import 'explore_tab.dart' show buildModLogo;
import 'theme.dart';
import 'widgets.dart';

class InstalledTab extends StatefulWidget {
  final InstallerState state;
  const InstalledTab({super.key, required this.state});

  @override
  State<InstalledTab> createState() => _InstalledTabState();
}

class _InstalledTabState extends State<InstalledTab> {
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

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(widget.state.t('installed_copied_clipboard'))),
    );
  }

  Future<void> _pickAndInstallMod() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'zip',
          'dll',
          'tar',
          'xz',
          'zst',
          'zstd',
          'txz',
          'tzst',
        ],
        dialogTitle: widget.state.t('installed_btn_add_mod_manually'),
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        await widget.state.installModFromFile(filePath);
        if (mounted) {
          checkAndPromptUmmCompat(context, widget.state);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.state.t(
                'installed_err_file_picker',
                args: {'error': describeAppError(e)},
              ),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final guideKey = widget.state.game.getSteamLaunchOptionsGuideKey();
    final launchGuide = guideKey != null ? widget.state.t(guideKey) : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32.0, 28.0, 32.0, 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          PageHeader(title: widget.state.t('installed_title')),
          const SizedBox(height: 24.0),

          // 1. MelonLoader 관리 카드
          AppCard(
            title: widget.state.t('installed_loader_title'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildLoaderStatusRow(),

                // MelonLoader 구버전 안내 배너
                if (widget.state.isLoaderInstalled && widget.state.isLoaderOutdated) ...[
                  const SizedBox(height: 14.0),
                  StatusBanner(
                    tone: BannerTone.warning,
                    message: widget.state.t('installed_loader_outdated_banner', args: {
                      'version': widget.state.loaderVersion,
                      'targetVersion': '0.7.3'
                    }),
                  ),
                ],

                // UMM 감지 안내 배너
                if (widget.state.isUmmDetected) ...[
                  const SizedBox(height: 14.0),
                  StatusBanner(
                    tone: BannerTone.warning,
                    message: widget.state.t('installed_umm_banner'),
                  ),
                ],

                // 스팀 런치 가이드 (Linux, macOS 등 비윈도우 플랫폼용)
                if (widget.state.isLoaderInstalled && launchGuide != null) ...[
                  const SizedBox(height: 14.0),
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: AppColors.bgElev,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          widget.state.t('installed_launch_guide_title'),
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        SelectableText(
                          launchGuide,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12.5,
                            height: 1.55,
                          ),
                        ),
                        const SizedBox(height: 14.0),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: [
                            if (launchGuide.contains('setup_helper.sh'))
                              OlButton(
                                label: widget.state.t('installed_btn_copy_native_launch'),
                                icon: Icons.content_copy_rounded,
                                height: 36.0,
                                fontSize: 13.0,
                                onClick: () => _copyToClipboard(
                                  // Steam on macOS does not resolve relative
                                  // paths, so emit the absolute script path.
                                  Platform.isMacOS
                                      ? '"${widget.state.gamePath}/setup_helper.sh" %command%'
                                      : './setup_helper.sh %command%',
                                ),
                              ),
                            if (launchGuide.contains('WINEDLLOVERRIDES'))
                              OlButton(
                                label: widget.state.t('installed_btn_copy_proton_launch'),
                                icon: Icons.content_copy_rounded,
                                height: 36.0,
                                fontSize: 13.0,
                                onClick: () => _copyToClipboard('WINEDLLOVERRIDES="winhttp=n,b" %command%'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16.0),

          // 2. 로컬 설치 모드 관리 카드
          AppCard(
            title: widget.state.t('installed_list_title'),
            padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 8.0),
            // Always rendered so the header doesn't jump while tasks run
            action: !widget.state.isValidPath
                ? null
                : AppButton(
                    label: widget.state.t('installed_btn_add_mod_manually'),
                    icon: Icons.upload_file_outlined,
                    variant: AppButtonVariant.secondary,
                    size: AppButtonSize.sm,
                    onPressed: widget.state.isProcessing ? null : _pickAndInstallMod,
                  ),
            child: widget.state.installedMods.isEmpty
                ? Container(
                    margin: const EdgeInsets.only(bottom: 12.0),
                    padding: const EdgeInsets.symmetric(vertical: 36.0),
                    decoration: BoxDecoration(
                      color: AppColors.bgElev,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.inventory_2_outlined,
                          size: 28.0,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(height: 10.0),
                        Text(
                          widget.state.t('installed_no_mods'),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14.0,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.state.installedMods.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final mod = widget.state.installedMods[index];
                      final onlineMod = widget.state.onlineModsCache[mod.slug];
                      final hasUpdate = onlineMod != null &&
                          onlineMod.latestVersion != null &&
                          VersionUtils.isNewerVersion(mod.version, onlineMod.latestVersion!.version);
                      final showSwitch = !mod.id.startsWith('umm-');
                      final bool modBusy = widget.state.isProcessing || widget.state.activeTaskFor(mod.slug) != null;
                      final opacity = mod.isEnabled ? 1.0 : 0.45;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Row(
                          children: [
                            if (showSwitch) ...[
                              OlSwitch(
                                value: mod.isEnabled,
                                onChanged: modBusy
                                    ? null
                                    : (value) async {
                                        await widget.state.toggleModActive(mod, value);
                                      },
                              ),
                              const SizedBox(width: 14.0),
                            ],
                            Expanded(
                              child: Opacity(
                                opacity: opacity,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40.0,
                                      height: 40.0,
                                      decoration: BoxDecoration(
                                        color: AppColors.control,
                                        borderRadius: BorderRadius.circular(AppRadius.sm),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: buildModLogo(
                                        logoPath: onlineMod?.logo,
                                        fallbackName: mod.name,
                                        apiUrl: widget.state.apiUrl,
                                        width: 40.0,
                                        height: 40.0,
                                        fallbackFontSize: 16.0,
                                        getFallbackGradient: fallbackLogoGradient,
                                      ),
                                    ),
                                    const SizedBox(width: 12.0),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  mod.name,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: AppColors.text,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14.5,
                                                  ),
                                                ),
                                              ),
                                              if (mod.isBeta) ...[
                                                const SizedBox(width: 8.0),
                                                AppBadge(
                                                  label: widget.state.t('explore_modal_beta'),
                                                  tone: BadgeTone.warning,
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 4.0),
                                          Wrap(
                                            spacing: 12.0,
                                            runSpacing: 2.0,
                                            children: [
                                              Text(
                                                widget.state.t('installed_ver_prefix', args: {'version': mod.version}),
                                                style: const TextStyle(color: AppColors.textTertiary, fontSize: 12.5),
                                              ),
                                              if (onlineMod != null) ...[
                                                Text(
                                                  widget.state.t('installed_latest_ver_prefix', args: {
                                                    'version': onlineMod.latestVersion?.version ?? "0.0.0"
                                                  }),
                                                  style: TextStyle(
                                                    color: hasUpdate ? AppColors.warning : AppColors.textTertiary,
                                                    fontSize: 12.5,
                                                    fontWeight: hasUpdate ? FontWeight.w600 : FontWeight.normal,
                                                  ),
                                                ),
                                                if (onlineMod.latestVersion?.gameVersion != null)
                                                  Text(
                                                    widget.state.t('installed_game_ver_prefix', args: {
                                                      'version': onlineMod.latestVersion!.gameVersion!
                                                    }),
                                                    style: const TextStyle(color: AppColors.textTertiary, fontSize: 12.5),
                                                  ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12.0),
                            Wrap(
                              spacing: 8.0,      // 버튼 간 가로 간격
                              runSpacing: 8.0,   // 줄바꿈 발생 시 세로 간격
                              children: [
                                if (hasUpdate)
                                  OlButton(
                                    label: widget.state.t('installed_btn_update_mod'),
                                    icon: Icons.download_rounded,
                                    height: 36.0,
                                    fontSize: 13.0,
                                    onClick: modBusy ? null : () async {
                                      await widget.state.installMod(onlineMod, version: onlineMod.latestVersion?.version);
                                      if (context.mounted) checkAndPromptUmmCompat(context, widget.state);
                                    },
                                  ),
                                OlButton(
                                    label: widget.state.t('installed_btn_delete_mod'),
                                    icon: Icons.delete_outline_rounded,
                                    tone: OlButtonTone.danger,
                                    height: 36.0,
                                    fontSize: 13.0,
                                    onClick: modBusy ? null : () async {
                                      final confirm = await showDeleteConfirmDialog(context, widget.state, mod.name);
                                      if (confirm) await widget.state.uninstallMod(mod.slug, mod.name);
                                    },
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // 전역 진행 상태 텍스트
          if (widget.state.statusMessage != null) ...[
            const SizedBox(height: 16.0),
            StatusBanner(
              tone: BannerTone.info,
              message: widget.state.statusMessage!,
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildLoaderStatusRow() {
    final bool installed = widget.state.isLoaderInstalled;
    final bool outdated = widget.state.isLoaderOutdated;
    final bool umm = widget.state.isUmmDetected;

    final IconData icon = installed
        ? (outdated ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded)
        : (umm ? Icons.warning_amber_rounded : Icons.cancel_outlined);
    final Color color = installed
        ? (outdated ? AppColors.warning : AppColors.accent)
        : (umm ? AppColors.warning : AppColors.muted);
    final Color tint = installed
        ? (outdated ? AppColors.warningSoft : AppColors.accentSoft)
        : (umm ? AppColors.warningSoft : AppColors.control);

    return Row(
      children: [
        Container(
          width: 40.0,
          height: 40.0,
          decoration: BoxDecoration(
            color: tint,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, color: color, size: 20.0),
        ),
        const SizedBox(width: 12.0),
        Expanded(
          child: Text(
            installed
                ? (outdated
                    ? widget.state.t('installed_loader_outdated_title')
                    : widget.state.t('installed_loader_active', args: {'version': widget.state.loaderVersion}))
                : (umm
                    ? widget.state.t('installed_loader_umm_title')
                    : widget.state.t('installed_loader_inactive')),
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 14.0,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12.0),
        if (widget.state.isProcessing)
          const SizedBox(
            width: 18.0,
            height: 18.0,
            child: CircularProgressIndicator(strokeWidth: 2.0),
          )
        else if (widget.state.isValidPath)
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              if (installed && outdated)
                OlButton(
                  label: widget.state.t('installed_btn_update_loader', args: {'version': '0.7.3'}),
                  icon: Icons.download_rounded,
                  onClick: widget.state.hasActiveTasks ? null : () async {
                    await widget.state.installMelonLoader();
                  },
                ),
              OlButton(
                label: installed
                    ? widget.state.t('installed_btn_uninstall')
                    : (umm ? widget.state.t('installed_btn_replace_loader') : widget.state.t('installed_btn_install')),
                tone: installed ? OlButtonTone.danger : OlButtonTone.primary,
                icon: installed
                    ? Icons.delete_outline_rounded
                    : (umm ? Icons.swap_horiz_rounded : Icons.download_rounded),
                onClick: widget.state.hasActiveTasks ? null : () async {
                  if (widget.state.isLoaderInstalled) {
                    final confirm = await showLoaderUninstallConfirmDialog(context, widget.state);
                    if (confirm) {
                      await widget.state.uninstallMelonLoader();
                    }
                  } else {
                    if (widget.state.isUmmDetected) {
                      showReplaceUmmDialog(context, widget.state);
                    } else {
                      await widget.state.installMelonLoader();
                    }
                  }
                },
              ),
            ],
          ),
      ],
    );
  }
}
