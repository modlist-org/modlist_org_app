import 'package:flutter/material.dart';
import 'package:overlayer_ui_flutter/overlayer_ui_flutter.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:convert';
import 'dart:io';
import '../core/installer_state.dart';
import '../models/mod_model.dart';

const String _githubSvg = '''
<svg viewBox="0 0 24 24" width="24" height="24" fill="currentColor">
  <path d="M12 2C6.477 2 2 6.477 2 12c0 4.42 2.865 8.166 6.839 9.489.5.092.682-.217.682-.482 0-.237-.008-.866-.013-1.7-2.782.603-3.369-1.34-3.369-1.34-.454-1.156-1.11-1.464-1.11-1.464-.908-.62.069-.608.069-.608 1.003.07 1.531 1.03 1.531 1.03.892 1.529 2.341 1.087 2.91.831.092-.646.35-1.086.636-1.336-2.22-.253-4.555-1.11-4.555-4.943 0-1.091.39-1.984 1.029-2.683-.103-.253-.446-1.27.098-2.647 0 0 .84-.269 2.75 1.025A9.564 9.564 0 0112 6.844c.85.004 1.705.115 2.504.337 1.909-1.294 2.747-1.025 2.747-1.025.546 1.377.203 2.394.1 2.647.64.699 1.028 1.592 1.028 2.683 0 3.842-2.339 4.687-4.566 4.935.359.309.678.919.678 1.852 0 1.336-.012 2.415-.012 2.743 0 .267.18.579.688.481C19.138 20.161 22 16.416 22 12c0-5.523-4.477-10-10-10z"/>
</svg>
''';

const String _discordSvg = '''
<svg viewBox="0 0 24 24" width="24" height="24" fill="currentColor">
  <path d="M20.317 4.37a19.791 19.791 0 00-4.885-1.515.074.074 0 00-.079.037c-.21.375-.444.864-.608 1.25a18.27 18.27 0 00-5.487 0 12.64 12.64 0 00-.617-1.25.077.077 0 00-.079-.037A19.736 19.736 0 003.677 4.37a.07.07 0 00-.032.027C.533 9.046-.32 13.58.099 18.057a.082.082 0 00.031.057 19.9 19.9 0 005.993 3.03.078.078 0 00.084-.028c.462-.63.874-1.295 1.226-1.994.021-.041.001-.09-.041-.106a13.094 13.094 0 01-1.873-.894.077.077 0 01-.008-.128c.126-.093.252-.19.372-.287a.075.075 0 01.077-.011c3.92 1.793 8.18 1.793 12.061 0a.073.073 0 01.078.009c.12.099.246.195.373.289a.077.077 0 01-.006.127 12.299 12.299 0 01-1.873.894.077.077 0 00-.041.107c.36.698.772 1.362 1.225 1.993a.076.076 0 00.084.028 19.839 19.839 0 006.002-3.03.077.077 0 00.032-.054c.5-5.177-.838-9.674-3.549-13.66a.061.061 0 00-.031-.03zM8.02 15.33c-1.183 0-2.157-1.085-2.157-2.419 0-1.333.956-2.419 2.156-2.419 1.21 0 2.176 1.096 2.157 2.42 0 1.333-.956 2.418-2.156 2.418zm7.975 0c-1.183 0-2.157-1.085-2.157-2.419 0-1.333.955-2.419 2.156-2.419 1.21 0 2.176 1.096 2.157 2.42 0 1.333-.946 2.418-2.156 2.418z"/>
</svg>
''';

Future<void> _launchUrl(String url) async {
  try {
    if (Platform.isWindows) {
      await Process.run('start', [url], runInShell: true);
    } else if (Platform.isMacOS) {
      await Process.run('open', [url]);
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', [url]);
    }
  } catch (_) {}
}

String _getImageUrl(String? path, String baseUrl) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http')) return path;
  final base = baseUrl.endsWith('/')
      ? baseUrl.substring(0, baseUrl.length - 1)
      : baseUrl;
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
    return _buildFallbackLogo(
      fallbackName,
      fallbackFontSize,
      getFallbackGradient,
    );
  }

  if (logoPath.startsWith('data:image')) {
    try {
      final commaIndex = logoPath.indexOf(',');
      if (commaIndex != -1) {
        final base64Str = logoPath.substring(commaIndex + 1);
        final bytes = base64.decode(base64Str);
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: BoxFit.cover,
        );
      }
    } catch (e) {
      return _buildFallbackLogo(
        fallbackName,
        fallbackFontSize,
        getFallbackGradient,
      );
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

Widget _buildFallbackLogo(
  String name,
  double fontSize,
  LinearGradient Function(String) getFallbackGradient,
) {
  return Container(
    decoration: BoxDecoration(gradient: getFallbackGradient(name)),
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

final markdownStyleSheet = MarkdownStyleSheet(
  p: const TextStyle(
    color: Colors.white70,
    fontSize: 13.5,
    height: 1.4,
    fontFamily: 'SUIT',
  ),
  blockquote: const TextStyle(
    color: Colors.white60,
    fontStyle: FontStyle.italic,
    fontFamily: 'SUIT',
  ),
  blockquoteDecoration: const BoxDecoration(
    border: Border(left: BorderSide(color: Color(0xFF919AFF), width: 3.0)),
  ),
  blockquotePadding: const EdgeInsets.symmetric(
    horizontal: 12.0,
    vertical: 6.0,
  ),
  h1: const TextStyle(
    color: Colors.white,
    fontSize: 16.0,
    fontWeight: FontWeight.bold,
    fontFamily: 'SUIT',
  ),
  h2: const TextStyle(
    color: Colors.white,
    fontSize: 14.0,
    fontWeight: FontWeight.bold,
    fontFamily: 'SUIT',
  ),
  strong: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
  em: const TextStyle(fontStyle: FontStyle.italic),
  listBullet: const TextStyle(color: Color(0xFF919AFF)),
  code: const TextStyle(
    color: Color.fromARGB(255, 193, 194, 255),
    fontFamily: 'Consolas',
    fontSize: 13.0,
  ),
  codeblockDecoration: BoxDecoration(
    color: const Color(0xFF111118),
    borderRadius: BorderRadius.circular(8.0),
    border: Border.all(color: Colors.white10),
  ),
  codeblockPadding: const EdgeInsets.all(12.0),
);

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('모드 데이터를 불러오는 데 실패했습니다: $e')));
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
                        Text(
                          widget.state.t('explore_filter_category'),
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 12.0,
                          ),
                        ),
                        const SizedBox(height: 6.0),
                        SizedBox(
                          height: 42,
                          child: UIDropdown<String>(
                            modelValue: _selectedCategory,
                            defaultValue: 'all',
                            values: const [
                              'all',
                              'ui',
                              'gameplay',
                              'utility',
                              'visuals',
                              'library',
                            ],
                            display: (val) {
                              if (val == 'all') {
                                return widget.state.t(
                                  'explore_filter_category_all',
                                );
                              }
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
                        Text(
                          widget.state.t('explore_filter_sort'),
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 12.0,
                          ),
                        ),
                        const SizedBox(height: 6.0),
                        SizedBox(
                          height: 42,
                          child: UIDropdown<String>(
                            modelValue: _selectedSort,
                            defaultValue: 'downloads_desc',
                            values: const [
                              'downloads_desc',
                              'updated',
                              'created',
                              'name_asc',
                            ],
                            display: (val) {
                              if (val == 'downloads_desc') {
                                return widget.state.t(
                                  'explore_filter_sort_downloads',
                                );
                              }
                              if (val == 'updated') {
                                return widget.state.t(
                                  'explore_filter_sort_updated',
                                );
                              }
                              if (val == 'created') {
                                return widget.state.t(
                                  'explore_filter_sort_created',
                                );
                              }
                              if (val == 'name_asc') {
                                return widget.state.t(
                                  'explore_filter_sort_name',
                                );
                              }
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
                  hintStyle: const TextStyle(
                    color: Colors.white24,
                    fontSize: 14.0,
                  ),
                  suffixIcon: const Icon(
                    Icons.search,
                    color: Colors.white30,
                    size: 20.0,
                  ),
                  filled: true,
                  fillColor: const Color(0xFF3C3A4B),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: const BorderSide(
                      color: Color(0xFF919AFF),
                      width: 1.5,
                    ),
                  ),
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
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF919AFF),
                    ),
                  ),
                )
              : _mods.isEmpty
              ? Center(
                  child: Text(
                    widget.state.t('explore_no_mods_found'),
                    style: const TextStyle(
                      color: Colors.white30,
                      fontSize: 14.0,
                    ),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          const double minCardWidth = 388.0;
                          const double spacing = 16.0;

                          final count =
                              ((constraints.maxWidth + spacing) /
                                      (minCardWidth + spacing))
                                  .floor()
                                  .clamp(1, 999);

                          return GridView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24.0,
                            ),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: count,
                                  crossAxisSpacing: spacing,
                                  mainAxisSpacing: spacing,
                                  mainAxisExtent: 154.0,
                                ),
                            itemCount: _mods.length,
                            itemBuilder: (context, index) {
                              return _buildModCard(_mods[index]);
                            },
                          );
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
    // Authors list
    final List<Author> authors = [];
    if (mod.author != null) {
      authors.add(mod.author!);
    }
    authors.addAll(mod.collaborators);
    final List<String> names = [];
    if (mod.author != null) {
      names.add(mod.author!.displayName);
    }
    if (mod.collaborators.isNotEmpty) {
      final displayed = mod.collaborators.take(2);
      for (final collab in displayed) {
        names.add(collab.displayName);
      }
    }
    String authorNamesStr = names.join(', ');
    if (mod.collaborators.length > 2) {
      authorNamesStr += widget.state.locale == 'ko-KR' ? ' 외' : ' and more';
    }
    final String authorNames = authorNamesStr;
    final bool isAnyAuthorVerified = authors.any((a) => a.isVerifiedDeveloper);

    final String gameLabel = mod.game.toLowerCase() == 'adofai'
        ? (widget.state.locale == 'ko-KR' ? '얼불춤 (ADOFAI)' : 'ADOFAI')
        : mod.game.toUpperCase();

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
              // 1. Logo and Title/Summary info (Row)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo
                  Container(
                    width: 44.0,
                    height: 44.0,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: buildModLogo(
                      logoPath: mod.logo,
                      fallbackName: mod.name,
                      apiUrl: widget.state.apiUrl,
                      width: 44.0,
                      height: 44.0,
                      fallbackFontSize: 18.0,
                      getFallbackGradient: _getFallbackGradient,
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  // Title and Subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mod.name,
                          style: const TextStyle(
                            fontSize: 15.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3.0),
                        Text(
                          mod.summary,
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 11.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10.0),

              // 2. Badges Row
              Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          if (mod.isFeatured) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6.0,
                                vertical: 2.0,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0x1FFFB300),
                                borderRadius: BorderRadius.circular(4.0),
                                border: Border.all(
                                  color: const Color(0xFFFFB300),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Color(0xFFFFB300),
                                    size: 10.0,
                                  ),
                                  const SizedBox(width: 2.0),
                                  Text(
                                    widget.state.t('explore_card_featured'),
                                    style: const TextStyle(
                                      color: Color(0xFFFFB300),
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6.0),
                          ],
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6.0,
                              vertical: 2.0,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0x1F7E808F),
                              borderRadius: BorderRadius.circular(4.0),
                              border: Border.all(
                                color: const Color(0x5F7E808F),
                              ),
                            ),
                            child: Text(
                              gameLabel,
                              style: const TextStyle(
                                color: Color(0xFFC2C3D3),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6.0),
                          ...mod.categories.map(
                            (cat) => Container(
                              margin: const EdgeInsets.only(right: 6.0),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6.0,
                                vertical: 2.0,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0x1F919AFF),
                                borderRadius: BorderRadius.circular(4.0),
                                border: Border.all(
                                  color: const Color(0x3F919AFF),
                                ),
                              ),
                              child: Text(
                                widget.state.locale == 'ko-KR'
                                    ? widget.state.t('category_$cat')
                                    : cat.toUpperCase(),
                                style: const TextStyle(
                                  color: Color(0xFF919AFF),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),

              // 3. Divider
              Divider(
                color: Colors.white.withValues(alpha: 0.04),
                height: 1.0,
                thickness: 1.0,
              ),
              const SizedBox(height: 10.0),

              // 4. Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Author Info
                  Expanded(
                    child: Row(
                      children: [
                        if (authors.isNotEmpty) ...[
                          _buildOverlappingAvatars(authors),
                          const SizedBox(width: 8.0),
                        ],
                        Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  authorNames,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11.0,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isAnyAuthorVerified) ...[
                                const SizedBox(width: 3.0),
                                const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF4CAF50),
                                  size: 12.0,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  // Mod Version, Game Version & Downloads
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Mod Version Pill
                      if (mod.latestVersion != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5.0,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2B283D),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: Text(
                            'v${mod.latestVersion!.version}',
                            style: const TextStyle(
                              color: Color(0xFF919AFF),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5.0),
                      ],
                      // Game Version Pill
                      if (mod.latestVersion?.gameVersion != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5.0,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0x1FFFFFFF),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: Text(
                            '🎮 ${mod.latestVersion!.gameVersion}',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5.0),
                      ],
                      // Download count
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.download,
                            color: Colors.white30,
                            size: 12.0,
                          ),
                          const SizedBox(width: 1.5),
                          Text(
                            '${mod.downloads}',
                            style: const TextStyle(
                              color: Colors.white30,
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniAvatar(Author author) {
    if (author.avatar == null || author.avatar!.isEmpty) {
      return CircleAvatar(
        radius: 8.0,
        backgroundColor: const Color(0xFF919AFF),
        child: Text(
          author.displayName.isNotEmpty
              ? author.displayName[0].toUpperCase()
              : 'A',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 7.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    // data:image 또는 http url
    if (author.avatar!.startsWith('data:image')) {
      try {
        final commaIndex = author.avatar!.indexOf(',');
        if (commaIndex != -1) {
          final base64Str = author.avatar!.substring(commaIndex + 1);
          final bytes = base64.decode(base64Str);
          return ClipOval(
            child: Image.memory(
              bytes,
              width: 16.0,
              height: 16.0,
              fit: BoxFit.cover,
            ),
          );
        }
      } catch (_) {}
    }

    return ClipOval(
      child: Image.network(
        author.avatar!,
        width: 16.0,
        height: 16.0,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => CircleAvatar(
          radius: 8.0,
          backgroundColor: const Color(0xFF919AFF),
          child: Text(
            author.displayName.isNotEmpty
                ? author.displayName[0].toUpperCase()
                : 'A',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 7.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverlappingAvatars(List<Author> authors) {
    if (authors.isEmpty) return const SizedBox.shrink();

    final List<Widget> avatarWidgets = [];
    final int displayCount = authors.length > 3 ? 3 : authors.length;

    for (int i = 0; i < displayCount; i++) {
      avatarWidgets.add(
        Positioned(
          left: i * 12.0,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF1E1C28), width: 1.5),
            ),
            child: _buildMiniAvatar(authors[i]),
          ),
        ),
      );
    }

    return SizedBox(
      width: 16.0 + (displayCount - 1) * 12.0 + 3.0,
      height: 19.0,
      child: Stack(alignment: Alignment.centerLeft, children: avatarWidgets),
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
        return _ModDetailModal(modSlug: summaryMod.slug, state: widget.state);
      },
    );
  }
}

class _ModDetailModal extends StatefulWidget {
  final String modSlug;
  final InstallerState state;

  const _ModDetailModal({required this.modSlug, required this.state});

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
      final result = await widget.state.apiService.fetchModDetails(
        widget.modSlug,
      );
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
              Text(
                widget.state.t('explore_modal_err_title'),
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12.0),
              Text(
                _error ?? widget.state.t('explore_modal_err_body'),
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 24.0),
              UIButton(
                label: widget.state.t('explore_modal_btn_close'),
                fontSize: 14.0,
                onClick: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      );
    }

    final mod = _mod!;
    final List<Author> authors = [];
    if (mod.author != null) {
      authors.add(mod.author!);
    }
    authors.addAll(mod.collaborators);
    final isInstalled = widget.state.installedMods.any((m) {
      return m.slug.toLowerCase() == mod.slug.toLowerCase() ||
          widget.state.game.isModMatched(m.slug, mod.slug);
    });
    final localMod = isInstalled
        ? widget.state.installedMods.firstWhere((m) {
            return m.slug.toLowerCase() == mod.slug.toLowerCase() ||
                widget.state.game.isModMatched(m.slug, mod.slug);
          })
        : null;

    return Dialog(
      backgroundColor: const Color(0xFF1E1C28),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
      ),
      insetPadding: const EdgeInsets.all(40.0),
      child: Container(
        width: 680.0,
        padding: const EdgeInsets.all(24.0),
        child: ScrollConfiguration(
          behavior: const MaterialScrollBehavior().copyWith(scrollbars: false),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Close Button & Game Label
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 3.0,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16151D),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Text(
                        mod.game.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 12.0),

                // Header (Logo, Name, Author)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 64.0,
                      height: 64.0,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mod.name,
                            style: const TextStyle(
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 4.0),

                          Row(
                            children: [
                              if (mod.author != null)
                                _buildUserBadge(mod.author!),

                              if (mod.collaborators.isNotEmpty) ...[
                                const SizedBox(width: 10.0),

                                Text(
                                  '+${mod.collaborators.length}',
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),

                                const SizedBox(width: 6.0),

                                Transform.translate(
                                  offset: const Offset(0.0, -1.0),
                                  child: SizedBox(
                                    width:
                                        mod.collaborators.take(8).length *
                                            12.0 +
                                        20.0,
                                    height: 20.0,
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        for (
                                          int i = 0;
                                          i < mod.collaborators.take(8).length;
                                          i++
                                        )
                                          Positioned(
                                            left: i * 14.0,
                                            child: Opacity(
                                              opacity: (1.0 - i * 0.08).clamp(
                                                0.4,
                                                1.0,
                                              ),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFF16151D,
                                                  ),
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: const Color(
                                                      0xFF16151D,
                                                    ),
                                                    width: 2.0,
                                                  ),
                                                ),
                                                child: _buildAvatar(
                                                  mod.collaborators[i],
                                                  size: 20.0,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Download Conut
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.download_rounded,
                            size: 18.0,
                            color: Colors.white54,
                          ),

                          const SizedBox(width: 6.0),

                          Text(
                            '${mod.downloads}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14.0),

                // Tabs / Description / Changelog
                const SizedBox(height: 6.0),
                Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 240.0,
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16151D),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: ShaderMask(
                                shaderCallback: (rect) {
                                  return const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.white,
                                      Colors.white,
                                      Colors.white,
                                      Colors.transparent,
                                    ],
                                    stops: [0.0, 0.75, 0.9, 1.0],
                                  ).createShader(rect);
                                },
                                blendMode: BlendMode.dstIn,
                                child: SingleChildScrollView(
                                  physics: const NeverScrollableScrollPhysics(),
                                  child: MarkdownBody(
                                    data: mod.description ?? mod.summary,
                                    styleSheet: markdownStyleSheet,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    Positioned(
                      top: 8.0,
                      right: 8.0,
                      child: IconButton(
                        icon: const Icon(
                          Icons.open_in_full,
                          size: 18.0,
                          color: Colors.white54,
                        ),
                        tooltip: widget.state.t('explore_modal_expand'),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => Dialog(
                              backgroundColor: const Color(0xFF1E1C28),
                              insetPadding: const EdgeInsets.all(40.0),
                              child: Container(
                                constraints: const BoxConstraints(
                                  maxWidth: 1000.0,
                                  maxHeight: 900.0,
                                ),
                                padding: const EdgeInsets.all(24.0),
                                child: SingleChildScrollView(
                                  child: MarkdownBody(
                                    data: mod.description ?? mod.summary,
                                    styleSheet: markdownStyleSheet,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12.0),

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
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF919AFF),
                          ),
                          minHeight: 6.0,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        widget.state.statusMessage ??
                            widget.state.t('explore_modal_loading'),
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12.0,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ] else ...[
                  // Warnings
                  if (!widget.state.isValidPath)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Text(
                        widget.state.t('explore_modal_warn_path'),
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12.0,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else if (!widget.state.isLoaderInstalled)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            widget.state.t('explore_modal_warn_loader'),
                            style: const TextStyle(
                              color: Colors.white30,
                              fontSize: 12.0,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8.0),
                          _DownloadButton(
                            height: 44.0,
                            backgroundColor: const Color(0xFF6C78FF),
                            onTap: () async {
                              await widget.state.installMelonLoader();
                            },
                            child: Text(
                              widget.state.t('explore_modal_btn_auto_loader'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    // Stable version download button
                    if (_latestVersion != null) ...[
                      _DownloadButton(
                        height: 50.0,
                        backgroundColor: const Color(0xFF5865F2),
                        onTap: () async {
                          await widget.state.installMod(
                            mod,
                            version: _latestVersion!.version,
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.download,
                              color: Colors.white,
                              size: 20.0,
                            ),
                            const SizedBox(width: 8.0),
                            Text(
                              'v${_latestVersion!.version}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'SUIT',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8.0),
                    ],

                    // Beta version download button
                    if (mod.latestBetaVersion != null) ...[
                      _DownloadButton(
                        height: 50.0,
                        backgroundColor: const Color(0xFF352920),
                        border: Border.all(
                          color: const Color(0xFFC8945A),
                          width: 1.5,
                        ),
                        onTap: () async {
                          await widget.state.installMod(
                            mod,
                            version: mod.latestBetaVersion!.version,
                            isBeta: true,
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.download,
                              color: Color(0xFFC8945A),
                              size: 20.0,
                            ),
                            const SizedBox(width: 8.0),
                            Text(
                              'v${mod.latestBetaVersion!.version} (${widget.state.locale == 'ko-KR' ? '베타' : 'Beta'})',
                              style: const TextStyle(
                                color: Color(0xFFC8945A),
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'SUIT',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8.0),
                    ],
                  ],

                  // Social GitHub & Discord buttons row
                  if ((mod.sourceUrl != null && mod.sourceUrl!.isNotEmpty) ||
                      (mod.communityUrl != null &&
                          mod.communityUrl!.isNotEmpty)) ...[
                    Row(
                      children: [
                        if (mod.sourceUrl != null && mod.sourceUrl!.isNotEmpty)
                          Expanded(
                            child: _DownloadButton(
                              height: 44.0,
                              backgroundColor: const Color(0xFF1F2026),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.05),
                                width: 1.0,
                              ),
                              onTap: () => _launchUrl(mod.sourceUrl!),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SvgPicture.string(
                                    _githubSvg,
                                    width: 18.0,
                                    height: 18.0,
                                    colorFilter: const ColorFilter.mode(
                                      Colors.white,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  const SizedBox(width: 8.0),
                                  const Text(
                                    'GitHub',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14.0,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'SUIT',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (mod.sourceUrl != null &&
                            mod.sourceUrl!.isNotEmpty &&
                            mod.communityUrl != null &&
                            mod.communityUrl!.isNotEmpty)
                          const SizedBox(width: 12.0),
                        if (mod.communityUrl != null &&
                            mod.communityUrl!.isNotEmpty)
                          Expanded(
                            child: _DownloadButton(
                              height: 44.0,
                              backgroundColor: const Color(0xFF1B1E30),
                              border: Border.all(
                                color: const Color(
                                  0xFF5865F2,
                                ).withValues(alpha: 0.15),
                                width: 1.0,
                              ),
                              onTap: () => _launchUrl(mod.communityUrl!),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SvgPicture.string(
                                    _discordSvg,
                                    width: 18.0,
                                    height: 18.0,
                                    colorFilter: const ColorFilter.mode(
                                      Color(0xFF5865F2),
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  const SizedBox(width: 8.0),
                                  const Text(
                                    'Discord',
                                    style: TextStyle(
                                      color: Color(0xFF5865F2),
                                      fontSize: 14.0,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'SUIT',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],

                  // Delete button if installed
                  if (isInstalled &&
                      localMod != null &&
                      widget.state.isValidPath &&
                      widget.state.isLoaderInstalled) ...[
                    const SizedBox(height: 8.0),
                    _DownloadButton(
                      height: 44.0,
                      backgroundColor: const Color(0xFF2C1E21),
                      border: Border.all(
                        color: const Color(0xFFE74C3C).withValues(alpha: 0.3),
                        width: 1.0,
                      ),
                      onTap: () async {
                        await widget.state.uninstallMod(mod.slug, mod.name);
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.delete_outline,
                            color: Color(0xFFE74C3C),
                            size: 18.0,
                          ),
                          const SizedBox(width: 8.0),
                          Text(
                            '${widget.state.t('explore_modal_btn_delete')} (v${localMod.version})',
                            style: const TextStyle(
                              color: Color(0xFFE74C3C),
                              fontSize: 14.0,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'SUIT',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],

                const SizedBox(height: 12.0),
                // Global status response helper
                if (widget.state.statusMessage != null &&
                    !widget.state.isProcessing)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      widget.state.statusMessage!,
                      style: TextStyle(
                        color: widget.state.statusMessage!.contains('실패')
                            ? Colors.redAccent
                            : const Color(0xFF919AFF),
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(Author author, {double size = 24.0}) {
    final double radius = size / 2;
    if (author.avatar == null || author.avatar!.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFF919AFF),
        child: Text(
          author.displayName.isNotEmpty
              ? author.displayName[0].toUpperCase()
              : 'A',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.45,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    if (author.avatar!.startsWith('data:image')) {
      try {
        final commaIndex = author.avatar!.indexOf(',');
        if (commaIndex != -1) {
          final base64Str = author.avatar!.substring(commaIndex + 1);
          final bytes = base64.decode(base64Str);
          return ClipOval(
            child: Image.memory(
              bytes,
              width: size,
              height: size,
              fit: BoxFit.cover,
            ),
          );
        }
      } catch (_) {}
    }

    return ClipOval(
      child: Image.network(
        author.avatar!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => CircleAvatar(
          radius: radius,
          backgroundColor: const Color(0xFF919AFF),
          child: Text(
            author.displayName.isNotEmpty
                ? author.displayName[0].toUpperCase()
                : 'A',
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.45,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserBadge(Author author) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: const Color(0xFF16151D),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildAvatar(author, size: 20.0),
          const SizedBox(width: 6.0),
          Text(
            author.displayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13.0,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (author.isVerifiedDeveloper) ...[
            const SizedBox(width: 6.0),
            Container(
              padding: const EdgeInsets.all(1.0),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF1B4D3E), width: 1.0),
                borderRadius: BorderRadius.circular(4.0),
                color: const Color(0xFF0F2C22),
              ),
              child: const Icon(
                Icons.check,
                color: Color(0xFF2ECC71),
                size: 10.0,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DownloadButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Border? border;
  final double height;

  const _DownloadButton({
    required this.child,
    required this.onTap,
    required this.backgroundColor,
    this.border,
    this.height = 50.0,
  });

  @override
  State<_DownloadButton> createState() => _DownloadButtonState();
}

class _DownloadButtonState extends State<_DownloadButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _isPressed = false;
      }),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isPressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: widget.height,
            decoration: BoxDecoration(
              color: _isPressed
                  ? widget.backgroundColor.withValues(alpha: 0.8)
                  : (_isHovered
                        ? widget.backgroundColor.withValues(alpha: 0.9)
                        : widget.backgroundColor),
              borderRadius: BorderRadius.circular(12.0),
              border: widget.border,
            ),
            alignment: Alignment.center,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
