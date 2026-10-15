import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:path/path.dart' as p;
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

// 트레이 상주, 단일 인스턴스, 시작 시 실행 관리
class BackgroundService with TrayListener, WindowListener {
  BackgroundService._();
  static final BackgroundService instance = BackgroundService._();

  static const String hiddenArg = '--hidden';
  static const String _appName = 'modlist.org';
  // shortcut: 고정 포트 단일 인스턴스, 다른 프로그램이 포트를 쓰면 단일 인스턴스 없이 그냥 실행됨
  static const int _instancePort = 47913;

  /// 다른 인스턴스(딥링크 클릭 등)에서 넘어온 modlist:// 링크
  final ValueNotifier<String?> incomingDeepLink = ValueNotifier(null);

  ServerSocket? _server;

  /// 이미 실행 중인 인스턴스가 있으면 인자를 넘기고 true 반환 (호출 측에서 종료)
  Future<bool> forwardToRunningInstance(List<String> args) async {
    try {
      _server = await ServerSocket.bind(InternetAddress.loopbackIPv4, _instancePort);
      _server!.listen(_onClient);
      return false;
    } on SocketException {
      try {
        final socket = await Socket.connect(InternetAddress.loopbackIPv4, _instancePort,
            timeout: const Duration(seconds: 2));
        socket.write('${args.join('\n')}\n');
        await socket.flush();
        await socket.close();
        return true;
      } catch (_) {
        return false;
      }
    }
  }

  void _onClient(Socket socket) {
    socket.cast<List<int>>().transform(utf8.decoder).transform(const LineSplitter()).listen(
      (line) {
        if (line.startsWith('modlist://')) incomingDeepLink.value = line;
      },
      onDone: () {
        socket.destroy();
        showWindow();
      },
      onError: (_) => socket.destroy(),
    );
  }

  Future<void> init(List<String> args) async {
    await windowManager.ensureInitialized();
    await windowManager.setPreventClose(true);
    windowManager.addListener(this);

    await trayManager.setIcon(Platform.isWindows ? 'assets/tray_icon.ico' : 'assets/tray_icon.png');
    if (!Platform.isLinux) await trayManager.setToolTip(_appName);
    await trayManager.setContextMenu(Menu(items: [
      MenuItem(key: 'open', label: 'Open modlist.org'),
      MenuItem.separator(),
      MenuItem(key: 'quit', label: 'Quit'),
    ]));
    trayManager.addListener(this);

    if (!Platform.isMacOS) {
      // 공백 있는 경로 대비 따옴표, AppImage는 마운트 경로가 매번 바뀌므로 원본 파일 경로 사용
      final exe = Platform.environment['APPIMAGE'] ?? Platform.resolvedExecutable;
      launchAtStartup.setup(appName: _appName, appPath: '"$exe"', args: const [hiddenArg]);
    }

    if (args.contains(hiddenArg)) {
      await windowManager.waitUntilReadyToShow(null, () => windowManager.hide());
    }
  }

  /// 새 인스턴스를 띄우기 전에 호출 (자체 업데이트 재실행이 기존 인스턴스로 전달되고 꺼지는 것 방지)
  Future<void> releaseInstanceLock() async {
    await _server?.close();
    _server = null;
  }

  Future<void> showWindow() async {
    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> quit() async {
    await trayManager.destroy();
    await _server?.close();
    exit(0);
  }

  @override
  void onWindowClose() => windowManager.hide();

  @override
  void onTrayIconMouseDown() => showWindow();

  @override
  void onTrayIconRightMouseDown() => trayManager.popUpContextMenu();

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (menuItem.key == 'open') showWindow();
    if (menuItem.key == 'quit') quit();
  }

  // macOS는 launch_at_startup이 네이티브 코드를 요구해서 LaunchAgent plist를 직접 관리 (앱이 샌드박스가 아니라 가능)
  File get _macLaunchAgent => File(p.join(
      Platform.environment['HOME'] ?? '', 'Library', 'LaunchAgents', 'org.modlist.app.plist'));

  Future<bool> isLaunchAtStartupEnabled() async {
    try {
      if (Platform.isMacOS) return _macLaunchAgent.existsSync();
      return await launchAtStartup.isEnabled();
    } catch (_) {
      return false;
    }
  }

  Future<void> setLaunchAtStartup(bool enable) async {
    if (!Platform.isMacOS) {
      enable ? await launchAtStartup.enable() : await launchAtStartup.disable();
      return;
    }
    final file = _macLaunchAgent;
    if (!enable) {
      if (file.existsSync()) await file.delete();
      return;
    }
    String esc(String s) =>
        s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');
    await file.parent.create(recursive: true);
    await file.writeAsString('''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>org.modlist.app</string>
  <key>ProgramArguments</key>
  <array>
    <string>${esc(Platform.resolvedExecutable)}</string>
    <string>$hiddenArg</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
</dict>
</plist>
''');
  }
}
