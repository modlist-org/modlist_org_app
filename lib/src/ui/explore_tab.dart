import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:overlayer_ui_flutter/overlayer_ui_flutter.dart';
import 'dart:convert';
import 'dart:io';
import '../core/installer_state.dart';
import '../core/app_errors.dart';
import '../models/mod_model.dart';
import 'dialogs.dart';
import 'theme.dart';
import 'widgets.dart';

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
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    ),
  );
}

final markdownStyleSheet = MarkdownStyleSheet(
  p: const TextStyle(
    color: AppColors.textSecondary,
    fontSize: 14.0,
    height: 1.6,
    fontFamily: appFontFamily,
  ),
  a: const TextStyle(color: AppColors.accent),
  blockquote: const TextStyle(
    color: AppColors.textSecondary,
    fontFamily: appFontFamily,
  ),
  blockquoteDecoration: const BoxDecoration(
    color: AppColors.bgElev,
    border: Border(left: BorderSide(color: AppColors.accent, width: 3.0)),
  ),
  blockquotePadding: const EdgeInsets.symmetric(
    horizontal: 12.0,
    vertical: 8.0,
  ),
  h1: const TextStyle(
    color: AppColors.text,
    fontSize: 18.0,
    fontWeight: FontWeight.w600,
    fontFamily: appFontFamily,
  ),
  h2: const TextStyle(
    color: AppColors.text,
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    fontFamily: appFontFamily,
  ),
  h3: const TextStyle(
    color: AppColors.text,
    fontSize: 14.5,
    fontWeight: FontWeight.w600,
    fontFamily: appFontFamily,
  ),
  strong: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w600),
  em: const TextStyle(fontStyle: FontStyle.italic),
  listBullet: const TextStyle(color: AppColors.textTertiary),
  code: const TextStyle(
    color: AppColors.text,
    backgroundColor: AppColors.control,
    fontFamily: 'Consolas',
    fontFamilyFallback: ['Menlo', 'monospace'],
    fontSize: 13.0,
  ),
  codeblockDecoration: BoxDecoration(
    color: AppColors.bg,
    borderRadius: BorderRadius.circular(AppRadius.sm),
  ),
  codeblockPadding: const EdgeInsets.all(14.0),
  horizontalRuleDecoration: const BoxDecoration(
    border: Border(top: BorderSide(color: AppColors.border)),
  ),
);

String _gameLabel(InstallerState state, String game) {
  switch (game.toLowerCase()) {
    case 'adofai':
      return state.t('game_adofai');
    case 'dancing-line':
      return state.t('game_dancing_line');
    case 'rhythm-doctor':
      return state.t('game_rhythm_doctor');
    default:
      return game.toUpperCase();
  }
}

Widget _buildLetterAvatar(Author author, double size) {
  return Container(
    width: size,
    height: size,
    decoration: const BoxDecoration(
      color: AppColors.control,
      shape: BoxShape.circle,
    ),
    alignment: Alignment.center,
    child: Text(
      author.displayName.isNotEmpty ? author.displayName[0].toUpperCase() : 'A',
      style: TextStyle(
        color: AppColors.textSecondary,
        fontSize: size * 0.45,
        fontWeight: FontWeight.w600,
        height: 1.0,
      ),
    ),
  );
}

Widget _buildAuthorAvatar(Author author, {double size = 24.0}) {
  if (author.avatar == null || author.avatar!.isEmpty) {
    return _buildLetterAvatar(author, size);
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
      errorBuilder: (context, error, stackTrace) =>
          _buildLetterAvatar(author, size),
    ),
  );
}

/// Overlapping avatar stack (web `.avatar-stack`).
Widget _buildAvatarStack(
  List<Author> authors, {
  double size = 18.0,
  int max = 3,
  Color ringColor = AppColors.surface,
}) {
  if (authors.isEmpty) return const SizedBox.shrink();
  final int displayCount = authors.length > max ? max : authors.length;
  const double ring = 2.0;
  final double outer = size + ring * 2;
  final double step = outer - 8.0;

  return SizedBox(
    width: outer + (displayCount - 1) * step,
    height: outer,
    child: Stack(
      children: [
        for (int i = 0; i < displayCount; i++)
          Positioned(
            left: i * step,
            child: Container(
              padding: const EdgeInsets.all(ring),
              decoration: BoxDecoration(
                color: ringColor,
                shape: BoxShape.circle,
              ),
              child: _buildAuthorAvatar(authors[i], size: size),
            ),
          ),
      ],
    ),
  );
}

class ExploreTab extends StatefulWidget {
  final InstallerState state;
  const ExploreTab({super.key, required this.state});

  @override
  State<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab> {
  final TextEditingController _searchController = TextEditingController();

  final List<String> _selectedCategories = [];
  String _selectedSort = 'downloads_desc';

  List<ModItem> _mods = [];
  bool _isLoading = true;
  int _currentPage = 1;
  int _totalPages = 1;
  String? _lastGameId;

  // 디바운스 검색용
  DateTime? _lastSearchTime;

  @override
  void initState() {
    super.initState();
    _lastGameId = widget.state.game.id;
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
      if (_lastGameId != widget.state.game.id) {
        _lastGameId = widget.state.game.id;
        _currentPage = 1;
        _fetchMods();
      } else {
        setState(() {});
      }
    }
  }

  Future<void> _fetchMods() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await widget.state.apiService.fetchMods(
        game: widget.state.game.id,
        categories: _selectedCategories.isEmpty
            ? 'all'
            : _selectedCategories.join(','),
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
          SnackBar(
            content: Text(
              widget.state.t(
                'explore_err_load_failed',
                args: {'error': describeAppError(e)},
              ),
            ),
          ),
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
  LinearGradient _getFallbackGradient(String name) =>
      fallbackLogoGradient(name);

  Widget _buildCategoryChip(String cat) {
    final bool isSelected = cat == 'all'
        ? _selectedCategories.isEmpty
        : _selectedCategories.contains(cat);

    final String label = cat == 'all'
        ? widget.state.t('explore_filter_category_all')
        : widget.state.t('category_$cat');

    return HoverBuilder(
      onTap: () {
        setState(() {
          if (cat == 'all') {
            _selectedCategories.clear();
          } else {
            if (_selectedCategories.contains(cat)) {
              _selectedCategories.remove(cat);
            } else {
              _selectedCategories.add(cat);
            }
          }
          _currentPage = 1;
        });
        _fetchMods();
      },
      builder: (context, hovered) => HoverOutline(
        visible: hovered && !isSelected,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 34.0,
          padding: const EdgeInsets.symmetric(horizontal: 14.0),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.button : AppColors.control,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected || hovered
                  ? AppColors.text
                  : AppColors.textSecondary,
              fontSize: 13.0,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 필터 및 검색 바
        Padding(
          padding: const EdgeInsets.fromLTRB(32.0, 28.0, 32.0, 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeader(
                title: widget.state.t('tab_explore'),
                subtitle: _gameLabel(widget.state, widget.state.game.id),
              ),
              const SizedBox(height: 20.0),
              Row(
                children: [
                  // 검색어 입력
                  Expanded(
                    child: HoverOutlineField(
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 14.0,
                        ),
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: widget.state.t(
                            'explore_search_placeholder',
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            size: 18.0,
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 40.0,
                            minHeight: 42.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  // 정렬 필터
                  SizedBox(
                    width: 200,
                    height: 42,
                    child: UIDropdown<String>(
                      modelValue: _selectedSort,
                      defaultValue: 'downloads_desc',
                      values: const [
                        'updated',
                        'created',
                        'downloads_desc',
                        'downloads_asc',
                        'name_asc',
                        'name_desc',
                      ],
                      display: (val) {
                        if (val == 'updated') {
                          return widget.state.t('explore_filter_sort_updated');
                        }
                        if (val == 'created') {
                          return widget.state.t('explore_filter_sort_created');
                        }
                        if (val == 'downloads_desc') {
                          return widget.state.t(
                            'explore_filter_sort_downloads',
                          );
                        }
                        if (val == 'downloads_asc') {
                          return widget.state.t(
                            'explore_filter_sort_downloads_asc',
                          );
                        }
                        if (val == 'name_asc') {
                          return widget.state.t('explore_filter_sort_name');
                        }
                        if (val == 'name_desc') {
                          return widget.state.t(
                            'explore_filter_sort_name_desc',
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
              const SizedBox(height: 14.0),
              // 카테고리 필터 (Chips)
              ScrollConfiguration(
                behavior: const MaterialScrollBehavior().copyWith(
                  scrollbars: false,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildCategoryChip('all'),
                      const SizedBox(width: 8.0),
                      _buildCategoryChip('ui'),
                      const SizedBox(width: 8.0),
                      _buildCategoryChip('gameplay'),
                      const SizedBox(width: 8.0),
                      _buildCategoryChip('utility'),
                      const SizedBox(width: 8.0),
                      _buildCategoryChip('visuals'),
                      const SizedBox(width: 8.0),
                      _buildCategoryChip('library'),
                    ],
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
                  child: SizedBox(
                    width: 28.0,
                    height: 28.0,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                )
              : _mods.isEmpty
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(32.0, 0.0, 32.0, 32.0),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 48.0),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.inventory_2_outlined,
                            size: 32.0,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(height: 12.0),
                          Text(
                            widget.state.t('explore_no_mods_found'),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          const double minCardWidth = 400.0;
                          const double spacing = 16.0;

                          final count =
                              ((constraints.maxWidth - 64.0 + spacing) /
                                      (minCardWidth + spacing))
                                  .floor()
                                  .clamp(1, 999);

                          return GridView.builder(
                            padding: const EdgeInsets.fromLTRB(
                              32.0,
                              0.0,
                              32.0,
                              24.0,
                            ),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: count,
                                  crossAxisSpacing: spacing,
                                  mainAxisSpacing: spacing,
                                  mainAxisExtent: 168.0,
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
      authorNamesStr += widget.state.t('explore_card_author_more');
    }
    final String authorNames = authorNamesStr;
    final bool isAnyAuthorVerified = authors.any((a) => a.isVerifiedDeveloper);

    final List<String> shownCategories = mod.categories.take(3).toList();

    return HoverBuilder(
      onTap: () => _showModDetailDialog(mod),
      builder: (context, hovered) {
        final Color base = hovered ? AppColors.surfaceHover : AppColors.surface;

        return HoverOutline(
          visible: hovered,
          radius: AppRadius.lg,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            decoration: BoxDecoration(
              color: mod.isFeatured ? null : base,
              gradient: mod.isFeatured
                  ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.65],
                      colors: [
                        Color.alphaBlend(
                          AppColors.warning.withValues(alpha: 0.06),
                          base,
                        ),
                        base,
                      ],
                    )
                  : null,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: mod.isFeatured
                    ? AppColors.warning.withValues(alpha: 0.18)
                    : AppColors.border,
              ),
            ),
            padding: const EdgeInsets.all(18.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                Container(
                  width: 56.0,
                  height: 56.0,
                  decoration: BoxDecoration(
                    color: AppColors.control,
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: buildModLogo(
                    logoPath: mod.logo,
                    fallbackName: mod.name,
                    apiUrl: widget.state.apiUrl,
                    width: 56.0,
                    height: 56.0,
                    fallbackFontSize: 22.0,
                    getFallbackGradient: _getFallbackGradient,
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Heading
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              mod.name,
                              style: const TextStyle(
                                fontSize: 17.0,
                                fontWeight: FontWeight.w600,
                                color: AppColors.text,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (mod.isFeatured) ...[
                            const SizedBox(width: 8.0),
                            AppBadge(
                              label:
                                  '★ ${widget.state.t('explore_card_featured')}',
                              tone: BadgeTone.warning,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6.0),

                      // Authors
                      Row(
                        children: [
                          if (authors.isNotEmpty) ...[
                            _buildAvatarStack(
                              authors,
                              ringColor: hovered
                                  ? AppColors.surfaceHover
                                  : AppColors.surface,
                            ),
                            const SizedBox(width: 6.0),
                          ],
                          Flexible(
                            child: Text(
                              authorNames,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13.0,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isAnyAuthorVerified) ...[
                            const SizedBox(width: 6.0),
                            const VerifiedDot(),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8.0),

                      // Summary
                      Expanded(
                        child: Text(
                          mod.summary,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13.5,
                            height: 1.5,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Meta: badges + stats
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 22.0,
                              child: Wrap(
                                spacing: 6.0,
                                runSpacing: 6.0,
                                clipBehavior: Clip.hardEdge,
                                children: [
                                  for (final g in mod.games)
                                    AppBadge(
                                      label: _gameLabel(widget.state, g),
                                      tone: BadgeTone.game,
                                    ),
                                  for (final cat in shownCategories)
                                    AppBadge(
                                      label: widget.state.t('category_$cat'),
                                    ),
                                  if (mod.categories.length > 3)
                                    AppBadge(
                                      label: '+${mod.categories.length - 3}',
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10.0),
                          _buildCardStats(mod),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardStats(ModItem mod) {
    const TextStyle statStyle = TextStyle(
      color: AppColors.textTertiary,
      fontSize: 12.5,
      fontWeight: FontWeight.w600,
      fontFeatures: [FontFeature.tabularFigures()],
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Mod Version
        if (mod.latestVersion != null) ...[
          Text('v${mod.latestVersion!.version}', style: statStyle),
          const SizedBox(width: 10.0),
        ],
        // Game Version
        if (mod.latestVersion?.gameVersion != null) ...[
          const Icon(
            Icons.sports_esports_outlined,
            color: AppColors.textTertiary,
            size: 14.0,
          ),
          const SizedBox(width: 3.0),
          Text(mod.latestVersion!.gameVersion!, style: statStyle),
          const SizedBox(width: 10.0),
        ],
        // Download count
        const Icon(
          Icons.download_rounded,
          color: AppColors.textTertiary,
          size: 14.0,
        ),
        const SizedBox(width: 3.0),
        Text('${mod.downloads}', style: statStyle),
      ],
    );
  }

  Widget _buildPagination() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppButton(
            variant: AppButtonVariant.secondary,
            size: AppButtonSize.sm,
            onPressed: _currentPage > 1
                ? () {
                    setState(() {
                      _currentPage--;
                    });
                    _fetchMods();
                  }
                : null,
            child: const Icon(Icons.chevron_left_rounded, size: 18.0),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              '$_currentPage / $_totalPages',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          AppButton(
            variant: AppButtonVariant.secondary,
            size: AppButtonSize.sm,
            onPressed: _currentPage < _totalPages
                ? () {
                    setState(() {
                      _currentPage++;
                    });
                    _fetchMods();
                  }
                : null,
            child: const Icon(Icons.chevron_right_rounded, size: 18.0),
          ),
        ],
      ),
    );
  }

  // 모드 상세 모달 다이얼로그 표시
  void _showModDetailDialog(ModItem summaryMod) {
    showDialog(
      context: context,
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
          _error = describeAppError(e);
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
        shape: RoundedRectangleBorder(side: BorderSide.none),
        child: Center(
          child: SizedBox(
            width: 28.0,
            height: 28.0,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }

    if (_error != null || _mod == null) {
      return AppDialogFrame(
        icon: Icons.error_outline_rounded,
        iconColor: AppColors.danger,
        iconBackground: AppColors.dangerSoft,
        title: widget.state.t('explore_modal_err_title'),
        body: _error ?? widget.state.t('explore_modal_err_body'),
        actions: [
          OlButton(
            expand: true,
            label: widget.state.t('explore_modal_btn_close'),
            onClick: () => Navigator.pop(context),
          ),
        ],
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

    final String? statusMessage = widget.state.statusMessage;
    final bool statusIsError =
        statusMessage != null &&
        (statusMessage.toLowerCase().contains('실패') ||
            statusMessage.toLowerCase().contains('fail') ||
            statusMessage.toLowerCase().contains('失败') ||
            statusMessage.toLowerCase().contains('error'));

    return Dialog(
      insetPadding: const EdgeInsets.all(40.0),
      child: Container(
        width: 720.0,
        padding: const EdgeInsets.all(24.0),
        child: ScrollConfiguration(
          behavior: const MaterialScrollBehavior().copyWith(scrollbars: false),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header (Logo, Name, Author, Close)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 72.0,
                      height: 72.0,
                      decoration: BoxDecoration(
                        color: AppColors.control,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: buildModLogo(
                        logoPath: mod.logo,
                        fallbackName: mod.name,
                        apiUrl: widget.state.apiUrl,
                        width: 72.0,
                        height: 72.0,
                        fallbackFontSize: 30.0,
                        getFallbackGradient: fallbackLogoGradient,
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  mod.name,
                                  style: const TextStyle(
                                    fontSize: 22.0,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.text,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (mod.isFeatured) ...[
                                const SizedBox(width: 10.0),
                                AppBadge(
                                  label:
                                      '★ ${widget.state.t('explore_card_featured')}',
                                  tone: BadgeTone.warning,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8.0),
                          Row(
                            children: [
                              if (mod.author != null)
                                _buildUserBadge(mod.author!),

                              if (mod.collaborators.isNotEmpty) ...[
                                const SizedBox(width: 10.0),
                                _buildAvatarStack(
                                  mod.collaborators,
                                  size: 20.0,
                                  max: 8,
                                ),
                                const SizedBox(width: 6.0),
                                Text(
                                  '+${mod.collaborators.length}',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20.0),
                      tooltip: widget.state.t('explore_modal_btn_close'),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),

                // Badges
                Wrap(
                  spacing: 6.0,
                  runSpacing: 6.0,
                  children: [
                    for (final g in mod.games)
                      AppBadge(
                        label: _gameLabel(widget.state, g),
                        tone: BadgeTone.game,
                      ),
                    for (final cat in mod.categories)
                      AppBadge(label: widget.state.t('category_$cat')),
                  ],
                ),
                const SizedBox(height: 16.0),

                // Stats
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4.0,
                    vertical: 12.0,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.bgElev,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        _buildStat(
                          widget.state.t('explore_modal_downloads'),
                          '${mod.downloads}',
                          Icons.download_rounded,
                        ),
                        if (_latestVersion != null) ...[
                          const VerticalDivider(width: 1.0),
                          _buildStat(
                            widget.state.t('explore_modal_latest_ver'),
                            'v${_latestVersion!.version}',
                            Icons.sell_outlined,
                          ),
                        ],
                        if (_latestVersion?.gameVersion != null) ...[
                          const VerticalDivider(width: 1.0),
                          _buildStat(
                            widget.state.t('explore_modal_game_ver'),
                            _latestVersion!.gameVersion!,
                            Icons.sports_esports_outlined,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),

                // Description
                LayoutBuilder(
                  builder: (context, constraints) {
                    final text = mod.description ?? mod.summary;

                    final overflow = _checkOverflow(
                      text,
                      constraints.maxWidth - 32,
                    );

                    return Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          height: 220.0,
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: AppColors.bgElev,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: ClipRect(
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
                                  stops: [0.0, 0.5, 0.75, 1.0],
                                ).createShader(rect);
                              },
                              blendMode: BlendMode.dstIn,
                              child: SingleChildScrollView(
                                physics: const NeverScrollableScrollPhysics(),
                                child: MarkdownBody(
                                  data: text,
                                  styleSheet: markdownStyleSheet,
                                ),
                              ),
                            ),
                          ),
                        ),

                        if (overflow)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.control,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.sm,
                                ),
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.open_in_full_rounded,
                                  size: 16,
                                ),
                                visualDensity: VisualDensity.compact,
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (dialogContext) => Dialog(
                                      insetPadding: const EdgeInsets.all(40.0),
                                      child: Container(
                                        constraints: const BoxConstraints(
                                          maxWidth: 1000.0,
                                          maxHeight: 900.0,
                                        ),
                                        padding: const EdgeInsets.all(28.0),
                                        child: SingleChildScrollView(
                                          child: MarkdownBody(
                                            data:
                                                mod.description ?? mod.summary,
                                            styleSheet: markdownStyleSheet,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20.0),

                // Installation status and Installer logic
                if (widget.state.isProcessing) ...[
                  // Progress indicator
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
                          widget.state.statusMessage ??
                              widget.state.t('explore_modal_loading'),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13.0,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10.0),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999.0),
                          child: LinearProgressIndicator(
                            value: widget.state.progress,
                            minHeight: 4.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Warnings
                  if (!widget.state.isValidPath)
                    StatusBanner(
                      tone: BannerTone.danger,
                      message: widget.state.t('explore_modal_warn_path'),
                    )
                  else if (!widget.state.isLoaderInstalled)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        StatusBanner(
                          tone: widget.state.isUmmDetected
                              ? BannerTone.warning
                              : BannerTone.info,
                          message: widget.state.isUmmDetected
                              ? widget.state.t('installed_umm_banner')
                              : widget.state.t('explore_modal_warn_loader'),
                        ),
                        const SizedBox(height: 12.0),
                        AppButton(
                          size: AppButtonSize.lg,
                          expand: true,
                          variant: widget.state.isUmmDetected
                              ? AppButtonVariant.beta
                              : AppButtonVariant.primary,
                          icon: widget.state.isUmmDetected
                              ? Icons.swap_horiz_rounded
                              : Icons.download_rounded,
                          label: widget.state.isUmmDetected
                              ? widget.state.t('installed_btn_replace_loader')
                              : widget.state.t('explore_modal_btn_auto_loader'),
                          onPressed: () async {
                            if (widget.state.isUmmDetected) {
                              showReplaceUmmDialog(context, widget.state);
                            } else {
                              await widget.state.installMelonLoader();
                            }
                          },
                        ),
                      ],
                    )
                  else ...[
                    // Stable version download button
                    if (_latestVersion != null) ...[
                      OlButton(
                        height: 50.0,
                        fontSize: 16.0,
                        expand: true,
                        icon: Icons.download_rounded,
                        label:
                            '${widget.state.t('explore_modal_btn_install')} · v${_latestVersion!.version}',
                        onClick: () async {
                          await widget.state.installMod(
                            mod,
                            version: _latestVersion!.version,
                          );
                          if (context.mounted) {
                            checkAndPromptUmmCompat(context, widget.state);
                          }
                        },
                      ),
                      const SizedBox(height: 8.0),
                    ],

                    // Beta version download button
                    if (mod.latestBetaVersion != null) ...[
                      AppButton(
                        size: AppButtonSize.lg,
                        expand: true,
                        variant: AppButtonVariant.beta,
                        icon: Icons.science_outlined,
                        label:
                            'v${mod.latestBetaVersion!.version} (${widget.state.t('explore_modal_beta')})',
                        onPressed: () async {
                          await widget.state.installMod(
                            mod,
                            version: mod.latestBetaVersion!.version,
                            isBeta: true,
                          );
                          if (context.mounted) {
                            checkAndPromptUmmCompat(context, widget.state);
                          }
                        },
                      ),
                      const SizedBox(height: 8.0),
                    ],
                  ],

                  // Social GitHub & Discord buttons row
                  if ((mod.sourceUrl != null && mod.sourceUrl!.isNotEmpty) ||
                      (mod.communityUrl != null &&
                          mod.communityUrl!.isNotEmpty)) ...[
                    if (!widget.state.isValidPath ||
                        !widget.state.isLoaderInstalled)
                      const SizedBox(height: 8.0),
                    Row(
                      children: [
                        if (mod.sourceUrl != null && mod.sourceUrl!.isNotEmpty)
                          Expanded(
                            child: AppButton(
                              label: 'GitHub',
                              variant: AppButtonVariant.secondary,
                              expand: true,
                              leading: SvgPicture.string(
                                _githubSvg,
                                width: 16.0,
                                height: 16.0,
                                colorFilter: const ColorFilter.mode(
                                  AppColors.text,
                                  BlendMode.srcIn,
                                ),
                              ),
                              onPressed: () => _launchUrl(mod.sourceUrl!),
                            ),
                          ),
                        if (mod.sourceUrl != null &&
                            mod.sourceUrl!.isNotEmpty &&
                            mod.communityUrl != null &&
                            mod.communityUrl!.isNotEmpty)
                          const SizedBox(width: 8.0),
                        if (mod.communityUrl != null &&
                            mod.communityUrl!.isNotEmpty)
                          Expanded(
                            child: AppButton(
                              label: 'Discord',
                              variant: AppButtonVariant.secondary,
                              expand: true,
                              leading: SvgPicture.string(
                                _discordSvg,
                                width: 16.0,
                                height: 16.0,
                                colorFilter: const ColorFilter.mode(
                                  AppColors.discord,
                                  BlendMode.srcIn,
                                ),
                              ),
                              onPressed: () => _launchUrl(mod.communityUrl!),
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
                    OlButton(
                      expand: true,
                      tone: OlButtonTone.danger,
                      icon: Icons.delete_outline_rounded,
                      label:
                          '${widget.state.t('explore_modal_btn_delete')} (v${localMod.version})',
                      onClick: () async {
                        final confirm = await showDeleteConfirmDialog(
                          context,
                          widget.state,
                          mod.name,
                        );
                        if (confirm) {
                          await widget.state.uninstallMod(mod.slug, mod.name);
                        }
                      },
                    ),
                  ],
                ],

                // Global status response helper
                if (statusMessage != null && !widget.state.isProcessing)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          statusIsError
                              ? Icons.error_outline_rounded
                              : Icons.check_circle_outline_rounded,
                          size: 16.0,
                          color: statusIsError
                              ? AppColors.danger
                              : AppColors.success,
                        ),
                        const SizedBox(width: 6.0),
                        Flexible(
                          child: Text(
                            statusMessage,
                            style: TextStyle(
                              color: statusIsError
                                  ? AppColors.danger
                                  : AppColors.textSecondary,
                              fontSize: 13.0,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 12.0,
              ),
            ),
            const SizedBox(height: 4.0),
            Row(
              children: [
                Icon(icon, size: 15.0, color: AppColors.textSecondary),
                const SizedBox(width: 6.0),
                Flexible(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 15.0,
                      fontWeight: FontWeight.w600,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserBadge(Author author) {
    return Container(
      height: 28.0,
      padding: const EdgeInsets.only(left: 4.0, right: 10.0),
      decoration: BoxDecoration(
        color: AppColors.control,
        borderRadius: BorderRadius.circular(999.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildAuthorAvatar(author, size: 20.0),
          const SizedBox(width: 6.0),
          Text(
            author.displayName,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 13.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (author.isVerifiedDeveloper) ...[
            const SizedBox(width: 6.0),
            const VerifiedDot(size: 14.0),
          ],
        ],
      ),
    );
  }
}

bool _checkOverflow(String text, double maxWidth) {
  final tp = TextPainter(
    text: TextSpan(
      text: text,
      style: const TextStyle(
        fontSize: 14.0,
        height: 1.6,
        fontFamily: appFontFamily,
      ),
    ),
    maxLines: null,
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: maxWidth);

  return tp.height > 160.0;
}
