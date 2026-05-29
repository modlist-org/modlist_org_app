import 'package:flutter_test/flutter_test.dart';
import 'package:modlist_org_app/src/core/adofai_game.dart';

void main() {
  group('isModMatched Tests', () {
    final game = AdofaiGame();

    test('Exact match', () {
      expect(game.isModMatched('adofai-tweaks', 'adofai-tweaks'), isTrue);
    });

    test('UMM prefix to standard slug match', () {
      expect(game.isModMatched('umm-Tweaks', 'adofai-tweaks'), isTrue);
      expect(game.isModMatched('umm-Tweaks', 'Tweaks'), isTrue);
    });

    test('Case insensitivity', () {
      expect(game.isModMatched('umm-tweaks', 'ADOFAI-TWEAKS'), isTrue);
    });

    test('Normalized separators', () {
      expect(game.isModMatched('umm-adofai_tweaks', 'adofai-tweaks'), isTrue);
      expect(game.isModMatched('umm-adofai tweaks', 'adofai-tweaks'), isTrue);
    });

    test('Ends with match', () {
      expect(game.isModMatched('umm-Tweaks', 'adofai-tweaks'), isTrue);
      expect(game.isModMatched('adofai-tweaks', 'umm-Tweaks'), isTrue);
    });

    test('No match cases', () {
      expect(game.isModMatched('umm-Tweaks', 'other-mod'), isFalse);
      expect(game.isModMatched('some-mod', 'another-mod'), isFalse);
    });
  });
}
