class Author {
  final String id;
  final String username;
  final String? globalName;
  final String? avatar;
  final bool isVerifiedDeveloper;

  Author({
    required this.id,
    required this.username,
    this.globalName,
    this.avatar,
    this.isVerifiedDeveloper = false,
  });

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      id: json['_id'] ?? '',
      username: json['username'] ?? '',
      globalName: json['globalName'],
      avatar: json['avatar'],
      isVerifiedDeveloper: json['isVerifiedDeveloper'] ?? false,
    );
  }

  String get displayName => globalName ?? username;
}

class ModVersion {
  final String version;
  final String? downloadUrl;
  final String changelog;
  final bool isApproved;
  final bool isBeta;
  final String createdAt;
  final String? gameVersion;

  ModVersion({
    required this.version,
    this.downloadUrl,
    required this.changelog,
    required this.isApproved,
    this.isBeta = false,
    required this.createdAt,
    this.gameVersion,
  });

  factory ModVersion.fromJson(Map<String, dynamic> json) {
    return ModVersion(
      version: json['version'] ?? '',
      downloadUrl: json['downloadUrl'],
      changelog: json['changelog'] ?? '',
      isApproved: json['isApproved'] ?? false,
      isBeta: json['isBeta'] ?? false,
      createdAt: json['createdAt'] ?? '',
      gameVersion: json['gameVersion'],
    );
  }
}

class ModItem {
  final String id;
  final String name;
  final String slug;
  final String summary;
  final String? description;
  final String game;
  final List<String> categories;
  final int downloads;
  final String? logo;
  final bool isFeatured;
  final Author? author;
  final List<Author> collaborators;
  final List<ModVersion> versions;
  final ModVersion? latestVersion;
  final ModVersion? latestBetaVersion;
  final String? sourceUrl;
  final String? communityUrl;
  final List<String> dependencySlugs;

  ModItem({
    required this.id,
    required this.name,
    required this.slug,
    required this.summary,
    this.description,
    required this.game,
    required this.categories,
    required this.downloads,
    this.logo,
    this.isFeatured = false,
    this.author,
    required this.collaborators,
    required this.versions,
    this.latestVersion,
    this.latestBetaVersion,
    this.sourceUrl,
    this.communityUrl,
    required this.dependencySlugs,
  });

  ModItem copyWith({
    ModVersion? latestVersion,
    ModVersion? latestBetaVersion,
    List<String>? dependencySlugs,
  }) {
    return ModItem(
      id: id,
      name: name,
      slug: slug,
      summary: summary,
      description: description,
      game: game,
      categories: categories,
      downloads: downloads,
      logo: logo,
      isFeatured: isFeatured,
      author: author,
      collaborators: collaborators,
      versions: versions,
      latestVersion: latestVersion ?? this.latestVersion,
      latestBetaVersion: latestBetaVersion ?? this.latestBetaVersion,
      sourceUrl: sourceUrl,
      communityUrl: communityUrl,
      dependencySlugs: dependencySlugs ?? this.dependencySlugs,
    );
  }

  factory ModItem.fromJson(Map<String, dynamic> json) {
    var categoryList = <String>[];
    if (json['categories'] != null) {
      categoryList = List<String>.from(json['categories']);
    }

    var collabList = <Author>[];
    if (json['collaboratorIds'] != null) {
      collabList = (json['collaboratorIds'] as List)
          .map((c) => Author.fromJson(c))
          .toList();
    }

    var versionList = <ModVersion>[];
    if (json['versions'] != null) {
      versionList = (json['versions'] as List)
          .map((v) => ModVersion.fromJson(v))
          .toList();
    }

    var depSlugs = <String>[];
    if (json['dependencies'] != null) {
      depSlugs = (json['dependencies'] as List)
          .map((d) => d is String ? d : (d['slug'] as String? ?? ''))
          .where((s) => s.isNotEmpty)
          .toList();
    }

    return ModItem(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      summary: json['summary'] ?? '',
      description: json['description'],
      game: json['game'] ?? '',
      categories: categoryList,
      downloads: json['downloads'] ?? 0,
      logo: json['logo'],
      isFeatured: json['isFeatured'] ?? false,
      author: json['authorId'] != null ? Author.fromJson(json['authorId']) : null,
      collaborators: collabList,
      versions: versionList,
      latestVersion: json['latestVersion'] != null
          ? ModVersion.fromJson(json['latestVersion'])
          : null,
      latestBetaVersion: json['latestBetaVersion'] != null
          ? ModVersion.fromJson(json['latestBetaVersion'])
          : null,
      sourceUrl: json['sourceUrl'],
      communityUrl: json['communityUrl'],
      dependencySlugs: depSlugs,
    );
  }
}

// Local Database / JSON에 저장될 로컬 설치된 모드 메타데이터
class InstalledMod {
  final String id;
  final String slug;
  final String name;
  final String version;
  final bool isBeta;
  final String installedAt;
  final List<String> installedFiles;
  final bool isEnabled;

  InstalledMod({
    required this.id,
    required this.slug,
    required this.name,
    required this.version,
    required this.isBeta,
    required this.installedAt,
    required this.installedFiles,
    this.isEnabled = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'slug': slug,
      'name': name,
      'version': version,
      'isBeta': isBeta,
      'installedAt': installedAt,
      'installedFiles': installedFiles,
      'isEnabled': isEnabled,
    };
  }

  factory InstalledMod.fromJson(Map<String, dynamic> json) {
    return InstalledMod(
      id: json['id'] ?? '',
      slug: json['slug'] ?? '',
      name: json['name'] ?? '',
      version: json['version'] ?? '',
      isBeta: json['isBeta'] ?? false,
      installedAt: json['installedAt'] ?? '',
      installedFiles: List<String>.from(json['installedFiles'] ?? []),
      isEnabled: json['isEnabled'] ?? true,
    );
  }
}
