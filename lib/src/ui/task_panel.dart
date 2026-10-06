import 'package:flutter/material.dart';
import '../core/installer_state.dart';
import 'theme.dart';

/// Floating list of running/finished mod tasks (and exclusive loader operations).
/// Rendered in an overlay so starting or finishing a task never shifts the page layout.
class TaskPanel extends StatelessWidget {
  final InstallerState state;

  const TaskPanel({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final tasks = state.tasks.where((t) => !t.isQuiet).toList();
    final showLoader = state.isProcessing;

    return AnimatedSize(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      alignment: Alignment.bottomRight,
      child: (tasks.isEmpty && !showLoader)
          ? const SizedBox.shrink()
          : ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360.0, maxHeight: 420.0),
              child: SingleChildScrollView(
                reverse: true,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (showLoader)
                      _TaskTile(
                        title: state.t('explore_modal_loading'),
                        message: state.statusMessage,
                        progress: state.progress > 0 ? state.progress : null,
                        status: ModTaskStatus.running,
                      ),
                    for (final task in tasks)
                      _TaskTile(
                        key: ValueKey(task.id),
                        title: task.name,
                        message: task.message,
                        progress: task.progress,
                        status: task.status,
                        onDismiss: task.isActive ? null : () => state.dismissTask(task.id),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final String title;
  final String? message;
  final double? progress;
  final ModTaskStatus status;
  final VoidCallback? onDismiss;

  const _TaskTile({
    super.key,
    required this.title,
    required this.message,
    required this.progress,
    required this.status,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final bool running = status == ModTaskStatus.running;
    final bool failed = status == ModTaskStatus.failed;
    final Color accent = failed ? AppColors.danger : (running ? AppColors.accent : AppColors.success);

    return Container(
      width: 360.0,
      margin: const EdgeInsets.only(top: 8.0),
      padding: const EdgeInsets.fromLTRB(14.0, 12.0, 10.0, 12.0),
      decoration: BoxDecoration(
        color: AppColors.control,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: failed ? AppColors.danger.withValues(alpha: 0.5) : AppColors.border),
        boxShadow: const [
          BoxShadow(color: Color(0x80000000), blurRadius: 25.0, offset: Offset(0, 10), spreadRadius: -5.0),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              SizedBox(
                width: 16.0,
                height: 16.0,
                child: running
                    ? CircularProgressIndicator(strokeWidth: 2.0, value: progress, color: accent)
                    : Icon(failed ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded, size: 16.0, color: accent),
              ),
              const SizedBox(width: 10.0),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.text, fontSize: 13.5, fontWeight: FontWeight.w600),
                ),
              ),
              if (running && progress != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, right: 4.0),
                  child: Text(
                    '${(progress! * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.0, fontWeight: FontWeight.w600),
                  ),
                ),
              if (onDismiss != null)
                InkWell(
                  borderRadius: BorderRadius.circular(6.0),
                  onTap: onDismiss,
                  child: const Padding(
                    padding: EdgeInsets.all(2.0),
                    child: Icon(Icons.close_rounded, size: 16.0, color: AppColors.textSecondary),
                  ),
                ),
            ],
          ),
          if (message != null && message!.isNotEmpty) ...[
            const SizedBox(height: 6.0),
            Text(
              message!,
              maxLines: failed ? 4 : 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: failed ? AppColors.danger : AppColors.textSecondary, fontSize: 12.5, height: 1.4),
            ),
          ],
          if (running) ...[
            const SizedBox(height: 10.0),
            ClipRRect(
              borderRadius: BorderRadius.circular(999.0),
              child: LinearProgressIndicator(value: progress, minHeight: 4.0, color: accent),
            ),
          ],
        ],
      ),
    );
  }
}
