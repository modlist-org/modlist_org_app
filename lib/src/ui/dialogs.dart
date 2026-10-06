import 'package:flutter/material.dart';
import '../core/installer_state.dart';
import '../core/update_checker.dart';
import 'theme.dart';
import 'widgets.dart';

/// Shared frame for the app's confirmation dialogs.
class AppDialogFrame extends StatelessWidget {
  final String title;
  final String body;
  final IconData? icon;
  final Color iconColor;
  final Color iconBackground;
  final List<Widget> actions;
  final bool stackActions;
  final double width;

  const AppDialogFrame({
    super.key,
    required this.title,
    required this.body,
    required this.actions,
    this.icon,
    this.iconColor = AppColors.accent,
    this.iconBackground = AppColors.accentSoft,
    this.stackActions = false,
    this.width = 460.0,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: width,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (icon != null) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 40.0,
                  height: 40.0,
                  decoration: BoxDecoration(
                    color: iconBackground,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(icon, color: iconColor, size: 20.0),
                ),
              ),
              const SizedBox(height: 16.0),
            ],
            Text(
              title,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 18.0,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10.0),
            Text(
              body,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14.0,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 24.0),
            if (stackActions)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (int i = 0; i < actions.length; i++) ...[
                    if (i > 0) const SizedBox(height: 8.0),
                    actions[i],
                  ],
                ],
              )
            else
              Row(
                children: [
                  for (int i = 0; i < actions.length; i++) ...[
                    if (i > 0) const SizedBox(width: 10.0),
                    Expanded(child: actions[i]),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Checks if MelonLoader is active, ummcompat is missing, and at least one UMM mod is installed.
/// If so, shows the UMM compatibility mod recommendation dialog.
void checkAndPromptUmmCompat(BuildContext context, InstallerState state) {
  if (state.isLoaderInstalled &&
      !state.installedMods.any((m) =>
          state.game.canonicalModSlug(m.slug).toLowerCase() == 'ummcompat' ||
          state.game.canonicalModSlug(m.id).toLowerCase() == 'ummcompat' ||
          m.id.toLowerCase() == 'umm-ummcompat' ||
          m.slug.toLowerCase() == 'umm-ummcompat') &&
      state.installedMods.any((m) => m.id.startsWith('umm-'))) {
    showInstallUmmCompatDialog(context, state);
  }
}

/// Shows the UMM compatibility mod installation dialog.
void showInstallUmmCompatDialog(BuildContext context, InstallerState state) {
  showDialog(
    context: context,
    builder: (dialogContext) {
      return AppDialogFrame(
        width: 500.0,
        icon: Icons.extension_outlined,
        title: state.t('install_ummcompat_dialog_title'),
        body: state.t('install_ummcompat_dialog_body'),
        stackActions: true,
        actions: [
          OlButton(
            expand: true,
            label: state.t('replace_umm_dialog_btn_yes'),
            onClick: () async {
              Navigator.pop(dialogContext);
              await state.installUmmCompat();
            },
          ),
          OlButton(
            expand: true,
            tone: OlButtonTone.neutral,
            label: state.t('replace_umm_dialog_btn_cancel'),
            onClick: () {
              Navigator.pop(dialogContext);
            },
          ),
        ],
      );
    },
  );
}

/// Shows a dialog to confirm mod deletion.
/// Returns true if the user chooses to delete, false otherwise.
Future<bool> showDeleteConfirmDialog(BuildContext context, InstallerState state, String modName) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AppDialogFrame(
        icon: Icons.delete_outline_rounded,
        iconColor: AppColors.danger,
        iconBackground: AppColors.dangerSoft,
        title: state.t('delete_confirm_dialog_title'),
        body: state.t('delete_confirm_dialog_body', args: {'name': modName}),
        actions: [
          OlButton(
            expand: true,
            tone: OlButtonTone.neutral,
            label: state.t('delete_confirm_dialog_btn_no'),
            onClick: () {
              Navigator.pop(dialogContext, false);
            },
          ),
          OlButton(
            expand: true,
            tone: OlButtonTone.danger,
            label: state.t('delete_confirm_dialog_btn_yes'),
            onClick: () {
              Navigator.pop(dialogContext, true);
            },
          ),
        ],
      );
    },
  );
  return result ?? false;
}

/// Shows a dialog to confirm MelonLoader uninstallation.
/// Returns true if the user chooses to uninstall, false otherwise.
Future<bool> showLoaderUninstallConfirmDialog(BuildContext context, InstallerState state) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AppDialogFrame(
        icon: Icons.delete_outline_rounded,
        iconColor: AppColors.danger,
        iconBackground: AppColors.dangerSoft,
        title: state.t('loader_uninstall_confirm_title'),
        body: state.t('loader_uninstall_confirm_body'),
        actions: [
          OlButton(
            expand: true,
            tone: OlButtonTone.neutral,
            label: state.t('delete_confirm_dialog_btn_no'),
            onClick: () {
              Navigator.pop(dialogContext, false);
            },
          ),
          OlButton(
            expand: true,
            tone: OlButtonTone.danger,
            label: state.t('delete_confirm_dialog_btn_yes'),
            onClick: () {
              Navigator.pop(dialogContext, true);
            },
          ),
        ],
      );
    },
  );
  return result ?? false;
}

/// Shows the Unity Mod Manager replacement dialog.
void showReplaceUmmDialog(BuildContext context, InstallerState state) {
  showDialog(
    context: context,
    builder: (dialogContext) {
      return AppDialogFrame(
        width: 500.0,
        icon: Icons.swap_horiz_rounded,
        iconColor: AppColors.warning,
        iconBackground: AppColors.warningSoft,
        title: state.t('replace_umm_dialog_title'),
        body: state.t('replace_umm_dialog_body'),
        stackActions: true,
        actions: [
          OlButton(
            expand: true,
            label: state.t('replace_umm_dialog_btn_yes'),
            onClick: () async {
              Navigator.pop(dialogContext);
              await state.installMelonLoader(installUmmCompat: true);
            },
          ),
          OlButton(
            expand: true,
            tone: OlButtonTone.danger,
            label: state.t('replace_umm_dialog_btn_no'),
            onClick: () async {
              Navigator.pop(dialogContext);
              await state.installMelonLoader(installUmmCompat: false);
            },
          ),
          OlButton(
            expand: true,
            tone: OlButtonTone.neutral,
            label: state.t('replace_umm_dialog_btn_cancel'),
            onClick: () {
              Navigator.pop(dialogContext);
            },
          ),
        ],
      );
    },
  );
}

/// Checks GitHub for a newer app release and prompts the user to update.
Future<void> checkForAppUpdate(
  BuildContext context,
  InstallerState state, {
  bool showNoUpdate = false,
}) async {
  try {
    final result = await UpdateChecker.fetchLatest();
    if (result == null) return;

    if (result.hasUpdate) {
      if (!context.mounted) return;
      _showUpdateDialog(
        context,
        state,
        result.latestVersion,
        result.releaseUrl,
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

void _showUpdateDialog(
  BuildContext context,
  InstallerState state,
  String latestVersion,
  String releaseUrl,
) {
  showDialog(
    context: context,
    builder: (dialogContext) {
      return AppDialogFrame(
        icon: Icons.system_update_alt_rounded,
        title: state.t('update_dialog_title'),
        body: state.t(
          'update_dialog_body',
          args: {
            'version': latestVersion,
            'currentVersion': UpdateChecker.currentVersion,
          },
        ),
        actions: [
          OlButton(
            expand: true,
            tone: OlButtonTone.neutral,
            label: state.t('update_dialog_btn_no'),
            onClick: () => Navigator.pop(dialogContext),
          ),
          OlButton(
            expand: true,
            label: state.t('update_dialog_btn_yes'),
            onClick: () {
              Navigator.pop(dialogContext);
              UpdateChecker.launchUrl(releaseUrl);
            },
          ),
        ],
      );
    },
  );
}
