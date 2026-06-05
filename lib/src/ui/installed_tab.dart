import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:overlayer_ui_flutter/overlayer_ui_flutter.dart';
import '../core/installer_state.dart';
import '../models/mod_model.dart';
import 'dialogs.dart';

class InstalledTab extends StatefulWidget {
  final InstallerState state;
  const InstalledTab({super.key, required this.state});

  @override
  State<InstalledTab> createState() => _InstalledTabState();
}

class _InstalledTabState extends State<InstalledTab> {
  bool _isLoadingOnlineData = false;
  // 각 설치된 모드의 온라인 상세 정보 캐시 (최신 버전 대조용)
  final Map<String, ModItem> _onlineModsCache = {};
  String? _lastGameId;

  @override
  void initState() {
    super.initState();
    _lastGameId = widget.state.game.id;
    _loadOnlineDetails();
    widget.state.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    widget.state.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) {
      if (_lastGameId != widget.state.game.id) {
        _lastGameId = widget.state.game.id;
        _onlineModsCache.clear();
      }
      _loadOnlineDetails(); // 모드가 설치/삭제되면 캐시를 갱신
      setState(() {});
    }
  }

  // 로컬 설치된 모드들의 온라인 데이터를 가져와 캐싱
  Future<void> _loadOnlineDetails() async {
    if (_isLoadingOnlineData) return;
    
    final localMods = widget.state.installedMods;
    if (localMods.isEmpty) return;

    // 캐시에 없는 모드들만 조회
    final slugsToFetch = localMods
        .map((m) => m.slug)
        .where((slug) => !_onlineModsCache.containsKey(slug))
        .toList();

    if (slugsToFetch.isEmpty) return;

    setState(() {
      _isLoadingOnlineData = true;
    });

    try {
      final futures = slugsToFetch.map((slug) async {
        try {
          // UMM 모드 접두사 'umm-'가 있으면 제거하여 온라인 API 조회 시 호환성 확보
          final cleanSlug = slug.startsWith('umm-') ? slug.substring(4) : slug;
          try {
            final result = await widget.state.apiService.fetchModDetails(cleanSlug);
            return {'localSlug': slug, 'data': result};
          } catch (e) {
            // 상세 조회 실패 시, 검색 API를 통해 매칭 시도 (예: UMM ID 'Tweaks' -> 'adofai-tweaks')
            final searchResult = await widget.state.apiService.fetchMods(
              game: widget.state.game.id,
              search: cleanSlug,
            );
            final List<ModItem> searchMods = searchResult['mods'] as List<ModItem>;
            for (final searchMod in searchMods) {
              if (widget.state.game.isModMatched(slug, searchMod.slug)) {
                final detailResult = await widget.state.apiService.fetchModDetails(searchMod.slug);
                return {'localSlug': slug, 'data': detailResult};
              }
            }
            rethrow;
          }
        } catch (_) {
          return null;
        }
      });
      
      final results = await Future.wait(futures);

      for (var result in results) {
        if (result != null) {
          final localSlug = result['localSlug'] as String;
          final data = result['data'] as Map<String, dynamic>;
          final mod = data['mod'] as ModItem;
          // 캐시 저장 시 로컬에서 조회한 슬러그로 저장하여 뷰에서 매치되도록 함
          _onlineModsCache[localSlug] = mod;
        }
      }
    } catch (_) {
      // 온라인 조회 실패 시 단순 넘어감 (오프라인 동작 지원)
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingOnlineData = false;
        });
      }
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
        allowedExtensions: ['zip', 'dll'],
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
          SnackBar(content: Text(widget.state.t('installed_err_file_picker', args: {'error': e.toString()}))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final guideKey = widget.state.game.getSteamLaunchOptionsGuideKey();
    final launchGuide = guideKey != null ? widget.state.t(guideKey) : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Text(
            widget.state.t('installed_title'),
            style: const TextStyle(
              fontSize: 22.0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 24.0),

          // 1. MelonLoader 관리 카드
          _buildCard(
            title: widget.state.t('installed_loader_title'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          widget.state.isLoaderInstalled
                              ? (widget.state.isLoaderOutdated ? Icons.warning_amber_rounded : Icons.check_circle)
                              : (widget.state.isUmmDetected ? Icons.warning_amber_rounded : Icons.cancel),
                          color: widget.state.isLoaderInstalled
                              ? (widget.state.isLoaderOutdated ? Colors.orangeAccent : const Color(0xFF919AFF))
                              : (widget.state.isUmmDetected ? Colors.orangeAccent : Colors.white30),
                        ),
                        const SizedBox(width: 12.0),
                        Text(
                          widget.state.isLoaderInstalled
                              ? (widget.state.isLoaderOutdated
                                  ? widget.state.t('installed_loader_outdated_title')
                                  : widget.state.t('installed_loader_active', args: {'version': widget.state.loaderVersion}))
                              : (widget.state.isUmmDetected
                                  ? widget.state.t('installed_loader_umm_title')
                                  : widget.state.t('installed_loader_inactive')),
                          style: const TextStyle(color: Colors.white, fontSize: 14.0),
                        ),
                      ],
                    ),
                    if (widget.state.isProcessing)
                      const SizedBox(
                        width: 20.0,
                        height: 20.0,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF919AFF)),
                        ),
                      )
                    else if (widget.state.isValidPath)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.state.isLoaderInstalled && widget.state.isLoaderOutdated) ...[
                            SizedBox(
                              width: 150.0,
                              height: 38.0,
                              child: UIButton(
                                label: widget.state.t('installed_btn_update_loader', args: {'version': '0.7.3'}),
                                fontSize: 13.0,
                                onClick: () async {
                                  await widget.state.installMelonLoader();
                                },
                              ),
                            ),
                            const SizedBox(width: 8.0),
                          ],
                          SizedBox(
                            width: widget.state.isUmmDetected ? 200.0 : 150.0,
                            height: 38.0,
                            child: UIButton(
                              label: widget.state.isLoaderInstalled
                                  ? widget.state.t('installed_btn_uninstall')
                                  : (widget.state.isUmmDetected ? widget.state.t('installed_btn_replace_loader') : widget.state.t('installed_btn_install')),
                              fontSize: widget.state.isUmmDetected ? 13.0 : 14.0,
                              onClick: () async {
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
                          ),
                        ],
                      ),
                  ],
                ),
                
                // MelonLoader 구버전 안내 배너
                if (widget.state.isLoaderInstalled && widget.state.isLoaderOutdated) ...[
                  const SizedBox(height: 12.0),
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: const Color(0x1FFF9800),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.orangeAccent, size: 20.0),
                        const SizedBox(width: 10.0),
                        Expanded(
                          child: Text(
                            widget.state.t('installed_loader_outdated_banner', args: {
                              'version': widget.state.loaderVersion,
                              'targetVersion': '0.7.3'
                            }),
                            style: const TextStyle(color: Colors.orangeAccent, fontSize: 12.5, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // UMM 감지 안내 배너
                if (widget.state.isUmmDetected) ...[
                  const SizedBox(height: 12.0),
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: const Color(0x1FFF9800),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.orangeAccent, size: 20.0),
                        const SizedBox(width: 10.0),
                        Expanded(
                          child: Text(
                            widget.state.t('installed_umm_banner'),
                            style: const TextStyle(color: Colors.orangeAccent, fontSize: 12.5, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                // 스팀 런치 가이드 (Linux, macOS 등 비윈도우 플랫폼용)
                if (widget.state.isLoaderInstalled && launchGuide != null) ...[
                  const SizedBox(height: 16.0),
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16151D),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          widget.state.t('installed_launch_guide_title'),
                          style: const TextStyle(color: Color(0xFF919AFF), fontSize: 13.0, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          launchGuide,
                          style: const TextStyle(color: Colors.white70, fontSize: 12.0, height: 1.4),
                        ),
                        const SizedBox(height: 12.0),
                        Row(
                          children: [
                            if (launchGuide.contains('setup_helper.sh')) ...[
                              SizedBox(
                                height: 36,
                                child: UIButton(
                                  label: widget.state.t('installed_btn_copy_native_launch'),
                                  fontSize: 13.0,
                                  onClick: () => _copyToClipboard('./setup_helper.sh %command%'),
                                ),
                              ),
                              const SizedBox(width: 8.0),
                            ],
                            if (launchGuide.contains('WINEDLLOVERRIDES')) ...[
                              SizedBox(
                                height: 36,
                                child: UIButton(
                                  label: widget.state.t('installed_btn_copy_proton_launch'),
                                  fontSize: 13.0,
                                  onClick: () => _copyToClipboard('WINEDLLOVERRIDES="winhttp=n,b" %command%'),
                                ),
                              ),
                            ]
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24.0),

          // 2. 로컬 설치 모드 관리 카드
          _buildCard(
            title: widget.state.t('installed_list_title'),
            action: widget.state.isProcessing || !widget.state.isValidPath
                ? null
                : Tooltip(
                    message: widget.state.t('installed_btn_add_mod_manually'),
                    child: IconButton(
                      icon: const Icon(
                        Icons.file_open_outlined,
                        color: Color(0xFF919AFF),
                        size: 20.0,
                      ),
                      hoverColor: const Color(0xFF919AFF).withValues(alpha: 0.08),
                      splashRadius: 20.0,
                      onPressed: _pickAndInstallMod,
                    ),
                  ),
            child: widget.state.installedMods.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32.0),
                    child: Center(
                      child: Text(
                        widget.state.t('installed_no_mods'),
                        style: const TextStyle(color: Colors.white24, fontSize: 14.0),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.state.installedMods.length,
                    separatorBuilder: (context, index) => const Divider(color: Colors.white10),
                    itemBuilder: (context, index) {
                      final mod = widget.state.installedMods[index];
                      final onlineMod = _onlineModsCache[mod.slug];
                      final hasUpdate = onlineMod != null &&
                          onlineMod.latestVersion != null &&
                          mod.version != onlineMod.latestVersion!.version;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    mod.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15.0,
                                    ),
                                  ),
                                  const SizedBox(height: 4.0),
                                  Row(
                                    children: [
                                      Text(
                                        widget.state.t('installed_ver_prefix', args: {'version': mod.version}),
                                        style: const TextStyle(color: Colors.white38, fontSize: 12.0),
                                      ),
                                      if (onlineMod != null) ...[
                                        const SizedBox(width: 12.0),
                                        Text(
                                          widget.state.t('installed_latest_ver_prefix', args: {
                                            'version': onlineMod.latestVersion?.version ?? "0.0.0"
                                          }),
                                          style: TextStyle(
                                            color: hasUpdate ? Colors.orangeAccent : Colors.white38,
                                            fontSize: 12.0,
                                            fontWeight: hasUpdate ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                        if (onlineMod.latestVersion?.gameVersion != null) ...[
                                          const SizedBox(width: 12.0),
                                          Text(
                                            widget.state.t('installed_game_ver_prefix', args: {
                                              'version': onlineMod.latestVersion!.gameVersion!
                                            }),
                                            style: const TextStyle(color: Colors.white38, fontSize: 12.0),
                                          ),
                                        ],
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12.0),
                            Row(
                              children: [
                                if (hasUpdate && !widget.state.isProcessing) ...[
                                  SizedBox(
                                    width: 90.0,
                                    height: 36.0,
                                    child: UIButton(
                                      label: widget.state.t('installed_btn_update_mod'),
                                      fontSize: 13.0,
                                      onClick: () async {
                                        await widget.state.installMod(
                                          onlineMod,
                                          version: onlineMod.latestVersion?.version,
                                        );
                                        if (context.mounted) {
                                          checkAndPromptUmmCompat(context, widget.state);
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8.0),
                                ],
                                if (!widget.state.isProcessing)
                                  SizedBox(
                                    width: 85.0,
                                    height: 36.0,
                                    child: UIButton(
                                      label: widget.state.t('installed_btn_delete_mod'),
                                      fontSize: 13.0,
                                      onClick: () async {
                                        final confirm = await showDeleteConfirmDialog(context, widget.state, mod.name);
                                        if (confirm) {
                                          await widget.state.uninstallMod(mod.slug, mod.name);
                                        }
                                      },
                                    ),
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
            const SizedBox(height: 24.0),
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1C28),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: const Color(0xFF919AFF).withValues(alpha: 0.15)),
              ),
              child: Text(
                widget.state.statusMessage!,
                style: const TextStyle(color: Color(0xFF919AFF), fontSize: 13.0, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ]
        ],
      ),
    );
  }



  Widget _buildCard({required String title, Widget? action, required Widget child}) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF919AFF),
                ),
              ),
              action ?? const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: 16.0),
          child,
        ],
      ),
    );
  }
}
