import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mod_model.dart';

class ApiService {
  static const String _defaultBaseUrl = 'https://modlist.org';
  static const String _baseUrlKey = 'modlist_api_base_url';

  // shared_preferences에서 설정된 base_url을 가져옴 (없으면 기본값)
  Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_baseUrlKey) ?? _defaultBaseUrl;
  }

  // base_url 설정 저장
  Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, url);
  }

  // 모드 목록 조회
  Future<Map<String, dynamic>> fetchMods({
    required String game,
    String? categories,
    String? search,
    String sortBy = 'downloads_desc',
    int page = 1,
    int limit = 12,
  }) async {
    final baseUrl = await getBaseUrl();
    final queryParams = {
      'game': game,
      'sortBy': sortBy,
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (categories != null && categories.isNotEmpty && categories != 'all') {
      queryParams['categories'] = categories;
    }
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    final uri = Uri.parse('$baseUrl/api/mods').replace(queryParameters: queryParams);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> modsJson = data['mods'] ?? [];
      final mods = modsJson.map((m) => ModItem.fromJson(m)).toList();
      
      return {
        'mods': mods,
        'pagination': data['pagination'] ?? {
          'total': mods.length,
          'page': page,
          'limit': limit,
          'totalPages': 1
        }
      };
    } else {
      throw Exception('Failed to load mods from api: ${response.statusCode}');
    }
  }

  // 모드 상세 정보 조회
  Future<Map<String, dynamic>> fetchModDetails(String slug) async {
    final baseUrl = await getBaseUrl();
    final uri = Uri.parse('$baseUrl/api/mods/$slug');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final modItemRaw = ModItem.fromJson(data['mod']);
      final latest = data['latestVersion'] != null ? ModVersion.fromJson(data['latestVersion']) : null;
      final latestBeta = data['latestBetaVersion'] != null ? ModVersion.fromJson(data['latestBetaVersion']) : null;
      
      final modItem = modItemRaw.copyWith(
        latestVersion: latest,
        latestBetaVersion: latestBeta,
      );

      return {
        'mod': modItem,
        'latestVersion': latest,
        'latestBetaVersion': latestBeta,
      };
    } else {
      throw Exception('Failed to load mod details: ${response.statusCode}');
    }
  }

  // 302 리디렉션 헤더에서 실제 다운로드 URL 추출 및 다운로드 카운팅 트리거
  Future<String> getDownloadUrl(String slug, {String? version, bool isBeta = false}) async {
    final baseUrl = await getBaseUrl();
    
    final queryParams = <String, String>{};
    if (version != null) {
      queryParams['version'] = version;
    }
    if (isBeta) {
      queryParams['beta'] = 'true';
    }

    final uri = Uri.parse('$baseUrl/api/mods/$slug/download').replace(queryParameters: queryParams);
    
    final client = http.Client();
    try {
      final request = http.Request('GET', uri)..followRedirects = false;
      final streamedResponse = await client.send(request);
      
      // 301, 302 리디렉션 응답에서 location 헤더 확인
      if (streamedResponse.statusCode == 301 || streamedResponse.statusCode == 302) {
        final location = streamedResponse.headers['location'];
        if (location != null && location.isNotEmpty) {
          return location;
        }
      }
      
      // 리디렉션이 없고 200인 경우 (드문 케이스지만 대응)
      if (streamedResponse.statusCode == 200) {
        return uri.toString();
      }
      
      throw Exception('Failed to get download URL redirect (Status: ${streamedResponse.statusCode})');
    } finally {
      client.close();
    }
  }
}
