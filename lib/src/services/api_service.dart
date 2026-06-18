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

  static const String _tokenKey = 'modlist_integration_token';

  Future<String?> getIntegrationToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> setIntegrationToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // Premium Cloud Saving Status 조회
  Future<Map<String, dynamic>> fetchSavingStatus() async {
    final baseUrl = await getBaseUrl();
    final token = await getIntegrationToken();
    if (token == null || token.isEmpty) {
      throw Exception('App Integration Token is not set in Settings.');
    }

    final uri = Uri.parse('$baseUrl/api/premium/saving');
    final response = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final Map<String, dynamic> body = jsonDecode(response.body);
      throw Exception(body['message'] ?? body['statusMessage'] ?? 'Failed to load cloud saves: ${response.statusCode}');
    }
  }

  // Presign upload URL 요청
  Future<Map<String, dynamic>> getUploadPresignedUrl({
    required String game,
    required String fileName,
    required int fileSize,
  }) async {
    final baseUrl = await getBaseUrl();
    final token = await getIntegrationToken();
    if (token == null || token.isEmpty) {
      throw Exception('App Integration Token is not set in Settings.');
    }

    final uri = Uri.parse('$baseUrl/api/premium/saving/presign-upload');
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'game': game,
        'fileName': fileName,
        'fileSize': fileSize,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final Map<String, dynamic> body = jsonDecode(response.body);
      throw Exception(body['message'] ?? body['statusMessage'] ?? 'Failed to generate upload URL: ${response.statusCode}');
    }
  }

  // Confirm upload 요청
  Future<Map<String, dynamic>> confirmUpload({
    required String game,
    required String fileName,
    required String fileKey,
    required int fileSize,
  }) async {
    final baseUrl = await getBaseUrl();
    final token = await getIntegrationToken();
    if (token == null || token.isEmpty) {
      throw Exception('App Integration Token is not set in Settings.');
    }

    final uri = Uri.parse('$baseUrl/api/premium/saving/confirm-upload');
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'game': game,
        'fileName': fileName,
        'fileKey': fileKey,
        'fileSize': fileSize,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final Map<String, dynamic> body = jsonDecode(response.body);
      throw Exception(body['message'] ?? body['statusMessage'] ?? 'Failed to confirm upload: ${response.statusCode}');
    }
  }

  // Presign download URL 요청
  Future<String> getDownloadPresignedUrl(String fileKey) async {
    final baseUrl = await getBaseUrl();
    final token = await getIntegrationToken();
    if (token == null || token.isEmpty) {
      throw Exception('App Integration Token is not set in Settings.');
    }

    final uri = Uri.parse('$baseUrl/api/premium/saving/presign-download');
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'fileKey': fileKey,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['downloadUrl'] as String;
    } else {
      final Map<String, dynamic> body = jsonDecode(response.body);
      throw Exception(body['message'] ?? body['statusMessage'] ?? 'Failed to generate download URL: ${response.statusCode}');
    }
  }

  // Delete cloud save 파일 요청
  Future<void> deleteCloudSave(String fileKey) async {
    final baseUrl = await getBaseUrl();
    final token = await getIntegrationToken();
    if (token == null || token.isEmpty) {
      throw Exception('App Integration Token is not set in Settings.');
    }

    final uri = Uri.parse('$baseUrl/api/premium/saving/delete');
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'fileKey': fileKey,
      }),
    );

    if (response.statusCode != 200) {
      final Map<String, dynamic> body = jsonDecode(response.body);
      throw Exception(body['message'] ?? body['statusMessage'] ?? 'Failed to delete cloud save: ${response.statusCode}');
    }
  }

  // Preset 생성
  Future<Map<String, dynamic>> createPreset({
    required String name,
    required String game,
    required List<Map<String, dynamic>> mods,
  }) async {
    final baseUrl = await getBaseUrl();
    final token = await getIntegrationToken();
    if (token == null || token.isEmpty) {
      throw Exception('App Integration Token is not set in Settings.');
    }

    final uri = Uri.parse('$baseUrl/api/premium/presets');
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'game': game,
        'mods': mods,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final Map<String, dynamic> body = jsonDecode(response.body);
      throw Exception(body['message'] ?? body['statusMessage'] ?? 'Failed to create preset: ${response.statusCode}');
    }
  }

  // Preset 상세 조회 (인증 불필요)
  Future<Map<String, dynamic>> fetchPreset(String presetId) async {
    final baseUrl = await getBaseUrl();
    final uri = Uri.parse('$baseUrl/api/premium/presets/$presetId');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final Map<String, dynamic> body = jsonDecode(response.body);
      throw Exception(body['message'] ?? body['statusMessage'] ?? 'Failed to fetch preset details: ${response.statusCode}');
    }
  }

  // 파일 업로드 (R2 직통)
  Future<void> uploadFileToR2(String uploadUrl, List<int> bytes) async {
    final uri = Uri.parse(uploadUrl);
    final response = await http.put(
      uri,
      headers: {
        'Content-Length': bytes.length.toString(),
        'Content-Type': 'application/octet-stream',
      },
      body: bytes,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to upload file to storage: ${response.statusCode}');
    }
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
