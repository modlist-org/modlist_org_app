import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'src/ui/main_layout.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  String? initialDeepLink;
  for (final arg in args) {
    if (arg.startsWith('modlist://')) {
      initialDeepLink = arg;
      break;
    }
  }

  // await clearFontCache(); for debug

  await Future.wait([
    _loadSuitFont(),
    _loadNotoSansSC(),
  ]);

  runApp(ModlistApp(initialDeepLink: initialDeepLink));
}

/*
Future<void> clearFontCache() async {
  final dir = await getApplicationSupportDirectory();
  final cacheDir = Directory('${dir.path}/fonts');

  if (await cacheDir.exists()) {
    await cacheDir.delete(recursive: true);
  }
}
*/

Future<Uint8List> _getCachedFont(String url) async {
  final dir = await getApplicationSupportDirectory();

  final fileName = md5.convert(url.codeUnits).toString();
  final file = File('${dir.path}/fonts/$fileName.ttf');

  if (!await file.exists()) {
    await file.parent.create(recursive: true);

    final response = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) {
      throw Exception('Font download failed: $url (${response.statusCode})');
    }

    await file.writeAsBytes(response.bodyBytes);
  }

  return await file.readAsBytes();
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
      } catch (e) {
        debugPrint('[FONT SKIP] $url -> $e');
      }
    }

    await loader.load();
  } catch (e, stackTrace) {
    debugPrint('[FONT LOADER FAIL] $family');
    debugPrint(e.toString());
    debugPrintStack(stackTrace: stackTrace);
  }
}

Future<void> _loadSuitFont() {
  return _loadFont('SUIT', [
    'https://cdn.jsdelivr.net/gh/sun-typeface/SUIT@2/fonts/variable/ttf/SUIT-Variable.ttf',
  ]);
}

Future<void> _loadNotoSansSC() {
  return _loadFont('NotoSansSC', [
    'https://cdn.jsdelivr.net/gh/notofonts/noto-cjk/Sans/Variable/TTF/Subset/NotoSansSC-VF.ttf',
  ]);
}

class ModlistApp extends StatelessWidget {
  final String? initialDeepLink;
  const ModlistApp({super.key, this.initialDeepLink});

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
          'NotoSansSC',
        ],
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF919AFF),
          secondary: Color(0xFF626696),
          surface: Color(0xFF1E1C28),
        ),
      ),
      home: MainLayout(initialDeepLink: initialDeepLink),
    );
  }
}