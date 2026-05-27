import 'package:flutter/material.dart';
import 'package:overlayer_ui_flutter/overlayer_ui_flutter.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'dart:convert';
import '../core/installer_state.dart';
import '../models/mod_model.dart';

String _getImageUrl(String? path, String baseUrl) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http')) return path;
  final base = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
  final relative = path.startsWith('/') ? path : '/$path';
  return '$base$relative';
}

Widget buildModLogo({
  required String? logoPath,
  required String fallbackName,
  required String apiUrl,
  required double width,
  required double height,
  required double fallbackFontSize,
  required LinearGradient Function(String) getFallbackGradient,
}) {
  if (logoPath == null || logoPath.isEmpty) {
    return _buildFallbackLogo(fallbackName, fallbackFontSize, getFallbackGradient);
  }
  
  if (logoPath.startsWith('data:image')) {
    try {
      final commaIndex = logoPath.indexOf(',');
      if (commaIndex != -1) {
        final base64Str = logoPath.substring(commaIndex + 1);
        final bytes = base64.decode(base64Str);
        return Image.memory(bytes, width: width, height: height, fit: BoxFit.cover);
      }
    } catch (e) {
      return _buildFallbackLogo(fallbackName, fallbackFontSize, getFallbackGradient);
    }
  }
  
  final url = _getImageUrl(logoPath, apiUrl);
  return Image.network(
    url,
    width: width,
    height: height,
    fit: BoxFit.cover,
    errorBuilder: (context, error, stackTrace) =>
        _buildFallbackLogo(fallbackName, fallbackFontSize, getFallbackGradient),
  );
}

Widget _buildFallbackLogo(String name, double fontSize, LinearGradient Function(String) getFallbackGradient) {
  return Container(
    decoration: BoxDecoration(
      gradient: getFallbackGradient(name),
    ),
    alignment: Alignment.center,
    child: Text(
      name.isNotEmpty ? name[0].toUpperCase() : 'M',
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
  );
}

// UMM ID(예: Tweaks)와 서버 슬러그(예: adofai-tweaks) 간의 유연한 매칭 지원 헬퍼
bool isModMatched(String localSlug, String serverSlug) {
  final cleanLocal = localSlug.startsWith('umm-') ? localSlug.substring(4).toLowerCase() : localSlug.toLowerCase();
  final cleanServer = serverSlug.toLowerCase();
  
  if (cleanLocal == cleanServer) return true;
  
  final normLocal = cleanLocal.replaceAll('-', '').replaceAll('_', '').replaceAll(' ', '');
  final normServer = cleanServer.replaceAll('-', '').replaceAll('_', '').replaceAll(' ', '');
  
  if (normServer == normLocal) return true;
  if (normServer.endsWith(normLocal)) return true;
  if (normLocal.endsWith(normServer)) return true;
  
  return false;
}

class ExploreTab extends StatefulWidget {
  final InstallerState state;
  const ExploreTab({super.key, required this.state});

  @override
  State<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab> {
  final TextEditingController _searchController = TextEditingController();
  
  String _selectedCategory = 'all';
  String _selectedSort = 'downloads_desc';
  
  List<ModItem> _mods = [];
  bool _isLoading = true;
  int _currentPage = 1;
  int _totalPages = 1;

  // 디바운스 검색용
  DateTime? _lastSearchTime;

  @override
  void initState() {
    super.initState();
    _fetchMods();
    widget.state.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    widget.state.removeListener(_onStateChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _fetchMods() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await widget.state.apiService.fetchMods(
        game: widget.state.game.id,
        categories: _selectedCategory,
        search: _searchController.text,
        sortBy: _selectedSort,
        page: _currentPage,
        limit: 8,
      );

      if (mounted) {
        setState(() {
          _mods = result['mods'] as List<ModItem>;
          final pagination = result['pagination'];
          _currentPage = pagination['page'] ?? 1;
          _totalPages = pagination['totalPages'] ?? 1;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('모드 데이터를 불러오는 데 실패했습니다: $e')),
        );
      }
    }
  }

  void _onSearchChanged(String query) {
    final now = DateTime.now();
    _lastSearchTime = now;
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_lastSearchTime == now) {
        _currentPage = 1;
        _fetchMods();
      }
    });
  }

  // 모드명에 기반한 백업 그라데이션 스타일 계산
  LinearGradient _getFallbackGradient(String name) {
    int hash = 0;
    for (int i = 0; i < name.length; i++) {
      hash = name.codeUnitAt(i) + ((hash << 5) - hash);
    }
    final double h1 = (hash.abs() % 360).toDouble();
    final double h2 = ((h1 + 40) % 360).toDouble();
    return LinearGradient(
      colors: [
        HSLColor.fromAHSL(1.0, h1, 0.7, 0.5).toColor(),
        HSLColor.fromAHSL(1.0, h2, 0.7, 0.4).toColor(),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 필터 및 검색 바
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  // 카테고리 필터
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(widget.state.t('explore_filter_category'), style: const TextStyle(color: Colors.white38, fontSize: 12.0)),
                        const SizedBox(height: 6.0),
                        SizedBox(
                          height: 42,
                          child: UIDropdown<String>(
                            modelValue: _selectedCategory,
                            defaultValue: 'all',
                            values: const ['all', 'ui', 'gameplay', 'utility', 'visuals', 'library'],
                            display: (val) {
                              if (val == 'all') return widget.state.t('explore_filter_category_all');
                              return widget.state.t('category_$val');
                            },
                            fontSize: 14.0,
                            onChanged: (val) {
                              setState(() {
                                _selectedCategory = val;
                                _currentPage = 1;
                              });
                              _fetchMods();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  // 정렬 필터
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(widget.state.t('explore_filter_sort'), style: const TextStyle(color: Colors.white38, fontSize: 12.0)),
                        const SizedBox(height: 6.0),
                        SizedBox(
                          height: 42,
                          child: UIDropdown<String>(
                            modelValue: _selectedSort,
                            defaultValue: 'downloads_desc',
                            values: const ['downloads_desc', 'updated', 'created', 'name_asc'],
                            display: (val) {
                              if (val == 'downloads_desc') return widget.state.t('explore_filter_sort_downloads');
                              if (val == 'updated') return widget.state.t('explore_filter_sort_updated');
                              if (val == 'created') return widget.state.t('explore_filter_sort_created');
                              if (val == 'name_asc') return widget.state.t('explore_filter_sort_name');
                              return val;
                            },
                            fontSize: 14.0,
                            onChanged: (val) {
                              setState(() {
                                _selectedSort = val;
                                _currentPage = 1;
                              });
                              _fetchMods();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              // 검색어 입력
              TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white, fontSize: 14.0),
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: widget.state.t('explore_search_placeholder'),
                  hintStyle: const TextStyle(color: Colors.white24),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF1E1C28),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.04)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: const BorderSide(color: Color(0xFF919AFF)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
                ),
              ),
            ],
          ),
        ),

        // 모드 리스트 영역
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF919AFF)),
                  ),
                )
              : _mods.isEmpty
                  ? Center(
                      child: Text(
                        widget.state.t('explore_no_mods_found'),
                        style: const TextStyle(color: Colors.white30, fontSize: 14.0),
                      ),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: GridView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 2.1,
                              crossAxisSpacing: 16.0,
                              mainAxisSpacing: 16.0,
                            ),
                            itemCount: _mods.length,
                            itemBuilder: (context, index) {
                              final mod = _mods[index];
                              return _buildModCard(mod);
                            },
                          ),
                        ),
                        // 페이지네이션
                        if (_totalPages > 1) _buildPagination(),
                      ],
                    ),
        ),
      ],
    );
  }

  Widget _buildModCard(ModItem mod) {
    final isInstalled = widget.state.installedMods.any((m) {
      return m.slug.toLowerCase() == mod.slug.toLowerCase() || isModMatched(m.slug, mod.slug);
    });
    final localMod = isInstalled
        ? widget.state.installedMods.firstWhere((m) {
            return m.slug.toLowerCase() == mod.slug.toLowerCase() || isModMatched(m.slug, mod.slug);
          })
        : null;
    final hasUpdate = localMod != null &&
        mod.latestVersion != null &&
        localMod.version != mod.latestVersion!.version;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _showModDetailDialog(mod),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1C28),
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.04),
              width: 1.0,
            ),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top: Logo and Title info
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo
                  Container(
                    width: 50.0,
                    height: 50.0,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: buildModLogo(
                      logoPath: mod.logo,
                      fallbackName: mod.name,
                      apiUrl: widget.state.apiUrl,
                      width: 50.0,
                      height: 50.0,
                      fallbackFontSize: 20.0,
                      getFallbackGradient: _getFallbackGradient,
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  // Title / Author
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                mod.name,
                                style: const TextStyle(
                                  fontSize: 15.0,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (mod.isFeatured)
                              const Padding(
                                padding: EdgeInsets.only(left: 4.0),
                                child: Text('⭐', style: TextStyle(fontSize: 12.0)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          'By ${mod.author?.displayName ?? "알 수 없음"}',
                          style: const TextStyle(color: Colors.white30, fontSize: 12.0),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10.0),
              // Summary
              Expanded(
                child: Text(
                  mod.summary,
                  style: const TextStyle(color: Colors.white60, fontSize: 13.0, height: 1.3),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 10.0),
              // Footer: badgess
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (mod.categories.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                          decoration: BoxDecoration(
                            color: const Color(0x1F919AFF),
                            borderRadius: BorderRadius.circular(4.0),
                            border: Border.all(color: const Color(0x3F919AFF)),
                          ),
                          child: const Text(
                            'UI',
                            style: TextStyle(color: Color(0xFF919AFF), fontSize: 10.0, fontWeight: FontWeight.w600),
                          ),
                        )
                      else
                        ...mod.categories.map((cat) => Container(
                          margin: const EdgeInsets.only(right: 6.0),
                          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                          decoration: BoxDecoration(
                            color: const Color(0x1F919AFF),
                            borderRadius: BorderRadius.circular(4.0),
                            border: Border.all(color: const Color(0x3F919AFF)),
                          ),
                          child: Text(
                            cat.toUpperCase(),
                            style: const TextStyle(color: Color(0xFF919AFF), fontSize: 10.0, fontWeight: FontWeight.w600),
                          ),
                        )),
                      const SizedBox(width: 4.0),
                      Row(
                        children: [
                          const Icon(Icons.download, color: Colors.white38, size: 12.0),
                          const SizedBox(width: 2.0),
                          Text('${mod.downloads}', style: const TextStyle(color: Colors.white38, fontSize: 11.0)),
                        ],
                      ),
                    ],
                  ),
                  // Install Status Badge
                  if (hasUpdate)
                    Text(
                      widget.state.t('explore_badge_update_req'),
                      style: const TextStyle(color: Colors.orangeAccent, fontSize: 11.0, fontWeight: FontWeight.bold),
                    )
                  else if (isInstalled)
                    Text(
                      widget.state.t('explore_badge_installed'),
                      style: const TextStyle(color: Color(0xFF919AFF), fontSize: 11.0, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPagination() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white),
            disabledColor: Colors.white24,
            onPressed: _currentPage > 1
                ? () {
                    setState(() {
                      _currentPage--;
                    });
                    _fetchMods();
                  }
                : null,
          ),
          Text(
            '$_currentPage / $_totalPages',
            style: const TextStyle(color: Colors.white, fontSize: 14.0),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.white),
            disabledColor: Colors.white24,
            onPressed: _currentPage < _totalPages
                ? () {
                    setState(() {
                      _currentPage++;
                    });
                    _fetchMods();
                  }
                : null,
          ),
        ],
      ),
    );
  }

  // 모드 상세 모달 다이얼로그 표시
  void _showModDetailDialog(ModItem summaryMod) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) {
        return _ModDetailModal(
          modSlug: summaryMod.slug,
          state: widget.state,
        );
      },
    );
  }
}

class _ModDetailModal extends StatefulWidget {
  final String modSlug;
  final InstallerState state;
  
  const _ModDetailModal({
    required this.modSlug,
    required this.state,
  });

  @override
  State<_ModDetailModal> createState() => _ModDetailModalState();
}

class _ModDetailModalState extends State<_ModDetailModal> {
  ModItem? _mod;
  ModVersion? _latestVersion;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDetails();
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

  Future<void> _loadDetails() async {
    try {
      final result = await widget.state.apiService.fetchModDetails(widget.modSlug);
      if (mounted) {
        setState(() {
          _mod = result['mod'] as ModItem;
          _latestVersion = result['latestVersion'] as ModVersion?;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Dialog(
        backgroundColor: Colors.transparent,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF919AFF)),
          ),
        ),
      );
    }

    if (_error != null || _mod == null) {
      return Dialog(
        backgroundColor: const Color(0xFF1E1C28),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.state.t('explore_modal_err_title'), style: const TextStyle(color: Colors.redAccent, fontSize: 18.0, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12.0),
              Text(_error ?? widget.state.t('explore_modal_err_body'), style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 24.0),
              UIButton(label: widget.state.t('explore_modal_btn_close'), fontSize: 14.0, onClick: () => Navigator.pop(context)),
            ],
          ),
        ),
      );
    }

    final mod = _mod!;
    final isInstalled = widget.state.installedMods.any((m) {
      return m.slug.toLowerCase() == mod.slug.toLowerCase() || isModMatched(m.slug, mod.slug);
    });
    final localMod = isInstalled
        ? widget.state.installedMods.firstWhere((m) {
            return m.slug.toLowerCase() == mod.slug.toLowerCase() || isModMatched(m.slug, mod.slug);
          })
        : null;
    final hasUpdate = localMod != null &&
        mod.latestVersion != null &&
        localMod.version != mod.latestVersion!.version;

    return Dialog(
      backgroundColor: const Color(0xFF1E1C28),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
      ),
      insetPadding: const EdgeInsets.all(40.0),
      child: Container(
        width: 600.0,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Close Button & Game Label
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16151D),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Text(
                    mod.game.toUpperCase(),
                    style: const TextStyle(color: Colors.white38, fontSize: 11.0, fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
              ],
            ),
            const SizedBox(height: 16.0),

            // Header (Logo, Name, Author)
            Row(
              children: [
                Container(
                  width: 64.0,
                  height: 64.0,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: buildModLogo(
                    logoPath: mod.logo,
                    fallbackName: mod.name,
                    apiUrl: widget.state.apiUrl,
                    width: 64.0,
                    height: 64.0,
                    fallbackFontSize: 28.0,
                    getFallbackGradient: (name) {
                      int hash = 0;
                      for (int i = 0; i < name.length; i++) {
                        hash = name.codeUnitAt(i) + ((hash << 5) - hash);
                      }
                      final double h1 = (hash.abs() % 360).toDouble();
                      final double h2 = ((h1 + 40) % 360).toDouble();
                      return LinearGradient(
                        colors: [
                          HSLColor.fromAHSL(1.0, h1, 0.7, 0.5).toColor(),
                          HSLColor.fromAHSL(1.0, h2, 0.7, 0.4).toColor(),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        mod.name,
                        style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        'By ${mod.author?.displayName ?? "알 수 없음"}',
                        style: const TextStyle(color: Color(0xFF919AFF), fontSize: 13.0),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20.0),

            // Tabs / Description / Changelog
            Text(
              widget.state.t('explore_modal_desc'),
              style: const TextStyle(color: Colors.white38, fontSize: 12.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            Container(
              height: 120.0,
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: const Color(0xFF16151D),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: SingleChildScrollView(
                child: MarkdownBody(
                  data: mod.description ?? mod.summary,
                  styleSheet: MarkdownStyleSheet(
                    p: const TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.4, fontFamily: 'SUIT'),
                    h1: const TextStyle(color: Colors.white, fontSize: 16.0, fontWeight: FontWeight.bold, fontFamily: 'SUIT'),
                    h2: const TextStyle(color: Colors.white, fontSize: 14.0, fontWeight: FontWeight.bold, fontFamily: 'SUIT'),
                    strong: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    em: const TextStyle(fontStyle: FontStyle.italic),
                    listBullet: const TextStyle(color: Color(0xFF919AFF)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16.0),

            // Mod metadata
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMetaInfo(widget.state.t('explore_modal_categories'), mod.categories.join(', ').toUpperCase()),
                _buildMetaInfo(widget.state.t('explore_modal_downloads'), widget.state.t('explore_modal_downloads_unit', args: {'count': '${mod.downloads}'})),
                _buildMetaInfo(widget.state.t('explore_modal_latest_ver'), 'v${_latestVersion?.version ?? "0.0.0"}'),
              ],
            ),
            const SizedBox(height: 24.0),

            // Installation status and Installer logic
            if (widget.state.isProcessing) ...[
              // Progress indicator
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4.0),
                    child: LinearProgressIndicator(
                      value: widget.state.progress,
                      backgroundColor: const Color(0xFF16151D),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF919AFF)),
                      minHeight: 6.0,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    widget.state.statusMessage ?? widget.state.t('explore_modal_loading'),
                    style: const TextStyle(color: Colors.white54, fontSize: 12.0, fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ] else ...[
              // Action Buttons
              if (!widget.state.isValidPath)
                Text(
                  widget.state.t('explore_modal_warn_path'),
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12.0, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                )
              else if (!widget.state.isLoaderInstalled)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.state.t('explore_modal_warn_loader'),
                      style: const TextStyle(color: Colors.white30, fontSize: 12.0),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12.0),
                    UIButton(
                      label: widget.state.t('explore_modal_btn_auto_loader'),
                      fontSize: 14.0,
                      onClick: () async {
                        await widget.state.installMelonLoader();
                      },
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    if (isInstalled) ...[
                      Expanded(
                        child: UIButton(
                          label: widget.state.t('explore_modal_btn_delete'),
                          fontSize: 14.0,
                          onClick: () async {
                            await widget.state.uninstallMod(mod.slug, mod.name);
                          },
                        ),
                      ),
                      if (hasUpdate) ...[
                        const SizedBox(width: 12.0),
                        Expanded(
                          child: UIButton(
                            label: '${widget.state.t('installed_btn_update_mod')} (v${mod.latestVersion!.version})',
                            fontSize: 14.0,
                            onClick: () async {
                              await widget.state.installMod(mod, version: mod.latestVersion!.version);
                            },
                          ),
                        ),
                      ],
                    ] else ...[
                      Expanded(
                        child: UIButton(
                          label: widget.state.t('explore_modal_btn_install'),
                          fontSize: 14.0,
                          onClick: () async {
                            await widget.state.installMod(mod, version: mod.latestVersion?.version);
                          },
                        ),
                      ),
                    ],
                  ],
                ),
            ],
            const SizedBox(height: 12.0),
            // Global status response helper
            if (widget.state.statusMessage != null && !widget.state.isProcessing)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  widget.state.statusMessage!,
                  style: TextStyle(
                    color: widget.state.statusMessage!.contains('실패') ? Colors.redAccent : const Color(0xFF919AFF),
                    fontSize: 12.0,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11.0)),
        const SizedBox(height: 4.0),
        Text(value, style: const TextStyle(color: Colors.white70, fontSize: 13.0, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
