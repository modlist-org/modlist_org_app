enum ModTaskKind { install, local, uninstall, toggle }

enum ModTaskStatus { running, done, failed }

/// A mod install/delete/toggle shown in the task panel.
class ModTask {
  final int id;

  /// Lower-cased mod slug (or `file:<path>` for local installs).
  final String key;
  final String name;
  final ModTaskKind kind;
  ModTaskStatus status = ModTaskStatus.running;

  /// 0..1, or null while the amount of work is unknown.
  double? progress;
  String message;

  ModTask({
    required this.id,
    required this.key,
    required this.name,
    required this.kind,
    required this.message,
    this.progress,
  });

  bool get isActive => status == ModTaskStatus.running;
  bool get isFailed => status == ModTaskStatus.failed;

  /// Quick toggles finish too fast to be worth a panel entry unless they fail.
  bool get isQuiet => kind == ModTaskKind.toggle && !isFailed;
}
