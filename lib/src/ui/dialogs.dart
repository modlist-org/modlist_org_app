import 'package:flutter/material.dart';
import 'package:overlayer_ui_flutter/overlayer_ui_flutter.dart';
import '../core/installer_state.dart';

/// Checks if MelonLoader is active, ummcompat is missing, and at least one UMM mod is installed.
/// If so, shows the UMM compatibility mod recommendation dialog.
void checkAndPromptUmmCompat(BuildContext context, InstallerState state) {
  if (state.isLoaderInstalled &&
      !state.installedMods.any((m) =>
          m.slug.toLowerCase() == 'ummcompat' ||
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
    barrierColor: Colors.black87,
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: const Color(0xFF1E1C28),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Container(
          width: 500.0,
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                state.t('install_ummcompat_dialog_title'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16.0),
              Text(
                state.t('install_ummcompat_dialog_body'),
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
                      label: state.t('replace_umm_dialog_btn_yes'),
                      fontSize: 13.0,
                      onClick: () async {
                        Navigator.pop(dialogContext);
                        await state.installUmmCompat();
                      },
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  SizedBox(
                    height: 42.0,
                    child: UIButton(
                      label: state.t('replace_umm_dialog_btn_cancel'),
                      fontSize: 13.0,
                      color: const Color(0xFF383946),
                      hoverColor: const Color(0xFF494A5B),
                      pressedColor: const Color(0xFF5D5E72),
                      onClick: () {
                        Navigator.pop(dialogContext);
                      },
                    ),
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

/// Shows a dialog to confirm mod deletion.
/// Returns true if the user chooses to delete, false otherwise.
Future<bool> showDeleteConfirmDialog(BuildContext context, InstallerState state, String modName) async {
  final result = await showDialog<bool>(
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
                state.t('delete_confirm_dialog_title'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16.0),
              Text(
                state.t('delete_confirm_dialog_body', args: {'name': modName}),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13.5,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24.0),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 42.0,
                      child: UIButton(
                        label: state.t('delete_confirm_dialog_btn_yes'),
                        fontSize: 13.0,
                        color: const Color(0xFFC56363),
                        hoverColor: const Color(0xFFD67474),
                        pressedColor: const Color(0xFFE28A8A),
                        onClick: () {
                          Navigator.pop(dialogContext, true);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: SizedBox(
                      height: 42.0,
                      child: UIButton(
                        label: state.t('delete_confirm_dialog_btn_no'),
                        fontSize: 13.0,
                        color: const Color(0xFF383946),
                        hoverColor: const Color(0xFF494A5B),
                        pressedColor: const Color(0xFF5D5E72),
                        onClick: () {
                          Navigator.pop(dialogContext, false);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
                state.t('loader_uninstall_confirm_title'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16.0),
              Text(
                state.t('loader_uninstall_confirm_body'),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13.5,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24.0),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 42.0,
                      child: UIButton(
                        label: state.t('delete_confirm_dialog_btn_yes'),
                        fontSize: 13.0,
                        color: const Color(0xFFC56363),
                        hoverColor: const Color(0xFFD67474),
                        pressedColor: const Color(0xFFE28A8A),
                        onClick: () {
                          Navigator.pop(dialogContext, true);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: SizedBox(
                      height: 42.0,
                      child: UIButton(
                        label: state.t('delete_confirm_dialog_btn_no'),
                        fontSize: 13.0,
                        color: const Color(0xFF383946),
                        hoverColor: const Color(0xFF494A5B),
                        pressedColor: const Color(0xFF5D5E72),
                        onClick: () {
                          Navigator.pop(dialogContext, false);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
  return result ?? false;
}
