import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'src/ui/main_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _loadSuitFont();
  runApp(const ModlistApp());
}

Future<void> _loadSuitFont() async {
  try {
    final fontLoader = FontLoader('SUIT');
    
    final fontUrls = [
      'https://cdn.jsdelivr.net/gh/sun-typeface/SUIT@2/fonts/static/ttf/SUIT-Thin.ttf',
      'https://cdn.jsdelivr.net/gh/sun-typeface/SUIT@2/fonts/static/ttf/SUIT-Regular.ttf',
      'https://cdn.jsdelivr.net/gh/sun-typeface/SUIT@2/fonts/static/ttf/SUIT-Medium.ttf',
      'https://cdn.jsdelivr.net/gh/sun-typeface/SUIT@2/fonts/static/ttf/SUIT-SemiBold.ttf',
      'https://cdn.jsdelivr.net/gh/sun-typeface/SUIT@2/fonts/static/ttf/SUIT-Bold.ttf',
    ];

    for (final url in fontUrls) {
      try {
        final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 4));
        if (response.statusCode == 200) {
          final bytes = response.bodyBytes;
          final byteData = ByteData.view(bytes.buffer);
          fontLoader.addFont(Future.value(byteData));
        }
      } catch (_) {}
    }
    
    await fontLoader.load();
  } catch (_) {}
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
