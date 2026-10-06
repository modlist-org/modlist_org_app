import 'package:flutter_test/flutter_test.dart';
import 'package:modlist_org_app/src/models/mod_model.dart';

Map<String, dynamic> _json({Object? translations}) => {
      '_id': 'x',
      'name': 'Mod',
      'slug': 'mod',
      'summary': 'Default summary',
      'description': 'Default description',
      'game': 'adofai',
      'categories': ['ui'],
      'downloads': 0,
      'translations': ?translations,
    };

void main() {
  test('uses the translation for the requested locale', () {
    final mod = ModItem.fromJson(_json(translations: {
      'ko-KR': {'summary': '한국어 요약', 'description': '한국어 설명'},
    }));
    expect(mod.summaryFor('ko-KR'), '한국어 요약');
    expect(mod.descriptionFor('ko-KR'), '한국어 설명');
  });

  test('falls back per field and for missing locales', () {
    final mod = ModItem.fromJson(_json(translations: {
      'zh-CN': {'summary': '中文', 'description': '   '},
    }));
    expect(mod.summaryFor('zh-CN'), '中文');
    expect(mod.descriptionFor('zh-CN'), 'Default description');
    expect(mod.summaryFor('en-US'), 'Default summary');
  });

  test('older servers without translations still parse', () {
    final mod = ModItem.fromJson(_json());
    expect(mod.translations, isEmpty);
    expect(mod.summaryFor('ko-KR'), 'Default summary');
  });
}
