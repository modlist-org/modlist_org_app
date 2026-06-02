import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'src/ui/main_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Future.wait([
    _loadSuitFont(),
    _loadSourceHanSansCN(),
  ]);

  runApp(const ModlistApp());
}

Future<Uint8List> _getCachedFont(String url) async {
  final dir = await getApplicationSupportDirectory();

  final fileName = Uri.parse(url).pathSegments.last;
  final file = File('${dir.path}/fonts/$fileName');

  if (await file.exists()) {
    debugPrint('[FONT] Cache hit: $fileName');
    return await file.readAsBytes();
  }

  debugPrint('[FONT] Download: $fileName');

  await file.parent.create(recursive: true);

  final response = await http
      .get(Uri.parse(url))
      .timeout(const Duration(seconds: 4));

  if (response.statusCode != 200) {
    throw Exception('Failed to download font');
  }

  await file.writeAsBytes(response.bodyBytes);

  return response.bodyBytes;
}

Future<void> _loadFont(
  String family,
  List<String> urls,
) async {
  try {
    final loader = FontLoader(family);

    for (final url in urls) {
      try {
        final bytes = await _getCachedFont(url);

        loader.addFont(
          Future.value(
            ByteData.view(bytes.buffer),
          ),
        );
      } catch (_) {}
    }

    await loader.load();
  } catch (_) {}
}

Future<void> _loadSuitFont() {
  return _loadFont('SUIT', [
    'https://cdn.jsdelivr.net/gh/sun-typeface/SUIT@2/fonts/static/ttf/SUIT-ExtraLight.ttf',
    'https://cdn.jsdelivr.net/gh/sun-typeface/SUIT@2/fonts/static/ttf/SUIT-Regular.ttf',
    'https://cdn.jsdelivr.net/gh/sun-typeface/SUIT@2/fonts/static/ttf/SUIT-Medium.ttf',
    'https://cdn.jsdelivr.net/gh/sun-typeface/SUIT@2/fonts/static/ttf/SUIT-Bold.ttf',
    'https://cdn.jsdelivr.net/gh/sun-typeface/SUIT@2/fonts/static/ttf/SUIT-Heavy.ttf',
  ]);
}

Future<void> _loadSourceHanSansCN() {
  return _loadFont('SourceHanSansCN', [
    'https://cdn.jsdelivr.net/npm/@zf-web-font/sourcehansanscn@0.2.0/SourceHanSansCN-ExtraLight.ttf',
    'https://cdn.jsdelivr.net/npm/@zf-web-font/sourcehansanscn@0.2.0/SourceHanSansCN-Regular.ttf',
    'https://cdn.jsdelivr.net/npm/@zf-web-font/sourcehansanscn@0.2.0/SourceHanSansCN-Medium.ttf',
    'https://cdn.jsdelivr.net/npm/@zf-web-font/sourcehansanscn@0.2.0/SourceHanSansCN-Bold.ttf',
    'https://cdn.jsdelivr.net/npm/@zf-web-font/sourcehansanscn@0.2.0/SourceHanSansCN-Heavy.ttf',
  ]);
}

class ModlistApp extends StatelessWidget {
  const ModlistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'modlist.org app',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF16151D),
        fontFamily: 'SUIT',
        fontFamilyFallback: const [
          'SourceHanSansCN',
        ],
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF919AFF),
          secondary: Color(0xFF626696),
          surface: Color(0xFF1E1C28),
        ),
      ),
      home: const MainLayout(),
    );
  }
}